# Lab xv6 Lock

[toc]

## 1. Memory Allocator

### 1.1 实验内容和思路

你的工作是实现每个 CPU 的空闲列表，并在 CPU 的空闲列表为空时进行窃取。 您必须为所有以“kmem”开头的锁命名。 也就是说，您应该为每个锁调用 initlock，并传递一个以“kmem”开头的名称。 运行 kalloctest 以查看您的实现是否减少了锁争用。 要检查它是否仍然可以分配所有内存，请运行 usertests sbrkmuch。 您的输出将类似于下图所示，kmem 锁的争用总量大大减少，尽管具体数字会有所不同。 确保 usertests 中的所有测试都通过。

hints:

- 你可以使用*kernel/param.h* 中的*NCPU* （NCPU表示XV6使用了几个虚拟处理器，而xv6对于每个进程只有一个线程，该提示表示我们可以基于CPU数量进行修改）
- 让*freerange* 将所有空闲内存块给予 正在运行 *freerange* 的CPU（如果所有空闲内存都给了一个CPU，那么其他CPU怎么办？--从有空闲内存块的CPU拿吗？）
- 函数 *cpuid()* 返回当前的 *cpu* 编号， 不过需要关闭中断才能保证该函数被安全地使用。中断开关可使用 *push_off()* 和 *pop_off()*
- 用 *kmem* 命名你的锁 （提示我们需要创建额外的锁）

### 1.2 实验步骤

1. 为每个CPU创建一个内存池

   ~~~c
   struct {
     struct spinlock lock;
     struct run *freelist;
     char lock_name[7];
   } kmem[NCPU];
   ~~~

2. 在`kinit()`中对每个锁进行初始化

   ```c
   for (int i = 0; i < NCPU; i++) {
       snprintf(kmem[i].lock_name, sizeof(kmem[i].lock_name), "kmem_%d", i);
       initlock(&kmem[i].lock, kmem[i].lock_name);
     }
   ```

3. 在`kfree()`中将物理内存的空闲页加入当前cpu的空闲页链表

   ````c
     r = (struct run*)pa;
   
     push_off();
     int id = cpuid();
   
     acquire(&kmem[id].lock);
     r->next = kmem[id].freelist;
     kmem[id].freelist = r;
     release(&kmem[id].lock);
   
     pop_off();
   ````

4. 对于`kalloc()`函数，当在当前核心上申请失败时，窃取其他cpu上的空闲页面。实现方法采用双指针方法，一个快指针移动的步长为2，一个慢指针移动的步长为1，当快指针到达链表尾端时，慢指针指向链表的中间，此时将空闲页面链表的前半部分分配给申请的CPU。

   ```c
     if(r)
       kmem[id].freelist = r->next;
     else{
       // 如果当前cpu没有空闲页面，则到其他cpu上申请页面
       int flag = 0;//success or fail
       int i = 0;
       for(i = 0; i < NCPU; i++) {
         if (i == id) continue;
   
         acquire(&kmem[i].lock);
         struct run *p = kmem[i].freelist;
         if(p) {
           // steal half of memory
           //fp每次移动两个步长，p移动一个步长，pre是p的前指针
           struct run *fp = p; // faster pointer
           struct run *pre = p;
           while (fp && fp->next) {
             fp = fp->next->next;
             pre = p;
             p = p->next;
           }//fp到链表尾端，p指向链表中段
   
           kmem[id].freelist = kmem[i].freelist;//本cpu获取前半段页面
           if (p == kmem[i].freelist) {
             // only have one page
             kmem[i].freelist = 0;
           }
           else {
             kmem[i].freelist = p;
             pre->next = 0;
           }
           flag = 1;
         }
         release(&kmem[i].lock);
   
         if (flag) {
           r = kmem[id].freelist;
           kmem[id].freelist = r->next;
           break;
         }
       }
     }
   ```

   

## 2. Buffer cache

### 2.1 实验内容和思路

修改块缓存，使运行 bcachetest 时 bcache 中所有锁的获取循环迭代次数接近于零。 理想情况下，块缓存中涉及的所有锁的计数总和应该为零，但如果总和小于 500 也可以。修改 bget 和 brelse 以便对 bcache 中的不同块的并发查找和释放不太可能 锁冲突（例如，不必都等待 bcache.lock）。 您必须保持每个块最多缓存一个副本的不变量。 完成后，您的输出应该与下图类似（尽管不相同）。 确保用户测试仍然通过。

