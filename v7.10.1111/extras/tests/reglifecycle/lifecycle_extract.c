#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void copy(FILE *o,const char *path){FILE*f=fopen(path,"rb");int c;if(!f)exit(2);while((c=fgetc(f))!=EOF)fputc(c,o);fclose(f);}
static void part(FILE *o,const char*s,const char*name){char a[100],b[100];const char*p,*q;snprintf(a,sizeof a,"%s\tproc\tfar",name);snprintf(b,sizeof b,"%s\tendp",name);p=strstr(s,a);q=p?strstr(p,b):NULL;if(!q)exit(3);q+=strlen(b);fwrite(p,1,q-p,o);fputc('\n',o);}
int main(int argc,char**argv){FILE*f,*o;long n;char*s;if(argc!=5||!(f=fopen(argv[1],"rb")))return 1;fseek(f,0,SEEK_END);n=ftell(f);rewind(f);s=malloc(n+1);if(!s||fread(s,1,n,f)!=(size_t)n)return 2;fclose(f);s[n]=0;o=fopen(argv[4],"wb");if(!o)return 2;copy(o,argv[2]);part(o,s,"RegInitialize");part(o,s,"RegTerminate");copy(o,argv[3]);return fclose(o)!=0;}
