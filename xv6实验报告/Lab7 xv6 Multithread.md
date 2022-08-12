# Lab7 xv6 Multithread

[toc]

# 1. Uthread: switching between threads

### 1.1 实验要求

实现一个用户级的线程，并且完成线程之间切换的功能。数据结构`context`的维护来实现上下文的切换，上下文保存在寄存器中，即`sp`和`s0-s11`，`ra`用来保存线程的返回地址，类似于进程中的`pc`。

### 1.2 实验步骤

1. 在ph.c中添加上下文结构体

   ```c
   struct thread_context{
     uint64     ra;
     uint64     sp;
     uint64     s0;
     uint64     s1;
     uint64     s2;
     uint64     s3;
     uint64     s4;
     uint64     s5;
     uint64     s6;
     uint64     s7;
     uint64     s8;
     uint64     s9;
     uint64     s10;
     uint64     s11;
   };
   ```

2. 在`thread_create`中加入初始化代码，使`ra`指向线程的入口函数，`sp`指向栈底。ra返回的是创建线程是给定的函数入口

   ```c
     memset(&t->context, 0, sizeof(t->context));
     t->context.ra = (uint64)func;
     t->context.sp= (uint64)t->stack+STACK_SIZE;
   ```

3. 在`thread_schedule()`中调用`thread_switch()`

   ~~~c
   	/* YOUR CODE HERE
        * Invoke thread_switch to switch from t to next_thread:
        * thread_switch(??, ??);
        */
        thread_switch((uint64)&t->context,(uint64)&current_thread->context);
   ~~~

4. 填写 `uthread_switch.S`汇编代码，其中a0,a1分别是函数的第一个和第二个参数，用偏移量的方式来保存

   ```SAS
   thread_switch:
   	/* YOUR CODE HERE */
   	/* save old */
   	sd ra, 0(a0)
   	sd sp, 8(a0)
   	sd s0, 16(a0)
   	sd s1, 24(a0)
   	sd s2, 32(a0)
   	sd s3, 40(a0)
   	sd s4, 48(a0)
   	sd s5, 56(a0)
   	sd s6, 64(a0)
   	sd s7, 72(a0)
   	sd s8, 80(a0)
   	sd s9, 88(a0)
   	sd s10, 96(a0)
   	sd s11, 104(a0)
   
   	/* restore new */
   	ld ra, 0(a1)
   	ld sp, 8(a1)
   	ld s0, 16(a1)
   	ld s1, 24(a1)
   	ld s2, 32(a1)
   	ld s3, 40(a1)
   	ld s4, 48(a1)
   	ld s5, 56(a1)
   	ld s6, 64(a1)
   	ld s7, 72(a1)
   	ld s8, 80(a1)
   	ld s9, 88(a1)
   	ld s10, 96(a1)
   	ld s11, 104(a1)
   
   	ret    /* return to ra */
   ```

   

## 2. Using threads

### 2.1 实验要求

联系锁的使用。因为测试程序是将put和get操作进行了分离的，因此只需要考虑put操作之间的互斥。在`put()`函数读写bucket之前加锁，在函数结束时释放锁

### 2.2 实验步骤

1. 实现ph.c

   ~~~c
   pthread_mutex_t bucket_lock[NBUCKET];//定义锁
   
   static 
   void put(int key, int value)
   {
     ...
     if(e){
       ...
     } else {
       // the new is new.
       pthread_mutex_lock(&bucket_lock[i]);
       insert(key, value, &table[i], table[i]);
       pthread_mutex_unlock(&bucket_lock[i]);
     }
   }
   
   int
   main(int argc, char *argv[])
   {
    ...
   
     // init locks
     for(int i=0; i < NBUCKET; i++){
       pthread_mutex_init(&bucket_lock[i],NULL);
     }
     
     ...
   }
   ~~~

2. 测试

   ```shell
   $ ./ph 1
   100000 puts, 6.093 seconds, 16412 puts/second
   0: 0 keys missing
   100000 gets, 5.663 seconds, 17658 gets/second
   $ ./ph 2
   100000 puts, 2.959 seconds, 33795 puts/second
   0: 0 keys missing
   1: 0 keys missing
   200000 gets, 5.826 seconds, 34330 gets/second
   ```

   

## 3. Barrier

### 3.1 实验要求

实现一个屏障点，使所有线程都到达这个点之后才能继续执行。主要就是练习POSIX的条件变量的使用。

### 3.2 实现思路

只需要实现一个`barrier`函数即可。函数实现也没有什么多说的，就是加锁然后判断到达屏障点的线程数，如果所有线程都到达了就调用`pthread_cond_broadcast`唤醒其他线程，否则就调用`pthread_cond_wait`进行等待。

### 3.3 实现

```c
  pthread_mutex_lock(&bstate.barrier_mutex);

  bstate.nthread++;

  if(bstate.nthread == nthread){
    bstate.round++;
    bstate.nthread = 0;
    pthread_cond_broadcast(&bstate.barrier_cond);
  }else{
    pthread_cond_wait(&bstate.barrier_cond, &bstate.barrier_mutex);
  }

  pthread_mutex_unlock(&bstate.barrier_mutex);
```



## 4. 测试

 ```shell
 == Test uthread == 
 $ make qemu-gdb
 uthread: OK (5.0s) 
 == Test answers-thread.txt == answers-thread.txt: OK 
 == Test ph_safe == make[1]: Entering directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 make[1]: 'ph' is up to date.
 make[1]: Leaving directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 ph_safe: OK (11.2s) 
 == Test ph_fast == make[1]: Entering directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 make[1]: 'ph' is up to date.
 make[1]: Leaving directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 ph_fast: OK (24.2s) 
 == Test barrier == make[1]: Entering directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 make[1]: 'barrier' is up to date.
 make[1]: Leaving directory '/home/ubuntu/Desktop/work/xv6-labs-2020-1'
 barrier: OK (13.2s) 
 == Test time == 
 time: OK 
 Score: 60/60
 ```

