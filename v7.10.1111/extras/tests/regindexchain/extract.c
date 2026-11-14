#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void copy(FILE*out,const char*p){FILE*f=fopen(p,"rb");int c;if(!f)exit(2);while((c=fgetc(f))!=EOF)fputc(c,out);fclose(f);}
static void function(FILE*out,const char*path,const char*name){FILE*f=fopen(path,"rb");long n;char*s,*a,*b,start[128],end[128];if(!f)exit(2);fseek(f,0,SEEK_END);n=ftell(f);rewind(f);s=malloc(n+1);if(!s||fread(s,1,n,f)!=(size_t)n)exit(2);fclose(f);s[n]=0;snprintf(start,sizeof start,"%s\tproc\tfar",name);snprintf(end,sizeof end,"%s\tendp",name);a=strstr(s,start);b=a?strstr(a,end):NULL;if(!a||!b)exit(3);b+=strlen(end);fwrite(a,1,b-a,out);fputc('\n',out);free(s);}
int main(int argc,char**argv){FILE*out;if(argc!=6)return 1;out=fopen(argv[5],"wb");if(!out)return 2;copy(out,argv[3]);function(out,argv[1],"RegIndexBlock");function(out,argv[2],"RegGetKeyRecord");function(out,argv[2],"RegFreeRecordId");function(out,argv[2],"RegFreeRecord");function(out,argv[2],"RegAssignRecordId");copy(out,argv[4]);return fclose(out)!=0;}
