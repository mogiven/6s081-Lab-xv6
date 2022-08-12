# Lab：xv6 System Call

[toc]

实验目的：向 xv6 添加一些新的系统调用，了解它们的工作原理和一些内部组件。在后面的实验中添加更多系统调用。

## 1. Trace

### 1.1 实验要求

以trace为例，了解xv6系统调用是如何实现的，具体功能根据参数追踪相应的系统调用。



### 1.2 实验步骤

1. 添加$U/_trace到Makefile中的UPROGS变量里

   ```makefile
   	$U/_grind\
   	$U/_wc\
   	$U/_zombie\
   	$U/_trace\
   ```

2. 在user/user.h中添加声明，以便编译识别trace.c时

   ```c
   char* sbrk(int);
   int sleep(int);
   int uptime(void);
   int trace(int);//添加trace声明
   ```

   

3. 添加一个entry到user/usys.pl

   ```
   entry("sleep");
   entry("uptime");
   entry("trace");//添加trace声明
   ```

4. 在kernel/syscall.h中添加sysname数组

   ```c
   char *sysname[] = {
   [SYS_fork]    "fork",
   [SYS_exit]    "exit",
   [SYS_wait]    "wait",
   [SYS_pipe]    "pipe",
   [SYS_read]    "read",
   [SYS_kill]    "kill",
   [SYS_exec]    "exec",
   [SYS_fstat]   "stat",
   [SYS_chdir]   "chdir",
   [SYS_dup]     "dup",
   [SYS_getpid]  "getpid",
   [SYS_sbrk]    "sbrk",
   [SYS_sleep]   "sleep",
   [SYS_uptime]  "uptime",
   [SYS_open]    "open",
   [SYS_write]   "write",
   [SYS_mknod]   "mknod",
   [SYS_unlink]  "unlink",
   [SYS_link]    "link",
   [SYS_mkdir]   "mkdir",
   [SYS_close]   "close",
   [SYS_trace]   "trace",
   };
   ```

5. 添加并实现sys_trace()到kernel/sysproc.

   ```c
   uint64
   sys_trace(void)
   {
     int mask;
     if(argint(0, &mask) < 0)
       return -1;
     
     myproc()->mask = mask;
     return 0;
   }
   ```

   

6. 修改proc结构体，增加mask变量

   ```c
   // Per-process state
   struct proc {
     struct spinlock lock;
   
     // p->lock must be held when using these:
     enum procstate state;        // Process state
     struct proc *parent;         // Parent process
     void *chan;                  // If non-zero, sleeping on chan
     int killed;                  // If non-zero, have been killed
     int xstate;                  // Exit status to be returned to parent's wait
     int pid;                     // Process ID
   
     // these are private to the process, so p->lock need not be held.
     uint64 kstack;               // Virtual address of kernel stack
     uint64 sz;                   // Size of process memory (bytes)
     pagetable_t pagetable;       // User page table
     struct trapframe *trapframe; // data page for trampoline.S
     struct context context;      // swtch() here to run process
     struct file *ofile[NOFILE];  // Open files
     struct inode *cwd;           // Current directory
     char name[16];               // Process name (debugging)
     int mask;                    // 添加mask值
   };
   ```

7. 修改kernel/proc.c中的fork函数，添加子进程复制父进程mask的功能

   ```c
   int
   fork(void)
   {
     /* do something .... */
     safestrcpy(np->name, p->name, sizeof(p->name));
     
     // 复制 mask
     np->mask = p->mask;
   
     pid = np->pid;
   
     np->state = RUNNABLE;
   
     release(&np->lock);
   
     return pid;
   }
   ```

   

8. 修改syscall.c中的syscall函数

   ```c
   void
   syscall(void)
   {
     int num;
     struct proc *p = myproc();
   
     num = p->trapframe->a7;
     if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
       p->trapframe->a0 = syscalls[num]();
       // 添加追踪功能
       if (p->mask & (1 << num))
       {
         printf("%d: syscall %s -> %d\n",p->pid, syscalls_name[num], p->trapframe->a0);
       }
     } else {
       printf("%d %s: unknown sys call %d\n",
               p->pid, p->name, num);
       p->trapframe->a0 = -1;
     }
   }
   ```

   

### 1.3 实验结果

成功记录每个系统调用

