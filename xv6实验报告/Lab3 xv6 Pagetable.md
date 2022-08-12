# Lab：xv6 Pagetable

## 0. Content

[toc]

## 1. vmprint

### 1.1 实验要求和思路

将给定的页表的内容按照要求的格式打印出来。参考proc.c/freewalk()函数：其思路是在一级和二级页表中，每次遍历所有的pte，如果该pte的valid位置位，就递归调用freewalk，然后将pte清零，再释放本页的内存。当递归到三级页表时，因为所有pte都为0，只会释放本页，不会递归调用下去。

### 1.2 实验步骤

#### 1.2.1函数实现

```c
void vmprintRec(pagetable_t pagetable, int level){
   int dot = (level + 1) * 2;
    for(int i = 0; i < 512; i++){
      pte_t pte = pagetable[i];
      if(pte & PTE_V){
          for(int j = 0; j < dot; j++){
            if(j %2 == 0){
              printf(" ");
            }
            printf("."); 
          }
          printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
          if(level < 2){
            uint64 child = PTE2PA(pte);
            vmprintRec((pagetable_t)child, level + 1);
          }
      }
    } 
}
void vmprint(pagetable_t pagetable){
    printf("page table %p\n", pagetable);
    vmprintRec(pagetable, 0);
}
```

#### 1.2.2 添加声明和调用

1. 在`exec.c`中的`exec()`添加`if(p->pid==1) vmprint(p->pagetable)`
2. 在`def.h`中添加`vmprint()`函数声明

## 2. A kernel page table per process

### 2.1 实验要求和思路

xv6只有一张全局内核页表，直接映射物理内存。每个进程只有只有一张隐身用户地址空间的用户页表，而其地址在内核中是不合法的。当内核需要使用系统调用传入的用户地址空间的指针时，内核就必须先将该指针转化为实际的物理地址。实验思路：

1. 修改内核使得每个进程在内核中执行时使用自己的对内核页表的拷贝副本（同时也包含自己用户空间的映射）。
2. 修改struct proc使得每个进程维持一张内核页表
3. 修改scheduler使得切换进程时切换内核页表。

### 2.2 实验实现

实现的进程的内核页表中包含进程用户页表的所有映射、内核自身页表中CLINT到PHYSTOP的所有映射、以及该进程对应的内核栈的映射和trampoline的映射。

1. 修改proc结构体：

```c
pagetable_t kernelpt;   
```

2. 模仿kvminit，对进程的内核页表添加从CLINT到PHYSTOP的映射和trampoline的映射。

```c
//create a copy of the kernel page when the kvminit is done
//return the copy's pointer
//将内存中的部分的内容映射到进程的内核页表
pagetable_t createKpCopy(){
    pagetable_t kp = (pagetable_t) kalloc();
    memset(kp, 0, PGSIZE);
    // uart registers
    kvmmapforUkm(UART0, UART0, PGSIZE, PTE_R | PTE_W, kp);

    // virtio mmio disk interface
    kvmmapforUkm(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W, kp);

    // CLINT
    kvmmapforUkm(CLINT, CLINT, 0x10000, PTE_R | PTE_W, kp);

    // PLIC
    kvmmapforUkm(PLIC, PLIC, 0x400000, PTE_R | PTE_W, kp);

    // map kernel text executable and read-only.
    kvmmapforUkm(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X, kp);

    // map kernel data and the physical RAM we'll make use of.
    kvmmapforUkm((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W, kp);

    // map the trampoline for trap entry/exit to
    // the highest virtual address in the kernel.
    kvmmapforUkm(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X, kp);
    
    return kp;
}

// add a mapping to the user's copy of the kernel page table.
// does not flush TLB or enable paging.
void
kvmmapforUkm(uint64 va, uint64 pa, uint64 sz, int perm, pagetable_t kp)
{
  if(mappages(kp, va, sz, pa, perm) != 0)
    panic("kvmmap");
}
```

3. 然后修改proc.c的allocproc()函数，在进程分配时调用上述`createKpmap()`函数。每个进程的内核页表中增加该进程内核栈的映射。注意：因为该进程内核栈的映射已经在procinit中存放在内核页表中，而该内核栈的虚拟地址va存放在该进程的proc结构体中，所以这里只需要利用va找到对应的pte，然后拷贝过来即可

```c
extern pagetable_t kernel_page; //from vm.c

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc*
allocproc(void)
{
  ...

  // An empty user page table.
  p->pagetable = proc_pagetable(p);
  if(p->pagetable == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  
    //增加的代码
  p->kernelpt = createKpCopy();
  // if createKpCopy() return 0, there is a memeory allocation failue
  if(p->kernelpt == 0){
    freeproc(p);
    release(&p->lock);
    return 0;
  }
  
    //拷贝内核页表中该进程内核栈的映射到该进程自己的内核页表，pte页表项
  pte_t* pte = walk(kernel_pagetable, p->kstack, 0);
  if(pte == 0){
    panic("allocproc fails due to failing copying the kernel stack");
  }
  uint64 pa = PTE2PA(*pte);
  int perm = PTE_FLAGS(*pte);
  // copy the map of the process's kernel stack into the process's kernel pagetable
  kvmmapforUkm(p->kstack, pa, PGSIZE, perm, p->kernelpt);

    ...

  return p;
}
```

