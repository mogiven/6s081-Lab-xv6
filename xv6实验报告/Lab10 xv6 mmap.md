# Lab xv6 mmap

## 1. 实验内容及思路

实验是要实现最基础的`mmap`功能。mmap即内存映射文件，将一个文件直接映射到内存当中，之后对文件的读写就可以直接通过对内存进行读写来进行，而对文件的同步则由操作系统来负责完成。使用`mmap`可以避免对文件大量`read`和`write`操作带来的内核缓冲区和用户缓冲区之间的频繁的数据拷贝。在Kafka消息队列等软件中借助`mmap`来实现零拷贝（zero-copy）

* 实现只考虑内存映射文件的 mmap 和 munmap 系统调用.
* mmap 参数 addr 一直为 0, 由内核决定映射文件的虚拟地址.
* mmap 参数 flags 只考虑 MAP_SHARED 和 MAP_PRIVATE.
* mmap 使用懒分配进行内存映射.
* 定义一个 VMA 结构体来描述一块虚拟内存的信息. 可以用定长数组记录.
  

## 2. 实验步骤

### 2.1 添加系统调用和函数声明

1. 修改makefile

   添加`$U/_mmaptest\`

2. 系统调用定义

   * 在syscall.h中添加`#define SYS_mmap 22`和`#define SYS_munmap 23`
   * 在syscall.c中添加`extern uint64 sys_mmap(void)`和`extern uint64 sys_munmap(void)`
   * 在syscall.c中添加数组值
   * 在usys.pl中添加`entry("mmap")`和`entry("munmap")`
   * 在user.h中添加`void *mmap(void*,int,int,int,int,int)`和`int munmap(void*,int)`

### 2.2 定义数据结构

1. 在kernel/proc.h中定义`struct vma`结构体

   ```c
   struct vma {
       uint64 addr;    // mmap address
       int len;    // mmap memory length
       int prot;   // permission
       int flags;  // the mmap flags
       int offset; // the file offset
       struct file* f;     // pointer to the mapped file
   };
   ```

2. 在`struct pro`中添加相关变量。

   对于每个进程都要使用一个VMA数组来记录映射的内存，而且VMA是进程的私有字段，对于xv6的单进程用户线程系统，访问VMA是不用加锁的

   ```c
   struct proc {
     // ...
     struct inode *cwd;           // Current directory
     char name[16];               // Process name (debugging)
     struct vm_area vma[NVMA];    // VMA array - lab10
   };
   ```

### 2.3 实现函数

1. 实现`sys_map()`。这个函数主要就是申请一个`vma`，之后查找一块空闲内存，填入相关信息，将`vma`插入到进程的`vma`链表中去：

   ```c
   uint64 sys_mmap(void) {
     uint64 addr;
     int len, prot, flags, offset;
     struct file *f;
     struct vm_area *vma = 0;
     struct proc *p = myproc();
     int i;
   
     if (argaddr(0, &addr) < 0 || argint(1, &len) < 0
         || argint(2, &prot) < 0 || argint(3, &flags) < 0
         || argfd(4, 0, &f) < 0 || argint(5, &offset) < 0) {
       return -1;
     }
     if (flags != MAP_SHARED && flags != MAP_PRIVATE) {
       return -1;
     }
     // the file must be written when flag is MAP_SHARED
     if (flags == MAP_SHARED && f->writable == 0 && (prot & PROT_WRITE)) {
       return -1;
     }
     // offset must be a multiple of the page size
     if (len < 0 || offset < 0 || offset % PGSIZE) {
       return -1;
     }
   
     // allocate a VMA for the mapped memory
     for (i = 0; i < NVMA; ++i) {
       if (!p->vma[i].addr) {
         vma = &p->vma[i];
         break;
       }
     }
     if (!vma) {
       return -1;
     }
   
     // assume that addr will always be 0, the kernel 
     //choose the page-aligned address at which to create
     //the mapping
     addr = MMAPMINADDR;
     for (i = 0; i < NVMA; ++i) {
       if (p->vma[i].addr) {
         // get the max address of the mapped memory  
         addr = max(addr, p->vma[i].addr + p->vma[i].len);
       }
     }
     addr = PGROUNDUP(addr);
     if (addr + len > TRAPFRAME) {
       return -1;
     }
     vma->addr = addr;   
     vma->len = len;
     vma->prot = prot;
     vma->flags = flags;
     vma->offset = offset;
     vma->f = f;
     filedup(f);     // increase the file's reference count
   
     return addr;
   }
   ```

