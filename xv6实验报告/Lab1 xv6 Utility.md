# Lab：xv6 Utility

[toc]

实验目的：了解熟悉xv6和系统调用命令

## 1.Sleep

### 1.1 实验要求

为xv6实现UNIX程序sleep；sleep应该暂停一段用户指定的时间间隔。

### 1.2 实验步骤

1. 编写sleep.c程序

   ```c
   #include "../kernel/types.h"
   #include "../kernel/stat.h"
   #include "user.h"
   
   int main(int argc, char *argv[])
   
   {
   
    int time = atoi(argv[1]);
   
    sleep(time);
   
    exit(0);
   
   }
   ```

   

2. 在Makefile文件中加入加入`$U/_sleep\`

   ![image](https://thumbnail0.baidupcs.com/thumbnail/076c86481qf710f08d2f6bfc0c94c3ca?fid=1099950169229-250528-605868546546909&time=1658224800&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-VLyRpNq8AJUMjIB9F4u3JWikW64%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=21172851106178899&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

3. 编译程序,在控制台中键入命令

   `gcc -g -o sleep sleep.c`

4. 启动qemu并执行命令

   ![](https://thumbnail0.baidupcs.com/thumbnail/cc98310acr460953abdc792091037d98?fid=1099950169229-250528-28863825370692&time=1658224800&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-%2B7%2BoqkvfZExabCGcLhu%2FxTmooak%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=21208166304362707&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

## 2.Pingpong

### 2.1 实验要求

编写一个程序，它使用UNIX系统调用在两个进程之间通过一对管道“ping-pong”一个字节，每个方向一个。父进程通过向父进程parent_fd[1]写入一个字节来发送，子进程通过从父进程parent_fd[0]读取来接收。在从父进程接收到一个字节后，子进程用自己的字节响应，向child_fd[1]写入数据，然后由父进程读取。

### 2.2 实验步骤

1. 编写pingpong.c程序

   ```c
   #include "../kernel/types.h"
   #include "../kernel/stat.h"
   #include "user.h"
   
   int main(int argc, char *argv[]) {
     int p1[2], p2[2];
     char buffer[] = {'l'};
     int len = sizeof(buffer);
     pipe(p1);
     pipe(p2);
     if (fork() == 0) {//子进程
       close(p1[1]);//关闭管道1的写
       close(p2[0]);//关闭管道2的读
       if (read(p1[0], buffer, len) != len) {
         //从管道1中读数据
         printf("child read error!\n");
         exit(1);
       }
       printf("%d: received ping\n", getpid());
       if (write(p2[1], buffer, len) != len) {
         //往管道2中写数据
         printf("child write error\n");
         exit(1);
       }
       close(p1[0]);
       close(p2[1]);
       exit(0);
     } else {//父进程
       close(p1[0]);//关闭管道1的读
       close(p2[1]);//关闭管道2的写
       if (write(p1[1], buffer, len) != len) {
         //往管道1中写数据
         printf("parent write error!\n");
         exit(1);
       }
       if (read(p2[0], buffer, len) != len) {
         //从管道2中读数据
         printf("parent read error!\n");
         exit(1);
       }
       printf("%d: received pong\n");
       close(p1[1]);
       close(p2[0]);
       exit(0);
     }
     exit(0);
   }
   ```

   

2. 在Makefile文件中加入加入`$U/_pingpong\`

   ![](https://thumbnail0.baidupcs.com/thumbnail/5685164b3s1848b1f376d9195399e519?fid=1099950169229-250528-611677544858773&time=1658286000&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-zxa0q6IAHbO7jkpwXKV%2BD3g2O5Y%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=38462578363220443&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

3. 编译程序,在控制台中键入命令

   `gcc -g -o pingpong pingpong.c`

4. 启动qemu并执行命令

![](https://thumbnail0.baidupcs.com/thumbnail/973ca5f67l36e76f24d7484a32fb992b?fid=1099950169229-250528-136333564336236&time=1658224800&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-7sImgIAmsOMfb%2FNoF2AmhyLeWws%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=21309318086712024&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

进程（pid=12216）创建子进程（pid=4），子进程接受管道1数据，控制台输出ping；父进程接受管道2数据，控制台输出pong

## 3.Primes

### 3.1 实验要求

使用管道编写prime-siever的并发版本。任务是输出[2-35]区间内的素数。

### 3.2 实现思想

只要还没获取到所有的素数，便不断遍历/递归。每次递归时按下以下规则

1. 先在父进程中创建一个子进程。 
2.  利用子进程将剩下的所有数全都写到管道中。
3. 在父进程中，将数不断读出来，管道中第一个数一定是素数，然后删除它的倍数（如果不是它的倍数，就继续更新数组，同时记录数组中目前已有的数字数量）。

### 3.3 实验步骤

1. 编写primes.c程序,核心函数printiPrime( )如下

   ```c
   void printPrime(int *input, int count)
   {
     if (count == 0) {
       return;
     }
     int p[2], i = 0, prime = *input;
     pipe(p);
     char buff[4];
   
     //父进程打印素数，input数组中第一个一定是素数
     printf("prime %d\n", prime);
   
     if (fork() == 0) {
       close(p[0]);
       //子进程将剩下的数写进管道
       for (; i < count; i++) {
         write(p[1], (char *)(input + i), 4);
       }
       close(p[1]);
       exit(0);
     } else {
       close(p[1]);
       count = 0;
       while (read(p[0], buff, 4) != 0) {
         //遍历管道中的数
         int temp = *((int *)buff);
         if (temp % prime) {
           //删除该素数的倍数
           *input++ = temp;
           count++;
         }
       }
       printPrime(input - count, count);
       close(p[0]);
       wait(0);
     }
   }
   ```

   

2. 在Makefile文件中加入加入`$U/_primes\`

3. 编译程序,在控制台中键入命令

   `gcc -g -o primes primes.c`

4. 启动qemu，并执行命令

   ![](https://thumbnail0.baidupcs.com/thumbnail/d9a41dc60t4868b4263a10e48d628d43?fid=1099950169229-250528-329293738479218&time=1658286000&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-yaOeX5nUBV3Nnx85K0WbdtgrhAQ%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=38453180225239151&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

## 4. Find

### 4.1 实验要求

编写一个简单版本的Unix find程序：查找目录树中名称与字符串匹配的所有文件

### 4.2 实现思想

1. 根据hint查看`user/ls.c`是如何查找文件的
2. 递归实现文件查找，深度优先检索要查找的文件
3. stat结构体存放文件信息，dirent结构体存放目录信息
4. 使用`open()`打开当前fd，用`fstat()`判断fd的type，如果是文件，则与要找的文件名进行匹配；如果是目录，则循环read()到dirent结构，得到其子文件/目录名，拼接得到当前路径后进入递归调用。注意对于子目录中的`.`和`..`不要进行递归。
4. de.inum==0 代表当前文件夹 没有目录项，也就是文件夹里头没有任何文件

### 4.3 实验步骤

1. 编写find.c程序

   ```c
   #include "../kernel/types.h"
   #include "../kernel/fcntl.h"
   #include "../kernel/stat.h"
   #include "user.h"
   #include "../kernel/fs.h"
   
   char* des = 0;//要查找文件名字符串的指针
   void find(const char* path)
   {
       //buf中存放的是绝对路径
       //p是路径的尾指针
   	char buf[512],*p;
   	strcpy(buf,path);
   	p = buf + strlen(path);
   	*p++ = '/';//给buf路径加上‘/’
   
   	int fd;//文件描述符
   	struct stat st;//存放文件的信息
   	if (0 > (fd = open(path,O_RDONLY)))
   	{
           //输入了不存在的路径
   		printf("cannot open %s\n",path);
   		return;
   	}
   	if (0 > fstat(fd,&st))
   	{
   		printf("cannot fstat %s\n",path);
   		return;
   	}
   
   	struct dirent dir;//存放目录的信息
   	int len = sizeof(dir);
   	while (read(fd,&dir,len) == len)//一次获取一个目录或则文件
   	{
   		if (0 == dir.inum)
   			continue;
   		strcpy(p,dir.name);
   		if (stat(buf,&st) < 0)
   		{
   			printf("cannot stat %s\n",buf);
   			continue;
   		}
   		switch(st.type)
   		{
   			case T_FILE://如果buf是文件
   				if (!strcmp(dir.name,des))
   					printf("%s\n",buf);
   				break;
   
   			case T_DIR://如果buf是目录，则进入到buf下进一步寻找
   				if (strcmp(".",dir.name) && strcmp("..",dir.name))
   					find(buf);
   				break;
   
   			default:
   				break;
   		}
   	}
   	close(fd);
   }
   
   int main(int argc,const char* argv[])
   {
   	if (argc < 3)
   	{
   		printf("Usage: find <dir> <file> ...\n");
   		exit(1);
   	}
   	des = (char*)argv[2];
   	find(argv[1]);
   	exit(0);
   }
   
   
   ```

   

2. 在Makefile文件中加入加入`$U/_find\`

3. 编译程序,在控制台中键入命令

   `gcc -g -o find find.c`

4. 启动qemu，并执行命令

   ![](https://thumbnail0.baidupcs.com/thumbnail/09982c22aj8d921cee282e7e650e4776?fid=1099950169229-250528-333364840758143&time=1658286000&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-3EENDGbwJIjLSh78QLZWtknoOVw%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=38443843480944520&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

   

## 5. Xargs

### 5.1 实验要求

写一个xargs的普通版本，从标准输入中获取行数，并为每一行运行一个命令和提供参数。

### 5.2 实现思路

xargs的功能是将标准输入转为程序的命令行参数。可配合管道使用，让原本无法接收标准输入的命令可以使用标准输入作为参数。

1. 根据lab中的使用例子可以看出，xv6的xargs每次回车都会执行一次命令并输出结果，直到ctrl+d时结束；而linux中的实现则是一直接收输入，收到ctrl+d时才执行命令并输出结果。

2. 对每一行输入`fork()`出子进程，调用`exec()`执行命令。注意exec接收的二维参数数组argv，第一个参数argv[0]必须是该命令本身，最后一个参数argv[size-1]必须为0，否则将执行失败
3. 在处理输入时使用block和buf两个缓冲区配合保证lineslipt数组的正确性

### 5.3 实验步骤

1. 编写xargs.c程序

   ```c
   #include "../kernel/types.h"
   #include "user.h"
   #include "../kernel/param.h"
   
   int main(int argc, char *argv[])
    {
       char block[32], buf[32];
       int n = 0, k, m = 0;//n是lineSplit的index，k是block的index，m是buf的index
       char* lineSplit[MAXARG], *p;//linesplit存放每一行的信息，p是buf的内部指针
       p = buf;
   
       for (int i = 1; i < argc; i++) {
           lineSplit[n++] = argv[i];
       }
   
       //从标准输入中读取数据放到block
       while ((k = read(0, block, sizeof(block))) > 0) {
           //遍历block中的每一项
           for (int i = 0; i < k; i++) {
           if (block[i] == '\n') {
               //block读到尽头时，执行子进程，并重置一些参数
               buf[m] = 0;
               lineSplit[n++] = p;
               lineSplit[n] = 0;
               m = 0;
               p = buf;
               n = argc - 1;
               if (fork() == 0) {
               exec(argv[1], lineSplit);
               }
               wait(0);
           } else if (block[i] == ' ') {
               buf[m++] = 0;
               lineSplit[n++] = p;
               p = &buf[m];
           } else {
               buf[m++] = block[i];
           }
           }
       }
       exit(0);
   }
   ```

   

2. 在Makefile文件中加入加入`$U/_xagrs\`

3. 编译程序,在控制台中键入命令

   `gcc -g -o xagrs xargs.c`

4. 启动qemu，并执行命令

![](https://thumbnail0.baidupcs.com/thumbnail/c24797907m51412fc7e4845c743453f7?fid=1099950169229-250528-639893258409324&time=1658289600&rt=sh&sign=FDTAER-DCb740ccc5511e5e8fedcff06b081203-gXR3L18OjBHc0eCqdJC70Rsb5eI%3D&expires=8h&chkv=0&chkbd=0&chkpc=&dp-logid=38503983025748439&dp-callid=0&file_type=0&size=c710_u400&quality=100&vuk=-&ft=video)

## 6 实验中遇到的问题

1. 在pingpong实验中，理解父进程和子进程的通过管道进行通讯的方式。以及父进程与子进程之间通讯无需sleep()，问题参考博客[pipe和fork浅析_qq_43812167的博客-CSDN博客](https://blog.csdn.net/qq_43812167/article/details/113483030)。如果CPU切换到子进程执行到read的时候发现管道里面没有数据就会阻塞，等到CPU切换到父进程，然后向管道里面写数据后，CPU切换回子进程read就返回了。
2. 在primes实验中，难以构思出通过`fork()`和`pipe()`计算出素数的算法，参考了埃拉托斯特尼素数筛选算法：**要得到自然数n以内的全部素数，必须把不大于根号n的所有素数的倍数剔除，剩下的就是素数**。然后通过父进程筛选删除素数的倍数，子进程将剩下的数塞进管道中解决。
3. 在find实验中，字符串的匹配方式一时间没想起来可以使用`strcmp()`比较来匹配。还有在进入递归时防止进入到`.`和`..`目录中。
4. 在xargs实验中，理解xargs命令的作用，以及输入处理的方式，使用缓冲区来处理。配合管道使用，管道将上一条命令的输出作为下一条命令的输入，xargs命令将输入进行处理，确保下一条命令的输入正确性。

## 7 实验心得

本次实验时第一次实验，在安装虚拟机和配置环境中都遇到了不少的卡顿和困扰。然后也第一次接触了linux的命令，勉勉强强能够会用一些系统提供的接口来进行编程。熟悉一下xv6的环境和操作，自己在遇到问题时也能在博客和论坛上找到解答。