5. 修改scheduler，若有可运行的进程，则将其内核页表地址写入satp寄存器，刷新TLB，然后切换上下文到该进程的上下文。

```c
void
scheduler(void)
{
  ...
        p->state = RUNNING;
        c->proc = p;
          
        w_satp(MAKE_SATP(p->kernelpt));
        sfence_vma();
        //这里将当前cpu寄存器值保存，将p的上下文加载到该cpu寄存器中
        //提前将进程的内核页表写入satp寄存器，返回内核时就会使用该进程的内核页表
        swtch(&c->context, &p->context);
        // Process is done running for now.
        // It should have changed its p->state before coming back.
        c->proc = 0;
        //必须切回全局内核页表
        w_satp(MAKE_SATP(kernel_pagetable));
        sfence_vma();
      }
      release(&p->lock);
    }
#if !defined (LAB_FS)
    if(found == 0) {
      intr_on();
      //若没有可运行进程，则将内核自身页表写入satp寄存器并刷新TLB
      w_satp(MAKE_SATP(kernel_pagetable));
      sfence_vma();  
      asm volatile("wfi");
    }
#else
    ;
#endif
  }
}
```

6. 在freeproc()中释放一个进程的内核页表。具体实现在`freeUserKp()`函数中

```c
// free a proc structure and the data hanging from it,
// including user pages.
// p->lock must be held.
static void
freeproc(struct proc *p)
{
  ...
  p->state = UNUSED;
  if(p->kernelpt){
    freeUserKp(p->kernelpt, 0);
  }
  p->kernelpt = 0;
}
```

freeUserKp：释放用户的内核页表所占的物理页，对应内容清零

```c
void freeUserKp(pagetable_t kp, int level){
  if(level == 3) return;
  for(int i = 0; i < 512; i++){
    pte_t pte = kp[i];
    if(pte & PTE_V){
      uint64 child = PTE2PA(pte);
      freeUserKp((pagetable_t)child, level + 1);
      kp[i] = 0;
      //kp[i] &= (~PTE_V);
    }
  }
  kfree((void*)kp);
}
```

## 3. Simplify

### 3.1 实验要求和思路

**将每个进程的内核页表中增加用户映射，从而使得copyin可以直接解引用用户指针**

关于PLIC：v6的用户进程地址空间从0开始， 而内核地址开始于更高的地址。但是这种方式限制了一个用户进程的最大size要小于内核的最低虚拟地址。内核boot以后，内核的最低虚拟地址为0xC000000， 也是PLIC寄存器的地址。需要修改xv6来防止用户进程增长超过PLIC的地址。

思路：

- 首先替换copyin和copyinstr
- 在用户页表修改时对应修改该进程的内核页表。包括fork，exec和sbrk
- 在userinit中将第一个进程的用户页表加到该进程的内核页表
- 用户进程的内核页表中的用户地址对应的PTE的权限管理（PTE_U项修改后内核无法访问）
- PLIC限制

### 3.2 实验实现

#### 3.2.1 copyin & copyin_new

1. copyin_new

这里就直接使用了传入的用户空间的虚拟地址作为内核的虚拟地址来使用

```c
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  struct proc *p = myproc();

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    return -1;
  //因为用户进程的虚拟地址映射也放入了该进程的内核页表，所以可以直接使用该进程的虚拟地址srcva
  memmove((void *) dst, (void *)srcva, len);
  stats.ncopyin++;   // XXX lock
  return 0;
}
```

2. copyin

```c
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  return copyin_new(pagetable, dst, srcva, len);
}
```

#### 3.2.2 用户到内核页表的映射

1. U2KPageCopy：将用户页表中oldsz到newsze的虚拟地址空间的映射添加到该用户的内核页表中，**并清除U位**. 或从内核页表中删除newsz到oldsz的映射（uvmmalloc和uvmdealloc修改用户页表映射的内核页表版本）

```c
void U2KPageCopy(pagetable_t up, pagetable_t kp, uint64 oldsz, uint64 newsz){
    
    uint64 i, pa;
    uint flags;
    pte_t *pte;
    if(oldsz < newsz){
      //oldsz如果不是所属页的起始地址，则该页已经被添加到该用户的内核页表中了
      oldsz = PGROUNDUP(oldsz);
      for(i = oldsz; i < newsz; i += PGSIZE){
        if((pte = walk(up, i, 0)) == 0){
          panic("U2KPageCopy fails: pte should exits");
        }
      
        if((*pte & PTE_V) == 0){
          panic("U2KPageCopy fails: page not present");
        }
        
        pa = PTE2PA(*pte);
        flags = PTE_FLAGS(*pte);
        //清除U位，内核态下
        flags &= (~PTE_U);
        if((pte = walk(kp, i, 1)) == 0){
          panic("U2KPageCopy fails to find the  corresponding pte of user kernel page");
        }
        *pte = PA2PTE(pa) | flags;
      }
    }
    //下面的可以参考uvmunmap（移除从va开始的npagesof mapping）
    if(oldsz > newsz){
      //如果newze不是所在页的首地址，该page的映射交由下次清除
      newsz = PGROUNDUP(newsz);
      for(i = newsz; i < oldsz; i += PGSIZE){
        if((pte = walk(kp, i, 0)) == 0){
          panic("U2KPageCopy fails: pte should exits");
        }
        if((*pte & PTE_V) == 0){
          panic("U2KPageCopy fails: page not present");
        }
        //去标志位
        *pte = 0;
      }
    }
}
```

