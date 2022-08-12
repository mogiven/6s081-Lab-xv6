# Lab: Copy-on-Write Fork for xv6

[toc]

## 1. 实验要求

在原始的XV6中，fork函数是通过直接对进程的地址空间完整地复制一份来实现的。但是在某些情况下会造成资源的浪费：

1. fork在创建子进程后，会调用`exec()`导致fork做了很多无效功
2. 父进程和子进程的代码段可以可读共享，但是在fork的时候直接将父进程和子进程的页表和内存地址中的内容都进行复制，造成内存空间的浪费。

hint：

1. 修改fork，在生成子进程时不拷贝父进程内存，而是直接将复制父进程的页表内容到子进程的页表，同时把页表项设置为不可写入且为COW页表（在riscv.h中宏定义PTE_COW）；
2. 在子进程或者父进程写入内存时产生pagefault，此时检查pte项是否有PTE_COW标记，若有标记则分配内存，将COW页表内存拷贝到新分配的内存，并替换页表项，修改物理内存位置以及标记位为可写非COW页；
3. 修改copyout，内容和2相似
4. 考虑何时释放内存页，我们需要一个数组，记录每个页被引用次数page_ref，引用为1时若被kfree则执行释放操作，否则kfree时只page_ref–;同时kalloc时必定是内存第一次被分配，page_ref直接设为1。

## 2. 实验步骤

1. 在risc-v.c文件中添加宏定义

   `#define PTE_COW (1L << 9)`

2. `fork`函数会调用`uvmcopy`进行拷贝，因此只需要修改`uvmcopy`函数就可以了：删去`uvmcopy`中的`kalloc`函数，将父子进程页面的页表项都设置为不可写，并设置COW标志位

   ```c
   	*pte = *pte & (~PTE_W);  //修改为不可写入
       *pte = *pte | PTE_COW;     //标记为cow页
       pa = PTE2PA(*pte);
       flags = PTE_FLAGS(*pte);
   
       // if((mem = kalloc()) == 0)
       //   goto err;
       // memmove(mem, (char*)pa, PGSIZE);
       if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
         goto err;
       }
       ++ page_ref[(uint64)pa/PGSIZE];//维护引用次数
   ```

   

3. 定义全局变量记录页表的引用次数

   ~~~c
   int page_ref[PHYSTOP/PGSIZE];
   ~~~

4. 在`kalloc.c/kinit()`中初始化page_ref

5. 当页面引用次数超过1次时，不用释放该页面的物理内存

   ```c
   if( --page_ref[(uint64)pa/PGSIZE] > 0 )//加这句判断就行
       return;
   ...
   ```

6. 修该kalloc()，分配页表时要修改引用次数

7. 在`usertrap()`中处理缺页中断

   ~~~c
   else if( r_scause() == 15 ){
     	uint64 va = r_stval();
       pte_t *pte = walk( p->pagetable, va, 0);
       if(*pte & PTE_C){
         
         char* mem;
         uint64 flags, pa;
         pa = PTE2PA(*pte);
   
         if((mem = kalloc()) == 0){
           // printf("no mem remain on COW\n");
           p->killed = 1;
           exit(-1);
         }
   
         memmove(mem, (char*)pa, PGSIZE);
         flags = (PTE_FLAGS(*pte) | PTE_W) & (~PTE_C);
         uvmunmap(p->pagetable, PGROUNDDOWN(va), 1, 1);
   
         if(mappages(p->pagetable, PGROUNDDOWN(va), PGSIZE, (uint64)mem, flags) != 0){
           kfree(mem);
           p->killed = 1;
           exit(-1);
         }
   
       }else{
         p->killed = 1;
         exit(-1);
       }
     }
   ~~~

8. 修改vm.c/copyout()

   ```c
   	pte = walk(pagetable, va0, 0);
       if(*pte & PTE_C){
         if((mem = kalloc())==0){
           return -1;
         }
   
         memmove(mem, (char*)pa0, PGSIZE); 
         flags = ( PTE_FLAGS(*pte) | PTE_W ) & (~PTE_C);
         uvmunmap(pagetable, va0, 1, 1);
   
         if(mappages(pagetable, va0, PGSIZE, (uint64)mem, flags) != 0){
           kfree(mem);
           return -1;
         }
         pa
   ```

## 3. 测试结果

1. make grade

```shell
== Test running cowtest == 
$ make qemu-gdb
(9.2s) 
== Test   simple == 
  simple: OK 
== Test   three == 
  three: OK 
== Test   file == 
  file: OK 
== Test usertests == 
$ make qemu-gdb
(171.6s) 
    (Old xv6.out.usertests failure log removed)
== Test   usertests: copyin == 
  usertests: copyin: OK 
== Test   usertests: copyout == 
  usertests: copyout: OK 
== Test   usertests: all tests == 
  usertests: all tests: OK 
== Test time == 
time: OK 
Score: 110/110
```

