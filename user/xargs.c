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