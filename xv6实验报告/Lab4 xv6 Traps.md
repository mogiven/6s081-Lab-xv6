# Lab ：xv6 Traps

## 0. Content

[toc]

## 1. RISC-V assembly

### 1.1 实验目的

了解一些RISC-V程序集非常重要，这在6.004中已经介绍过。 xv6存储库中有一个文件user / call.c。 make fs.img对其进行编译，并在user / call.asm中生成该程序的可读汇编版本。阅读call.asm中有关g，f和main函数的代码。 RISC-V的说明手册在参考页上。 以下是您应回答的一些问题（将回答存储在文件Answers-traps.txt中）：

### 1.2 相关问题回答

1. Which registers contain arguments to functions? For example, which register holds 13 in main's call to `printf`?（哪些寄存器包含函数的参数？ 例如，哪个寄存器在main对printf的调用中保留13？）

   *a0 a1 a2 a3... a3保留13*

2. 在main的汇编代码中对函数f的调用在哪里？对函数g的调用在哪里？ （提示：编译器可以内联函数。）

   *ra=pc=0x30 0x30+1536(0x60)=0x630*

3. 函数printf位于哪个地址？

   *ra=pc=0x30 0x30+1536(0x60)=0x630*

   *（ra）+1536*

   ```tex
   jalr 1536(ra) # 630 <printf>
   ```

4. 紧随main的printf之后，寄存器ra中的值是什么？

   *ra是printf返回到main的地址 0x38*

5. 运行以下代码。

   ```c
   unsigned int i = 0x00646c72;
   printf("H%x Wo%s", 57616, &i);
   ```

   输出是什么？ 这是一个将字节映射为字符的ASCII表。输出取决于RISC-V是小端的事实。 如果RISC-V改为big-endian，那么您将i设置为什么才能产生相同的输出？ 您是否需要将57616更改为其他值？

   ```tex
   16进制 72 6c 64
   
   ascii码 r l d
   
   %x 是16进制 57616=0xe110
   
   输出 He110 World
   
   改为大端模式
   
   i=0x726c64
   
   不需要修改57616 因为不论大端还是小端，它16进制的表达方式不变
   
   读字符串是地址从小到大递增的
   ```

6. 在以下代码中，'y ='之后将输出什么？ （注意：答案不是一个特定的值。）为什么会发生？

   *取决于对应输入寄存器的值*

## 2. Backtrace

### 2.1 实验要求

在kernel / printf.c中实现backtrace（）函数。 在sys_sleep中插入对此函数的调用，然后运行bttest，该调用sys_sleep。 您的输出应如下所示：

```tex
backtrace:
0x0000000080002cda
0x0000000080002bb6
0x0000000080002898
```

之后退出qemu。 在您的终端中：地址可能略有不同，但是如果您运行addr2line -e内核/内核（或riscv64-unknown-elf-addr2line -e内核/内核）并按如下所示剪切并粘贴上述地址：

```tex
    $ addr2line -e kernel/kernel
    0x0000000080002de2
    0x0000000080002f4a
    0x0000000080002bfc
    Ctrl-D
```

您应该看到类似以下内容：

```shell
    kernel/sysproc.c:74
    kernel/syscall.c:224
    kernel/trap.c:85
```

编译器在每个堆栈帧中放置一个帧指针，该指针保存调用方的帧指针的地址。 回溯应该使用这些帧指针在堆栈上移动并在每个堆栈帧中打印保存的返回地址。

hints：

将用于backtrace的原型添加到kernel / defs.h，以便您可以在sys_sleep中调用backtrace。

GCC编译器将当前执行函数的帧指针存储在寄存器s0中。 将以下函数添加到kernel / riscv.h：

```text
static inline uint64
r_fp()
{
  uint64 x;
  asm volatile("mv %0, s0" : "=r" (x) );
  return x;
}
```

并在backtrace中调用此函数以读取当前帧指针。 此函数使用内联汇编读取s0。

这些讲义中有堆栈框架布局的图片。 请注意，返回地址位于距堆栈帧的帧指针固定偏移（-8）的位置，并且已保存的帧指针位于距帧指针固定偏移（-16）的位置。

Xv6在xv6内核中的PAGE对齐地址处为每个堆栈分配一页。 您可以使用PGROUNDDOWN（fp）和PGROUNDUP（fp）来计算堆栈页面的顶部和底部地址（请参阅kernel / riscv.h。这些数字有助于回溯以终止其循环。

一旦回溯工作正常，请从kernel / printf.c中的panic调用它，以便在内核崩溃时看到内核的backtrace。

### 2.2 实验步骤

#### 2.2.1 添加声明

1. 在kernel/defs.h添加定义

   ```c
   // printf.c
   void            printf(char*, ...);
   void            panic(char*) __attribute__((noreturn));
   void            printfinit(void);
   void            backtrace();
   ```

   

