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