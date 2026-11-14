#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void copy(FILE*out,const char*p){FILE*f=fopen(p,"rb");int c;if(!f)exit(2);while((c=fgetc(f))!=EOF)fputc(c,out);fclose(f);}
static void function(FILE*out,char*s,const char*name,const char*type){char start[128],end[128],*a,*b;snprintf(start,sizeof start,"%s\tproc\t%s",name,type);snprintf(end,sizeof end,"%s\tendp",name);a=strstr(s,start);b=a?strstr(a,end):NULL;if(!a||!b)exit(3);b+=strlen(end);fwrite(a,1,b-a,out);fputc('\n',out);}
int main(int argc,char**argv){FILE*f,*out;long n;char*s;if(argc!=5)return 1;f=fopen(argv[1],"rb");if(!f)return 2;fseek(f,0,SEEK_END);n=ftell(f);rewind(f);s=malloc(n+1);if(!s||fread(s,1,n,f)!=(size_t)n)return 2;fclose(f);s[n]=0;out=fopen(argv[4],"wb");if(!out)return 2;copy(out,argv[2]);function(out,s,"RegReadFile","far");function(out,s,"RegValidateHeader","near");function(out,s,"RegValidateKeyBlock","far");function(out,s,"RegChecksum","near");copy(out,argv[3]);return fclose(out)!=0;}