![](https://thumbnail0.baidupcs.com/thumbnail/d612e3df4r5d57bf4198f6d173183cc3?fid=1099950169229-250528-548271812866027&time=1659060000&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-Z39CpTd86mKjabA3a%2B7eL2HEDkQ%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=245818770601388082&dp-callid=0&file_type=0&size=c1536_u864&quality=90&vuk=-&ft=video&autopolicy=1)

## 2. Sysinfo

### 2.1 实验要求

实现一个可以获得当前系统可用进程数和可用内存的函数

### 2.2 实验步骤

1. 在makefile文件中添加`$U/_sysinfotest\`

   ```makefile
   	$U/_zombie\
   	$U/_trace\
   	$U/_sysinfotest\
   ```

2. 在user/user.h中添加结构体声明和函数声明

3. 在user/usys.pl中添加`entry("sysinfo")`

4. 为了在内核中实现sys_sysinfo函数，需要在kernel/proc.c和kernel/kalloc.c中分别添加函数获取正在使用的进程和可用的内存数

   

   ```c
   //proc.c
   int
   proc_size()
   {
     int i;
     int n = 0;
     for (i = 0; i < NPROC; i++)
     {
       if (proc[i].state != UNUSED) n++;
     }
     return n;
   }
   ```

   ```c
   //kalloc.c
   uint64 
   freememory()
   {
     struct run* p = kmem.freelist;
     uint64 num = 0;
     while (p)
     {
       num ++;
       p = p->next;
     }
     return num * PGSIZE;
   }
   ```

   

5. 添加`proc_size()`和`freememory()`的函数声明在defs.h

   ```c
   uint64          freememory(void);
   ```

   ```c
   int             proc_size(void);
   ```

6. 在kenner/sysproc.c中实现`sys_sysinfo`系统调用

   ```c
   uint64
   sys_sysinfo(void)
   {
     struct sysinfo info;
     uint64 addr;
     // 获取用户态传入的sysinfo结构体
     if (argaddr(0, &addr) < 0) 
       return -1;
     struct proc* p = myproc();
     info.freemem = freememory();
     info.nproc = proc_size();
     // 将内核态中的info复制到用户态
     if (copyout(p->pagetable, addr, (char*)&info, sizeof(info)) < 0)
       return -1;
     return 0;
   }
   ```

### 2.3 实验结果

成功通过sysinfotest测试

![](https://thumbnail0.baidupcs.com/thumbnail/4cf0c2390q97e2d3385ad387a23dd658?fid=1099950169229-250528-412035925892075&rt=pr&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-WIK%2ffktYydXKyVgbFpchWTmZ9R4%3d&expires=8h&chkbd=0&chkv=0&dp-logid=247153641883595596&dp-callid=0&time=1659063600&size=c1999_u1999&quality=100&vuk=1099950169229&ft=image)

## 3. 实验中遇到的问题&心得

1. 由于对总体布局还不太熟悉，在一些头文件中没加函数声明造成编译错误。例如没有加在syscall.c的syscalls函数数组中中加系统调用的函数声明等等。
2. 实现`sys_sysinfo()`过程中，函数`copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)`的使用。本质上就是将内核地址src开始的len大小的数据拷贝到用户进程pagetable的虚地址dstva处。所以sysinfo实现里先用argaddr读进来我们要保存的在用户态的数据sysinfo的指针地址，然后再把从内核里得到的sysinfo开始的内容以sizeof(sysinfo)大小的的数据复制到这个指针上，其实就是同一个数据结构，所以这样直接复制过去就可以了。

3. 简单了解系统调用的过程。以sysinfotest为例子，大概的过程就是
   1. user/sysinfotest.c调用sinfo函数 
   2. sinfo函数调用sysinfo系统调用
   3.  markfile调用usys.pl代码通过汇编进入内核 
   4. 执行内核中的sysproc.c程序中的`sys_sysinfo()`函数

## 4. 实验测试结果

![](https://thumbnail1.baidupcs.com/thumbnail/47164da19k390d3ac7538ad7d7c065df?fid=1099950169229-250528-566478657359361&rt=pr&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-FdoKadmWkDsSqLInuiG6gWdbOUQ%3d&expires=8h&chkbd=0&chkv=0&dp-logid=247744495675599837&dp-callid=0&time=1659067200&size=c1536_u864&quality=90&vuk=1099950169229&ft=image&autopolicy=1)

