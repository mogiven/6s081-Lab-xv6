# Lab xv6 Network driver

[toc]

## 1. 实验内容

在 kernel/e1000.c 中完成 e1000_transmit() 和 e1000_recv()，以便驱动程序可以传输和接收数据包。

hints for e1000_transmit ： 

* 首先通过读取 E1000_TDT 控制寄存器向 E1000 询问它期待下一个数据包的 TX 环索引。
*  然后检查环是否溢出。如果 E1000_TDT 索引的描述符中没有设置 E1000_TXD_STAT_DD，则说明 E1000 还没有完成对应的上一个传输请求，因此返回错误。
*  否则，使用 mbuffree() 释放从该描述符传输的最后一个 mbuf（如果有的话）。 
* 然后填写描述符。 m->head 指向包在内存中的内容，m->len 是包的长度。设置必要的 cmd 标志（查看 E1000 手册中的第 3.3 节）并隐藏指向 mbuf 的指针以供以后释放。
*  最后，通过将 E1000_TDT 模 TX_RING_SIZE 加一来更新环位置。
*  如果 e1000_transmit() 成功地将 mbuf 添加到环中，则返回 0。失败时（例如，没有可用于传输 mbuf 的描述符），返回 -1 以便调用者知道释放 mbuf。

hints for e1000_recv ： 

* 首先通过获取 E1000_RDT 控制寄存器并加一个模 RX_RING_SIZE，向 E1000 询问下一个等待接收的数据包（如果有）所在的环索引。
*  然后通过检查描述符状态部分中的 E1000_RXD_STAT_DD 位来检查新数据包是否可用。如果没有，请停止。 
* 否则，将 mbuf 的 m->len 更新为描述符中报告的长度。使用 net_rx() 将 mbuf 传送到网络堆栈。 然后使用 mbufalloc() 分配一个新的 mbuf 来替换刚刚给 net_rx() 的那个。将其数据指针（m->head）编程到描述符中。将描述符的状态位清零。 
* 最后，将 E1000_RDT 寄存器更新为最后处理的环描述符的索引。
*  e1000_init() 用 mbufs 初始化 RX 环，你会想看看它是如何做到的，也许还需要借用代码。 
* 在某些时候，已经到达的数据包总数将超过环大小（16）；确保您的代码可以处理。

## 2. 实验步骤

### 2.1 实现`e1000_transmit()`

注意`cmd`域，宏定义里面给了`E1000_TXD_CMD_R`和`E1000_TXD_CMD_EOP`。

```c
int
e1000_transmit(struct mbuf *m)
{
  acquire(&e1000_lock);

  uint32 idx = regs[E1000_TDT];
  struct tx_desc* desc = &tx_ring[idx];

  if((desc->status & E1000_TXD_STAT_DD) == 0){
    release(&e1000_lock);
    printf("buffer overflow\n");
    return -1;
  }

  if(tx_mbufs[idx])
    mbuffree(tx_mbufs[idx]);
  
  desc->addr = (uint64)m->head;
  desc->length = m->len;
  desc->cmd = E1000_TXD_CMD_RS | E1000_TXD_CMD_EOP;
  tx_mbufs[idx] = m;

  regs[E1000_TDT] = (idx + 1) % TX_RING_SIZE;
  __sync_synchronize();
  release(&e1000_lock);
  
  return 0;
}
```



### 2.2 实现`e1000_recv()`

注意一次中断应该把所有到达的数据都处理掉。

```c
static void
e1000_recv(void)
{
  int idx = (regs[E1000_RDT] + 1) % RX_RING_SIZE;
  struct rx_desc* desc = &rx_ring[idx];

  while(desc->status & E1000_RXD_STAT_DD){
    acquire(&e1000_lock);

    struct mbuf *buf = rx_mbufs[idx];
    mbufput(buf, desc->length);
    
    rx_mbufs[idx] = mbufalloc(0);
    if (!rx_mbufs[idx])
      panic("mbuf alloc failed");
    desc->addr = (uint64) rx_mbufs[idx]->head;
    desc->status = 0;

    regs[E1000_RDT] = idx;
    __sync_synchronize();
    release(&e1000_lock);

    net_rx(buf);
    
    idx = (regs[E1000_RDT] + 1) % RX_RING_SIZE;
    desc = &rx_ring[idx];
  }
}
```



## 3. 测试

```shell
== Test running nettests == 
$ make qemu-gdb
(4.3s) 
== Test   nettest: ping == 
  nettest: ping: OK 
== Test   nettest: single process == 
  nettest: single process: OK 
== Test   nettest: multi-process == 
  nettest: multi-process: OK 
== Test   nettest: DNS == 
  nettest: DNS: OK 
== Test time == 
time: OK 
Score: 100/100
```



## 4. 结论&心得

十一个实验做完下来，对于操作系统的核心部分也都通过实验有了更加深入的了解。知道了线程和进程切换之间的区别以及上下文切换是如何进行的；从以前只直到页表这个概念到现在知道了整个分页机构是如何运行的。总之是操作系统进行了内核代码层面上的接触，了解xv6内核的实现，并以其为例子对操作系统有了更加深入的了解。