2. 处理缺页中断

   由于在 sys_mmap() 中对文件映射的内存采用的是 Lazy allocation, 因此需要对访问文件映射内存产生的 page fault 进行处理. 和之前 Lazy allocation 和 COW 的实验相同, 即修改 kernel/trap.c 中 usertrap() 的代码.

   ```c
   if(r_scause() == 8){
       // ...
     } else if (r_scause() == 12 || r_scause() == 13
                || r_scause() == 15) { // mmap page fault - lab10
       char *pa;
       uint64 va = PGROUNDDOWN(r_stval());
       struct vm_area *vma = 0;
       int flags = PTE_U;
       int i;
       // find the VMA
       for (i = 0; i < NVMA; ++i) {
         // like the Linux mmap, it can modify the remaining bytes in
         //the end of mapped page
         if (p->vma[i].addr && va >= p->vma[i].addr
             && va < p->vma[i].addr + p->vma[i].len) {
           vma = &p->vma[i];
           break;
         }
       }
       if (!vma) {
         goto err;
       }
       // set write flag and dirty flag to the mapped page's PTE
       if (r_scause() == 15 && (vma->prot & PROT_WRITE)
           && walkaddr(p->pagetable, va)) {
         if (uvmsetdirtywrite(p->pagetable, va)) {
           goto err;
         }
       } else {
         if ((pa = kalloc()) == 0) {
           goto err;
         }
         memset(pa, 0, PGSIZE);
         ilock(vma->f->ip);
         if (readi(vma->f->ip, 0, (uint64) pa, va - vma->addr + vma->offset, PGSIZE) < 0) {
           iunlock(vma->f->ip);
           goto err;
         }
         iunlock(vma->f->ip);
         if ((vma->prot & PROT_READ)) {
           flags |= PTE_R;
         }
         // only store page fault and the mapped page can be written
         //set the PTE write flag and dirty flag otherwise don't set
         //these two flag until next store page falut
         if (r_scause() == 15 && (vma->prot & PROT_WRITE)) {
           flags |= PTE_W | PTE_D;
         }
         if ((vma->prot & PROT_EXEC)) {
           flags |= PTE_X;
         }
         if (mappages(p->pagetable, va, PGSIZE, (uint64) pa, flags) != 0) {
           kfree(pa);
           goto err;
         }
       }
     }else if((which_dev = devintr()) != 0){
       // ok
     } else {
   err:
       printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
       printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
       p->killed = 1;
     }
   ```