2. 修改kernel/riscv.h中增加r_fp()的实现，用来读取寄存器s0sc1t

   ```c
   //读s0(frame pointer)的值
   static inline uint64
   r_fp()
   {
     uint64 x;
     asm volatile("mv %0, s0" : "=r" (x) );
     return x;
   }
   ```

   

3. kernel/sysproc.c的sys_sleep()函数中调用backtrace()

   ```c
   uint64
   sys_sleep(void)
   {
     ...
     release(&tickslock);
     backtrace();
     return 0;
   }
   ```

   

#### 2.2.2 函数实现

```c
void 
backtrace(void)
{
   uint64* fp = (uint64*)r_fp();
   uint64 up = PGROUNDUP((uint64)fp);
   uint64 *ra;
   printf("backtrace:\n");
   while((uint64)fp!=up){
    fp=(uint64*)((uint64)fp-16);
    ra=(uint64*)((uint64)fp+8);
    printf("%p\n",*ra);
    fp=(uint64*)*fp;
   }
}
```



## 3. Alarm

### 3.1 实验要求

在本练习中，您将向xv6添加一项功能，该功能会在使用CPU时间的情况下定期向进程发出警报。 这对于想要限制消耗多少CPU时间的计算密集型进程，或者对于想要进行计算但还希望采取一些定期操作的进程很有用。 更一般而言，您将实现用户级中断/故障处理程序的原始形式。 例如，您可以使用类似的方法来处理应用程序中的页面错误。 您的解决方案是否通过Alarmtest和UserTests是正确的。

您应该添加一个新的sigalarm（interval，handler）系统调用。 如果应用程序调用sigalarm（n，fn），则在程序每消耗n个“ tick” CPU时间之后，内核应导致调用应用程序函数fn。 当fn返回时，应用程序应从中断处恢复。 滴答是xv6中相当随意的时间单位，由硬件计时器产生中断的频率决定。 如果应用程序调用sigalarm（0，0），则内核应停止生成定期警报调用。

您将在xv6存储库中找到一个文件user / alarmtest.c。 将其添加到Makefile。 在您添加了sigalarm和sigreturn系统调用之前，它无法正确编译（请参见下文）。

alarmtest在test0中调用sigalarm（2，periodic），以要求内核每2个滴答强制一次对periodic（）的调用，然后旋转一段时间。 您可以在user / alarmtest.asm中看到alarmtest的汇编代码，这对于调试很方便。 当alarmtest产生这样的输出并且usertests也正确运行时，您的解决方案是正确的：

```text
$ alarmtest
test0 start
........alarm!
test0 passed
test1 start
...alarm!
..alarm!
...alarm!
..alarm!
...alarm!
..alarm!
...alarm!
..alarm!
...alarm!
..alarm!
test1 passed
test2 start
................alarm!
test2 passed
$ usertests
...
ALL TESTS PASSED
$
```

完成后，您的解决方案将只有几行代码，但是正确实现可能有些棘手。 我们将使用原始存储库中的alerttest.c版本测试您的代码。 您可以修改alarmtest.c以帮助调试，但请确保原始的alarmtest表示所有测试均通过。

#### 3.1.1test0: invoke handler

通过修改内核以跳转到用户空间中的警报处理程序开始，这将导致test0打印“ alarm！”。 别担心，“警报”之后会发生什么！ 输出; 如果您的程序在打印“警报！”后崩溃，现在可以。 这里有一些提示：

您需要修改Makefile才能将alarmtest.c编译为xv6用户程序。

放置在user / user.h中的正确声明是：

```c
    int sigalarm(int ticks, void (*handler)());
    int sigreturn(void);
```

更新user / usys.pl（生成用户/usys.S）、kernel/syscall.h和kernel / syscall.c，以允许alarmtest调用sigalarm和sigreturn系统调用。

现在，您的sys_sigreturn应该只返回零。

您的sys_sigalarm（）应该在proc结构（在kernel / proc.h中）的新字段中存储警报间隔和指向处理函数的指针。

您需要跟踪自上次调用（或留到下一次调用）到流程的警报处理程序以来经过了多少滴答； 您也需要为此在struct proc中添加一个新字段。 您可以在proc.c中的allocproc（）中初始化proc字段。

每次滴答，硬件时钟都会强制产生一个中断，该中断在kernel / trap.c中的usertrap（）中处理。

您只想在有计时器中断的情况下处理进程的警报滴答声； 你想要类似if（which_dev == 2）...

仅当进程的计时器溢出时才调用警报功能。 请注意，用户警报功能的地址可能为0（例如，在user / alarmtest.asm中，周期位于地址0）。