2. 函数调用

   **首先，在创建第一个进程的函数userinit中需要加**。userinit先调用allocproc，此时进程的内核页表中已经有了和内核页表一样的映射了，然后userinit调用uvminit分配了一个pagetable装指令和数据。所以得把这个映射存入进程的内核页表。

```c
// Set up first user process.
void
userinit(void)
{
···
  
  // allocate one user page and copy init's instructions
  // and data into it.
  uvminit(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;
  U2KPageCopy(p->pagetable, p->kernelpt, 0, p->sz);

···
}
```

3. fork

   fork先调用allocproc()，而allocproc中已经分配好了一个只映射了trapframe和trampoline的用户页表，并调用createKpCopy()创建了一个用户进程的内核页表。之后fork调用uvmcopy将父进程的页表和对应物理内存的内容都拷贝给子进程，**所以这里修改了子进程的用户态页表，需要同步在子进程的内核态页表中添加对应的映射**。

```c
U2KPageCopy(np->pagetable, np->kernelpt, 0, np->sz);
```

4. exec

   fork产生的子进程往往会调用exec来执行新的程序。exec中会释放子进程当前的物理内存，将elf文件指定的内容载入内存中并分配新的stack page和guard page。所以用户的内核页表需要同步地释放子进程当前的物理内存映射，然后增加新的映射（别的解析里只增加新的映射，没有清除原映射。虽然没有报错，但是其实是有问题的）

```c
// 先清除原映射
U2KPageCopy(pagetable, p->kernelpt, oldsz, 0);
// 再增加新的映射
U2KPageCopy(pagetable, p->kernelpt, 0, sz);
```

5. sbrk

   分配和释放内存修改用户页表，需要sbrk系统调用，其调用growproc()函数实现。这里需要调用U2KPageCopy来维持用户的内核页表和用户页表保持同步。同时，**需要保证用户的虚拟地址空间不能增长到PLIC**.

```c
if(n > 0){
    //该进程的用户虚拟地址不能增长到PLIC
    if(PGROUNDUP(sz + n) >= PLIC){
      return -1;
    }
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
      return -1;
    }
    //往该进程的内核页表中增加相映的地址空间映射
    U2KPageCopy(p->pagetable, p->kernelpt, sz -n, sz);
  } else if(n < 0){
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    //往该进程的内核页表中去除相映的地址空间映射
    U2KPageCopy(p->pagetable, p->kernelpt, sz - n, sz);
  }
  p->sz = sz;
```

## 4. 总结

### 4.1 实验心得

本次实验是目前最耗时的实验，重温了虚拟内存和页表的知识，但是在实验中还是到处磕绊。后两节实验大致是创建一个供进程维护的内核级页表，在系统进行地址转换时访问进程的内核页表代替访问内核的全局页表，每个进程负责维护对应的内核级页表。同时还需要将进程的用户页表和进程的内核页表的虚拟地址空间映射对应起来，在用户指针传递到内核时可以直接引用。

### 4.2 make grade

受限对本次实验没有全面理解，实验只有40/60分

```
== Test pte printout == 
$ make qemu-gdb
pte printout: OK (4.3s) 
== Test answers-pgtbl.txt == answers-pgtbl.txt: FAIL 
    Cannot read answers-pgtbl.txt
== Test count copyin == 
$ make qemu-gdb
count copyin: OK (0.9s) 
== Test usertests == 
$ make qemu-gdb
Timeout! (300.1s) 
== Test   usertests: copyin == 
  usertests: copyin: OK 
== Test   usertests: copyinstr1 == 
  usertests: copyinstr1: OK 
== Test   usertests: copyinstr2 == 
  usertests: copyinstr2: OK 
== Test   usertests: copyinstr3 == 
  usertests: copyinstr3: OK 
== Test   usertests: sbrkmuch == 
  usertests: sbrkmuch: OK 
== Test   usertests: all tests == 
  usertests: all tests: FAIL 
    ...
                     sepc=0x0000000000002188 stval=0x000000000000fbc0
         OK
         test opentest: OK
         test writetest: OK
         test writebig: qemu-system-riscv64: terminating on signal 15 from pid 24457 (make)
    MISSING '^ALL TESTS PASSED$'
== Test time == 
time: FAIL 
    Cannot read time.txt
Score: 40/66
```



