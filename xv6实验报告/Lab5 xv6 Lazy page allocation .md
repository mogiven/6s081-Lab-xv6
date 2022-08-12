# Lab xv6 Lazy page allocation

##  0 Content

[toc]

## 1. Eliminate allocation from sbrk()

### 1.1 实验内容

更改 kernel/sysproc.c 中的 sys_sbrk() 函数，把原来只要申请就分配的逻辑改成申请时仅进行标注，即更改进程的 sz 字段。在`sbrk()`中提前为进程做好预分配内存的大小

### 1.2 实现

```c
uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  struct proc* p=myproc();
  addr = p->sz;
  p->sz+=n;//关键步骤
  if (n<0)
  {//如果空间是减少的则取消分配
    uvmdealloc(p->pagetable,addr,p->sz);
  }
  
  return addr;
}
```



## 2. Lazy allocation

### 2.1 实验内容

实现 `lazyalloc()`函数，完成懒分配的功能。关于懒分配：因为进程在申请内存时，很难精确地知道所需要的内存多大，因此，进程倾向于申请多于所需要的内存。这样会导致一个问题：有些内存可能一直不会使用，申请了很多内存但是使用的很少。懒分配模式就是解决这样一个问题。解决方法是：分配内存时，只增大进程的内存空间字段值，但并不实际进行内存分配；当该内存段需要使用时，会发现找不到内存页，抛出 page fault 中断，这时再进行物理内存的分配，然后重新执行指令。

### 2.2 实验步骤

1. 在def.h中声明函数

   ```c
   uint64          lazyalloc(struct proc *, uint64);
   ```

2. 在vm.c中实现lazyalloc函数,实现进程惰性分配内存

   ```c
   // lazy allocation memory va for proc p: handle page-fault.
   // return allocated memory (pa), 0 for failed 
   uint64 lazyalloc(struct proc * p, uint64 va){
     if(va >= p->sz || va < PGROUNDUP(p->trapframe->sp)){
       return 0;
     }
     char * mem;
     uint64 a = PGROUNDDOWN(va);
     mem = kalloc();
     if(mem == 0){
       return 0;
     }
     memset(mem, 0, PGSIZE);  
       if(mappages(p->pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
         kfree(mem);
         return 0;
       }
   
     return (uint64)mem;
   }
   ```

   注意：

   1. `p->trapframe->sp` 是指栈指针的位置，所以 `PGROUNDDOWN(p->trapframe->sp)` 是指栈顶最大值，是 guard 页的最大地址，用于防止栈溢出；
   2. `va>=p->sz`指虚拟地址不能超过堆实际分配的大小

3. 在 usertrap (`trap.c`) 里处理缺页错误，尝试惰性分配（调用`lazyalloc()`，失败就杀掉进程）

   ```c
   //trap.c
   if(r_scause() == 8){
       // system call
       ...
     } else if((which_dev = devintr()) != 0){
       // ok
     }else if((r_scause()==13) || (r_scause()==15)){
       if(lazyalloc(p,r_stval())<=0)
         p->killed=1;
     }else {
       ...
     }
   ```

   在trap.c中的注意要点

   - 如果申请内存成功了，如果虚拟地址不合法，需要释放掉这块内存；
   - page fault 的中断码是 13 和 15。因此，这里我们对 r_scause() 中断原因进行判断，如果是 13 或是 15，则说明没有找到地址
   - 错误的虚拟地址被保存在了 STVAL 寄存器中，我们取出该地址进行分配
   - 中断判断时，如果出错（虚拟地址不合法或者没有成功映射到物理地址），就杀死进程。

4. 修改`uvmunmap` ，该函数时释放内存时调用的。页表内有些地址并没有实际分配内存，因此没有进行映射，如果发现未分配的页，直接跳过，不需要 panic

   ```c
   	if((pte = walk(pagetable, a, 0)) == 0)
         //panic("uvmunmap: walk");
         continue;
       if((*pte & PTE_V) == 0)
         continue;
         //panic("uvmunmap: not mapped");
   ```

   

## 3. Lazytests and Usertests 

### 3.1 实验内容

通过测试`lazytes`t和`usertests`用例即可

### 3.2 实验步骤

1. 修改`uvmcopy`。fork 函数在创建进程时会调用 `uvmcopy` 函数。由于没有实际分配内存，因此，在这里，忽略 pte 无效，继续执行代码

   ``` c
   //vm.c
   	if((pte = walk(old, i, 0)) == 0)
         continue;
         //panic("uvmcopy: pte should exist");
       if((*pte & PTE_V) == 0)
         continue;
         //panic("uvmcopy: page not present");
   ```

