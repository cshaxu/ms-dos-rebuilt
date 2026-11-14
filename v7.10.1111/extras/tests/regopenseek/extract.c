#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void copy(FILE*out,const char*p){FILE*f=fopen(p,"rb");int c;if(!f)exit(2);while((c=fgetc(f))!=EOF)fputc(c,out);fclose(f);}
int main(int argc,char**argv){FILE*f,*out;long n;char*s,*a,*b;if(argc!=5)return 1;f=fopen(argv[1],"rb");if(!f)return 2;fseek(f,0,SEEK_END);n=ftell(f);rewind(f);s=malloc(n+1);if(!s||fread(s,1,n,f)!=(size_t)n)return 2;fclose(f);s[n]=0;a=strstr(s,"regread_read_loc_448:");b=a?strstr(a,"regread_read_loc_46E:"):NULL;if(!a||!b)return 3;out=fopen(argv[4],"wb");if(!out)return 2;copy(out,argv[2]);fwrite(a,1,b-a,out);copy(out,argv[3]);return fclose(out)!=0;}
