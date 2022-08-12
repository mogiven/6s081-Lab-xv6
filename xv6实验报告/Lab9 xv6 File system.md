# Lab xv6 File system

[toc]

## 1. Large files

### 1.1 实验内容和思路

修改 `bmap()`使其除了直接块和单间接块之外，还实现了双间接块。你只需要有11个直接块，而不是12个，才能为你新的双间接块腾出空间;不允许更改磁盘 inode 的大小。`ip->addrs[]`的前11个元素应该是直接块;第12个应该是一个单间接块（就像现在的块一样）;第13个应该是你新的双重间接块。

实现思路：
我们需要增加xv6文件的最大大小。目前xv6文件被限制为268个块，也就是268BSIZE字节（在xv6中BSIZE是1024）。这个限制来自于这样一个限定：一个xv6索引节点包含12个直接索引和一个一级间接索引（最多可容纳256个块号的块），总共有12+256=268个块。我们需要更改xv6文件系统代码，以支持每个inode中的二级间接索引，其中包含256个一级间接索引块的地址，每个块最多可以包含256个数据块地址。结果是，一个文件最多可以包含256256+256+11个块（11个而不是12个，因为我们将为二级间接索引块牺牲一个直接索引块号）。

### 1.2 实验步骤

1. 在fs.h中修改宏定义和dinode结构体定义

   ```c
   #define NDIRECT 11
   #define NINDIRECT (BSIZE / sizeof(uint))
   #define MAXFILE (NDIRECT + NINDIRECT + NINDIRECT * NINDIRECT)
   
   struct dinode {
     ...
     uint addrs[NDIRECT+2];   // Data block addresses
   };
   ```

2. 在file.h中修改inode结构体的定义

   ```c
   struct inode {
     ...
     uint addrs[NDIRECT+2];
   };
   
   ```

3. 修改fs.c中的`bmap()`函数.bn确定文件具体位置，然后先去找中间层的间接索引，读出来地址后，再去找第二层间接索引，写下刚读到的索引地址。然后根据这个索引再去找数据块写下数据。

4. 

   ```c
   static uint
   bmap(struct inode *ip, uint bn)
   {
     uint addr, *a;
     struct buf *bp;
   
     if(bn < NDIRECT){
       if((addr = ip->addrs[bn]) == 0)
         ip->addrs[bn] = addr = balloc(ip->dev);
       return addr;
     }
     bn -= NDIRECT;
   
     if(bn < NINDIRECT){
       // Load indirect block, allocating if necessary.
       if((addr = ip->addrs[NDIRECT]) == 0)
         ip->addrs[NDIRECT] = addr = balloc(ip->dev);
       bp = bread(ip->dev, addr);
       a = (uint*)bp->data;
       if((addr = a[bn]) == 0){
         a[bn] = addr = balloc(ip->dev);
         log_write(bp);
       }
       brelse(bp);
       return addr;
     }
     
     bn -= NINDIRECT;
   
      if(bn < NINDIRECT * NINDIRECT){
       // double indirect
       int idx = bn / NINDIRECT;
       int off = bn % NINDIRECT;
       if((addr = ip->addrs[NDIRECT + 1]) == 0)
         ip->addrs[NDIRECT + 1] = addr = balloc(ip->dev);
       bp = bread(ip->dev, addr);
       a = (uint*)bp->data;
       if((addr = a[idx]) == 0){
         a[idx] = addr = balloc(ip->dev);
         log_write(bp);
       }
       brelse(bp);
   
       bp = bread(ip->dev, addr);
       a = (uint*)bp->data;
       if((addr = a[off]) == 0){
         a[off] = addr = balloc(ip->dev);
         log_write(bp);
       }
       brelse(bp);
       return addr;
     }
   
     panic("bmap: out of range");
   }
   ```

   

## 2. Symbolic links

### 2.1 实验内容及思路

您将实现 symlink(char *target, char *path) 系统调用，它会在 path 处创建一个新的符号链接，该链接引用由 target 命名的文件。 有关详细信息，请参阅手册页符号链接。 要进行测试，请将 symlinktest 添加到 Makefile 并运行它。 当测试产生以下输出（包括 usertests 成功）时，您的解决方案就完成了。

符号链接就是在文件中保存指向文件的路径名，在打开文件的时候根据保存的路径名再去查找实际文件。与符号链接相反的就是硬链接，硬链接是将文件的`inode`号指向目标文件的`inode`，并将引用计数加一。

### 2.2 实验步骤

1. 修改Makefile文件，添加`$U_symlinktest`

2. 在user/usys.pl和user/user.h中添加声明

   `int symlink(char* ,char*)`

   `entry("symlink")`

3. 在kernel/stat.h中添加一个软连接的文件类型`#define T_SYMLINK 4`

4. 在kernel/fcntl.h中添加新的宏`#$define O_NOFOLLOW 0x800`

5. 在syscall.c中添加symlink指令

6. 在syscall.h中添加相应的系统调用编号`#define SYS_symlink`

7. 创建一个`inode`，设置类型为`T_SYMLINK`，然后向这个`inode`中写入目标文件的路径就行了。编写sys_symlink系统调用函数,

   ```c
   uint64
   sys_symlink(void)
   {
     char target[MAXPATH];
     memset(target, 0, sizeof(target));
     char path[MAXPATH];
     if(argstr(0, target, MAXPATH) < 0 || argstr(1, path, MAXPATH) < 0){
       return -1;
     }
     
     struct inode *ip;
   
     begin_op();
     if((ip = create(path, T_SYMLINK, 0, 0)) == 0){
       end_op();
       return -1;
     }
   
     if(writei(ip, 0, (uint64)target, 0, MAXPATH) != MAXPATH){
       // panic("symlink write failed");
       return -1;
     }
   
     iunlockput(ip);
     end_op();
     return 0;
   }
   ```

8. 在`sys_open`中添加对符号链接的处理，当模式不是`O_NOFOLLOW`的时候就对符号链接进行循环处理，直到找到真正的文件，如果循环超过了一定的次数（10），就说明可能发生了循环链接，就返回-1。这里主要就是要注意`namei`函数不会对`ip`上锁，需要使用`ilock`来上锁，而`create`则会上锁。

   ```c
   if(ip->type == T_SYMLINK){
       if(!(omode & O_NOFOLLOW)){
         int cycle = 0;
         char target[MAXPATH];
         while(ip->type == T_SYMLINK){
           if(cycle == 10){
             iunlockput(ip);
             end_op();
             return -1; // max cycle
           }
           cycle++;
           memset(target, 0, sizeof(target));
           readi(ip, 0, (uint64)target, 0, MAXPATH);
           iunlockput(ip);
           if((ip = namei(target)) == 0){
             end_op();
             return -1; // target not exist
           }
           ilock(ip);
         }
       }
     }
   ```

   

## 3. 测试

```shell
== Test running bigfile == 
$ make qemu-gdb
running bigfile: OK (129.4s) 
== Test running symlinktest == 
$ make qemu-gdb
(0.7s) 
== Test   symlinktest: symlinks == 
  symlinktest: symlinks: OK 
== Test   symlinktest: concurrent symlinks == 
  symlinktest: concurrent symlinks: OK 
== Test usertests == 
$ make qemu-gdb
usertests: OK (196.4s) 
== Test time == 
time: OK 
Score: 100/100
```

