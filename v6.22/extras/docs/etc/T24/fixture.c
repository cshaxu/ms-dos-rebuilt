#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdlib.h>
int main(int argc,char**argv){if(argc!=3)return 2;Sleep((DWORD)strtoul(argv[1],0,10));return atoi(argv[2]);}