3. 实现`sys_munmap()`系统调用

   `sys_munmap()`系统调用即将映射的部分内存进行取消映射, 同时若为 MAP_SHARED 则需要将对文件映射内存的修改会写到文件中。

   ```c
   uint64 sys_munmap(void) {
     uint64 addr, va;
     int len;
     struct proc *p = myproc();
     struct vm_area *vma = 0;
     uint maxsz, n, n1;
     int i;
   
     if (argaddr(0, &addr) < 0 || argint(1, &len) < 0) {
       return -1;
     }
     if (addr % PGSIZE || len < 0) {
       return -1;
     }
   
     // find the VMA
     for (i = 0; i < NVMA; ++i) {
       if (p->vma[i].addr && addr >= p->vma[i].addr
           && addr + len <= p->vma[i].addr + p->vma[i].len) {
         vma = &p->vma[i];
         break;
       }
     }
     if (!vma) {
       return -1;
     }
   
     if (len == 0) {
       return 0;
     }
   
     if ((vma->flags & MAP_SHARED)) {
       // the max size once can write to the disk
       maxsz = ((MAXOPBLOCKS - 1 - 1 - 2) / 2) * BSIZE;
       for (va = addr; va < addr + len; va += PGSIZE) {
         if (uvmgetdirty(p->pagetable, va) == 0) {
           continue;
         }
         // only write the dirty page back to the mapped file
         n = min(PGSIZE, addr + len - va);
         for (i = 0; i < n; i += n1) {
           n1 = min(maxsz, n - i);
           begin_op();
           ilock(vma->f->ip);
           if (writei(vma->f->ip, 1, va + i, va - vma->addr + vma->offset + i, n1) != n1) {
             iunlock(vma->f->ip);
             end_op();
             return -1;
           }
           iunlock(vma->f->ip);
           end_op();
         }
       }
     }
     uvmunmap(p->pagetable, addr, (len - 1) / PGSIZE + 1, 1);
     // update the vma
     if (addr == vma->addr && len == vma->len) {
       vma->addr = 0;
       vma->len = 0;
       vma->offset = 0;
       vma->flags = 0;
       vma->prot = 0;
       fileclose(vma->f);
       vma->f = 0;
     } else if (addr == vma->addr) {
       vma->addr += len;
       vma->offset += len;
       vma->len -= len;
     } else if (addr + len == vma->addr + vma->len) {
       vma->len -= len;
     } else {
       panic("unexpected munmap");
     }
     return 0;
   }
   ```

4. 修改`fork()`和`exit()`，田间对进程文件映射内存及VMA数组的处理

   ```c
   //exit()
   // unmap the mapped memory - lab10
     for (i = 0; i < NVMA; ++i) {
       if (p->vma[i].addr == 0) {
         continue;
       }
       vma = &p->vma[i];
       if ((vma->flags & MAP_SHARED)) {
         for (va = vma->addr; va < vma->addr + vma->len; va += PGSIZE) {
           if (uvmgetdirty(p->pagetable, va) == 0) {
             continue;
           }
           n = min(PGSIZE, vma->addr + vma->len - va);
           for (r = 0; r < n; r += n1) {
             n1 = min(maxsz, n - i);
             begin_op();
             ilock(vma->f->ip);
             if (writei(vma->f->ip, 1, va + i, va - vma->addr + vma->offset + i, n1) != n1) {
               iunlock(vma->f->ip);
               end_op();
               panic("exit: writei failed");
             }
             iunlock(vma->f->ip);
             end_op();
           }
         }
       }
       uvmunmap(p->pagetable, vma->addr, (vma->len - 1) / PGSIZE + 1, 1);
       vma->addr = 0;
       vma->len = 0;
       vma->offset = 0;
       vma->flags = 0;
       vma->offset = 0;
       fileclose(vma->f);
       vma->f = 0;
     }
   
   
   //fork()
   // copy all of VMA - lab10
     for (i = 0; i < NVMA; ++i) {
       if (p->vma[i].addr) {
         np->vma[i] = p->vma[i];
         filedup(np->vma[i].f);
       }
     }
   ```

   

## 3. 测试

```shell
== Test running mmaptest == 
$ make qemu-gdb
(5.7s) 
== Test   mmaptest: mmap f == 
  mmaptest: mmap f: OK 
== Test   mmaptest: mmap private == 
  mmaptest: mmap private: OK 
== Test   mmaptest: mmap read-only == 
  mmaptest: mmap read-only: OK 
== Test   mmaptest: mmap read/write == 
  mmaptest: mmap read/write: OK 
== Test   mmaptest: mmap dirty == 
  mmaptest: mmap dirty: OK 
== Test   mmaptest: not-mapped unmap == 
  mmaptest: not-mapped unmap: OK 
== Test   mmaptest: two files == 
  mmaptest: two files: OK 
== Test   mmaptest: fork_test == 
  mmaptest: fork_test: OK 
== Test usertests == 
$ make qemu-gdb
usertests: OK (202.7s) 
== Test time == 
time: OK 
Score: 140/140
```