实验思路：

1. 使用用哈希表来代替链表。这样每次获取和释放的时候，都只需要对哈希表的一个桶进行加锁，桶之间的操作就可以并行。
2. 在buf结构体中添加timetamp变量来记录LRU最近最少使用的信息。

### 2.2 实验步骤

1. 定义哈希桶结构体，hashtable.lock为桶级锁

   ```c
   struct bucket {
     struct spinlock lock;
     struct buf head;
   }hashtable[NBUCKET];
   ```

2. 在`binit()`函数中对哈希表进行初始化，将`bcache.buf[NBUF]`中的块平均分配给每个桶，记得设置`b->blockno`使块的hash与桶相对应，后面需要根据块来查找对应的桶。

   ```c
   void
   binit(void)
   {
     struct buf *b;
   
     initlock(&bcache.lock, "bcache");
   
     for(b = bcache.buf; b < bcache.buf+NBUF; b++){
       initsleeplock(&b->lock, "buffer");
     }
   
     b = bcache.buf;
     for (int i = 0; i < NBUCKET; i++) {
       initlock(&hashtable[i].lock, "bcache_bucket");
       for (int j = 0; j < NBUF / NBUCKET; j++) {
         b->blockno = i; // hash(b) should equal to i
         b->next = hashtable[i].head.next;
         hashtable[i].head.next = b;
         b++;
       }
     }
   }
   ```

3. `bget()`的功能实现

   - 在对应的用中寻找当前的内存块是否缓存，如果找到了就直接返回。如果没找到则需要查找一个块变更且替换。
   - 寻找的策略时先搜素桶内的空闲块，然后再去全局查找
   - 在全局查找时，需要给表级锁上锁。对于找的的块，需要先将该块原属的桶上锁，然后取下在释放锁，最后添加到需要该块的桶上。

   ```c
   // First try to find in current bucket.
     int min_time = 0x8fffffff;
     struct buf* replace_buf = 0;
   
     for(b = bucket->head.next; b != 0; b = b->next){
       if(b->refcnt == 0 && b->timestamp < min_time) {
         replace_buf = b;
         min_time = b->timestamp;
       }
     }
     if(replace_buf) {
       // printf("Local %d %p\n", idx, replace_buf);
       goto find;
     }
   
     // Try to find in other bucket.
     acquire(&bcache.lock);
     refind:
     for(b = bcache.buf; b < bcache.buf + NBUF; b++) {
       if(b->refcnt == 0 && b->timestamp < min_time) {
         replace_buf = b;
         min_time = b->timestamp;
       }
     }
     if (replace_buf) {
       // remove from old bucket
       int ridx = hash(replace_buf->dev, replace_buf->blockno);
       acquire(&hashtable[ridx].lock);
       if(replace_buf->refcnt != 0)  // be used in another bucket's local find between finded and acquire
       {
         release(&hashtable[ridx].lock);
         goto refind;
       }
       struct buf *pre = &hashtable[ridx].head;
       struct buf *p = hashtable[ridx].head.next;
       while (p != replace_buf) {
         pre = pre->next;
         p = p->next;
       }
       pre->next = p->next;
       release(&hashtable[ridx].lock);
       // add to current bucket
       replace_buf->next = hashtable[idx].head.next;
       hashtable[idx].head.next = replace_buf;
       release(&bcache.lock);
   ```

4. `bpin()`和`bunpin()`中的表级锁替换成桶级锁

## 3. 测试

```shell
== Test running kalloctest == 
$ make qemu-gdb
(128.9s) 
== Test   kalloctest: test1 == 
  kalloctest: test1: OK 
== Test   kalloctest: test2 == 
  kalloctest: test2: OK 
== Test kalloctest: sbrkmuch == 
$ make qemu-gdb
kalloctest: sbrkmuch: OK (13.5s) 
== Test running bcachetest == 
$ make qemu-gdb
(49.0s) 
== Test   bcachetest: test0 == 
  bcachetest: test0: OK 
== Test   bcachetest: test1 == 
  bcachetest: test1: OK 
== Test usertests == 
$ make qemu-gdb
usertests: OK (205.3s) 
== Test time == 
time: OK 
Score: 70/70
```



