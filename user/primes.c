#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"

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

int main(int argc, char *argv[]) {
  int input[34], i = 0;
  for (; i < 34; i++) {
    input[i] = i + 2;
  }
  printPrime(input, 34);
  exit(0);
}