2. 修改`walkaddr()`。由于进程利用系统调用已经到了内核中，页表已经切换为内核页表，无法直接访问虚拟地址。因此，需要通过 walkaddr 将虚拟地址翻译为物理地址。这里如果没找到对应的物理地址，就分配一个。

   ```c
   ...
   
     if(pte == 0)
       goto lzac;
     if((*pte & PTE_V) == 0)
       goto lzac;
     if((*pte & PTE_U) == 0)
       goto lzac;
     pa = PTE2PA(*pte);
    
     if (0) {
   lzac:
       if ((pa = lazyalloc(myproc(), va)) <= 0)
         pa = 0;
     }
   ```

## 4. 测试结果

```shell
== Test running lazytests == 
$ make qemu-gdb
(6.2s) 
== Test   lazy: map == 
  lazy: map: OK 
== Test   lazy: unmap == 
  lazy: unmap: OK 
== Test usertests == 
$ make qemu-gdb
(204.8s) 
== Test   usertests: pgbug == 
  usertests: pgbug: OK 
== Test   usertests: sbrkbugs == 
  usertests: sbrkbugs: OK 
== Test   usertests: argptest == 
  usertests: argptest: OK 
== Test   usertests: sbrkmuch == 
  usertests: sbrkmuch: OK 
== Test   usertests: sbrkfail == 
  usertests: sbrkfail: OK 
== Test   usertests: sbrkarg == 
  usertests: sbrkarg: OK 
== Test   usertests: stacktest == 
  usertests: stacktest: OK 
== Test   usertests: execout == 
  usertests: execout: OK 
== Test   usertests: copyin == 
  usertests: copyin: OK 
== Test   usertests: copyout == 
  usertests: copyout: OK 
== Test   usertests: copyinstr1 == 
  usertests: copyinstr1: OK 
== Test   usertests: copyinstr2 == 
  usertests: copyinstr2: OK 
== Test   usertests: copyinstr3 == 
  usertests: copyinstr3: OK 
== Test   usertests: rwsbrk == 
  usertests: rwsbrk: OK 
== Test   usertests: truncate1 == 
  usertests: truncate1: OK 
== Test   usertests: truncate2 == 
  usertests: truncate2: OK 
== Test   usertests: truncate3 == 
  usertests: truncate3: OK 
== Test   usertests: reparent2 == 
  usertests: reparent2: OK 
== Test   usertests: badarg == 
  usertests: badarg: OK 
== Test   usertests: reparent == 
  usertests: reparent: OK 
== Test   usertests: twochildren == 
  usertests: twochildren: OK 
== Test   usertests: forkfork == 
  usertests: forkfork: OK 
== Test   usertests: forkforkfork == 
  usertests: forkforkfork: OK 
== Test   usertests: createdelete == 
  usertests: createdelete: OK 
== Test   usertests: linkunlink == 
  usertests: linkunlink: OK 
== Test   usertests: linktest == 
  usertests: linktest: OK 
== Test   usertests: unlinkread == 
  usertests: unlinkread: OK 
== Test   usertests: concreate == 
  usertests: concreate: OK 
== Test   usertests: subdir == 
  usertests: subdir: OK 
== Test   usertests: fourfiles == 
  usertests: fourfiles: OK 
== Test   usertests: sharedfd == 
  usertests: sharedfd: OK 
== Test   usertests: exectest == 
  usertests: exectest: OK 
== Test   usertests: bigargtest == 
  usertests: bigargtest: OK 
== Test   usertests: bigwrite == 
  usertests: bigwrite: OK 
== Test   usertests: bsstest == 
  usertests: bsstest: OK 
== Test   usertests: sbrkbasic == 
  usertests: sbrkbasic: OK 
== Test   usertests: kernmem == 
  usertests: kernmem: OK 
== Test   usertests: validatetest == 
  usertests: validatetest: OK 
== Test   usertests: opentest == 
  usertests: opentest: OK 
== Test   usertests: writetest == 
  usertests: writetest: OK 
== Test   usertests: writebig == 
  usertests: writebig: OK 
== Test   usertests: createtest == 
  usertests: createtest: OK 
== Test   usertests: openiput == 
  usertests: openiput: OK 
== Test   usertests: exitiput == 
  usertests: exitiput: OK 
== Test   usertests: iput == 
  usertests: iput: OK 
== Test   usertests: mem == 
  usertests: mem: OK 
== Test   usertests: pipe1 == 
  usertests: pipe1: OK 
== Test   usertests: preempt == 
  usertests: preempt: OK 
== Test   usertests: exitwait == 
  usertests: exitwait: OK 
== Test   usertests: rmdot == 
  usertests: rmdot: OK 
== Test   usertests: fourteen == 
  usertests: fourteen: OK 
== Test   usertests: bigfile == 
  usertests: bigfile: OK 
== Test   usertests: dirfile == 
  usertests: dirfile: OK 
== Test   usertests: iref == 
  usertests: iref: OK 
== Test   usertests: forktest == 
  usertests: forktest: OK 
== Test time == 
time: OK 
Score: 119/119
```

