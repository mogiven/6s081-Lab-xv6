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

