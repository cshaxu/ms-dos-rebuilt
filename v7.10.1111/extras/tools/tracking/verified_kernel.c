#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
typedef struct{char name[128];unsigned seg,off;int used;} SYM;
static SYM syms[5000];static int ns;
static unsigned char io[300000],target[300000],bin[100000],sys[100000];
static size_t load(const char*p,unsigned char*v,size_t cap){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,cap,f);fclose(f);return n;}
static size_t find_unique(const unsigned char*a,size_t n,const unsigned char*b,size_t m){size_t i,at=0,count=0;if(m>n)exit(3);for(i=0;i+m<=n;i++)if(!memcmp(a+i,b,m)){at=i;count++;}if(count!=1)exit(3);return at;}
int main(int argc,char**argv){FILE*f,*out;WIN32_FIND_DATAA fd;HANDLE h;char line[4096],name[128],path[512],*p,*q;unsigned seg,off,len;int active=0,i,count=0;size_t ion,tn,bn,sn,ioat,skip,at;
 if(argc!=2)return 2;
 ion=load("out/IO.SYS",io,sizeof io);tn=load("../../baselines/targets/IO.SYS",target,sizeof target);bn=load("dos/MSDOS.BIN",bin,sizeof bin);sn=load("dos/MSDOS.SYS",sys,sizeof sys);
 ioat=find_unique(io,ion,sys,sn);skip=find_unique(bin,bn,sys,sn);if(ioat+sn>tn||memcmp(io+ioat,target+ioat,sn))return 3;
 f=fopen("dos/MSDOS.MAP","r");if(!f)return 2;while(fgets(line,sizeof line,f)){if(strstr(line,"Publics by Name")){active=1;continue;}if(strstr(line,"Publics by Value"))break;if(!active)continue;if(sscanf(line," %x:%x %127s",&seg,&off,name)==3&&strcmp(name,"Abs")&&ns<5000){strcpy(syms[ns].name,name);syms[ns].seg=seg;syms[ns].off=off;ns++;}}fclose(f);
 out=fopen(argv[1],"a");if(!out)return 2;h=FindFirstFileA("dos/*.LST",&fd);if(h==INVALID_HANDLE_VALUE)return 2;
 do{snprintf(path,sizeof path,"dos/%s",fd.cFileName);f=fopen(path,"rb");if(!f)continue;active=0;while(fgets(line,sizeof line,f)){if(strstr(line,"Procedures,  parameters and locals:")){active=1;continue;}if(!active)continue;
 p=strstr(line,"P Near");if(!p)p=strstr(line,"P Far");q=strstr(line,"Length=");if(!p||!q||sscanf(line," %127s",name)!=1)continue;q+=7;while(isspace((unsigned char)*q))q++;len=(unsigned)strtoul(q,NULL,16);if(!len)continue;
 for(i=0;i<ns;i++)if(!_stricmp(name,syms[i].name)&&!syms[i].used){at=16u*syms[i].seg+syms[i].off;if(at>=skip&&at+len<=skip+sn&&at+len<=bn&&!memcmp(bin+at,sys+at-skip,len)&&!memcmp(bin+at,target+ioat+at-skip,len)){fprintf(out,"IO.SYS,%s,%s,%lu,%u,exact\n",path,name,(unsigned long)(ioat+at-skip),len);syms[i].used=1;count++;}break;}}
 fclose(f);}while(FindNextFileA(h,&fd));FindClose(h);fclose(out);printf("verified_kernel_functions=%d; payload=%lu length=%lu stripped_prefix=%lu\n",count,(unsigned long)ioat,(unsigned long)sn,(unsigned long)skip);return 0;}