您需要修改usertrap（），以便在进程的警报间隔到期时，用户进程执行处理程序函数。 当RISC-V上的陷阱返回到用户空间时，由什么决定用户空间代码恢复执行的指令地址？如果告诉qemu仅使用一个CPU，则使用gdb查看陷阱更容易。 通过运行

```text
make CPUS=1 qemu-gdb
```

执行操作，如果alarmtest打印“ alarm！”，则表示成功。

#### 3.1.2 test1/test2(): resume interrupted code

可能是在test0或test1打印出“ alarm！”后，alarmtest崩溃，或者（最终）alarmtest打印出“ test1 failure”，或者退出了alerttest而没有打印“ test1 pass”。 要解决此问题，必须确保在完成警报处理程序后，控制返回到最初由计时器中断中断用户程序的指令。 您必须确保将寄存器的内容恢复到中断时所保存的值，以便用户程序可以在发生警报后不受干扰地继续运行。 最后，您应该在每次警报计数器关闭后对其进行“重新布防”，以便定期调用该处理程序。

首先，我们为您做出了设计决策：用户警报处理程序需要在完成后调用sigreturn系统调用。 请查看alarmtest.c中的periodic作为示例。 这意味着您可以将代码添加到usertrap和sys_sigreturn中，这些代码可以协作以使用户进程在处理警报后正常恢复。

一些提示：

您的解决方案将要求您保存和恢复寄存器---您需要保存和恢复哪些寄存器才能正确恢复中断的代码？ （提示：将会很多）。

当计时器关闭时，使usertrap在struct proc中保存足够的状态，以便sigreturn可以正确返回中断的用户代码。

防止再次进入处理程序-如果处理程序尚未返回，则内核不应再次调用它。 test2对此进行了测试。

一旦通过test0，test1和test2，就运行usertests以确保您没有破坏内核的任何其他部分。

### 3.2 实现

1. `kernel/proc.h`: 在 proc 结构体里添加需要的字段

   ```c
     int alarm_interval;     // the alarm interval (ticks)
     int alarm_passed;       // how many ticks have passed since the last call
     uint64 alarm_handler;   // pointer to the alarm handler function
     struct trapframe etpfm; // trapframe to resume
   ```

   

2. 添加 `sys_sigalarm` 系统调用：接收参数，为进程设置 alarm 的间隔时长和处理函数。最终的实现在 `kernel/sysproc.c` 

   ```c
   uint64
   sys_sigalarm(void)
   {
   	int interval;
   	uint64 handler;
   
   	if(argint(0, &interval) < 0)
   		return -1;
   
   	if(argaddr(1, &handler) < 0)
   		return -1;
   
   	struct proc *p = myproc();
   
   	p->alarm_interval = interval;
   	p->alarm_handler = handler;
   
   	return 0;
   }
   ```

   

3. 在 `usertrap` （`kernel/trap.c`）中处理时钟中断时，如果进程需要 alarm 就保存当前 trapframe 到 etpfm，调用 handler （把 handler 地址放到 trapframe->epc，回到用户空间之后就会运行该函数）

   ```c
   void
   usertrap(void)
   {
     ...
     if(which_dev == 2) {
   	// alarm
   	if (p->alarm_interval) {
   	  if (++p->alarm_passed == p->alarm_interval) {
   		memmove(&(p->etpfm), p->trapframe, sizeof(struct trapframe));
   		// return to alarm handler: call p->alarm_handler();
   		p->trapframe->epc = p->alarm_handler;
   	  }
   	}
       yield();
     }
     ...
   }
   ```

   

4. 实现 `sys_sigalarm` 系统调用，恢复 alarm 前的 trapframe（回到用户空间就会接着 alarm 之前的 PC 开始运行），把 alarm_passed 计数器置为零（允许下一次 alarm）：

   ```c
   uint64
   sys_sigreturn(void)
   {
   	struct proc *p = myproc();
   	memmove(p->trapframe, &(p->etpfm), sizeof(struct trapframe));
   	p->alarm_passed = 0;
   	return 0;
   }
   ```

## 4 结论

### 4.1 make grade

```shell
== Test answers-traps.txt == answers-traps.txt: FAIL 
    Cannot read answers-traps.txt
== Test backtrace test == 
$ make qemu-gdb
backtrace test: OK (2.8s) 
== Test running alarmtest == 
$ make qemu-gdb
(3.7s) 
== Test   alarmtest: test0 == 
  alarmtest: test0: OK 
== Test   alarmtest: test1 == 
  alarmtest: test1: OK 
== Test   alarmtest: test2 == 
  alarmtest: test2: OK 
== Test usertests == 
$ make qemu-gdb
usertests: OK (88.3s) 
== Test time == 
time: OK 
Score: 80/85
make: *** [Makefile:318: grade] Error 1
```



