#include "../kernel/types.h"
#include "../kernel/stat.h"
#include "user.h"
int main(int argc, char *argv[])
{
  int time = atoi(argv[1]);
  sleep(time);
  exit(0);
}
