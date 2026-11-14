#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
typedef struct{char name[128];unsigned seg,off;int used;} SYM;
static SYM syms[5000];static int ns;static unsigned char built[150000],target[150000];
static size_t load(const char*p,unsigned char*v){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,150000,f);fclose(f);return n;}
static size_t header(const unsigned char*v,size_t n){size_t h;if(n<32||v[0]!='M'||v[1]!='Z')exit(3);h=16u*(v[8]+256u*v[9]);if(h>=n)exit(3);return h;}
int main(int argc,char**argv){FILE*f,*out;WIN32_FIND_DATAA fd;HANDLE h;char line[4096],name[128],path[512],*p,*q;unsigned seg,off,len;int active=0,i,count=0;size_t bn,tn,bh,th,at,k,hit,hits;
 if(argc!=2)return 2;
 bn=load("out/COMMAND.COM",built);tn=load("../../baselines/targets/COMMAND.COM",target);bh=header(built,bn);th=header(target,tn);
 f=fopen("cmd/command/COMMAND.MAP","r");if(!f)return 2;while(fgets(line,sizeof line,f)){if(strstr(line,"Publics by Name")){active=1;continue;}if(strstr(line,"Publics by Value"))break;if(active&&sscanf(line," %x:%x %127s",&seg,&off,name)==3&&strcmp(name,"Abs")&&ns<5000){strcpy(syms[ns].name,name);syms[ns].seg=seg;syms[ns].off=off;ns++;}}fclose(f);
 out=fopen(argv[1],"a");if(!out)return 2;h=FindFirstFileA("cmd/command/*.LST",&fd);if(h==INVALID_HANDLE_VALUE)return 2;
 do{snprintf(path,sizeof path,"cmd/command/%s",fd.cFileName);f=fopen(path,"rb");if(!f)continue;while(fgets(line,sizeof line,f)){p=strstr(line,"N PROC");if(!p)p=strstr(line,"F PROC");q=strstr(line,"Length =");if(!p||!q||sscanf(line," %127s",name)!=1)continue;q+=8;while(isspace((unsigned char)*q))q++;len=(unsigned)strtoul(q,NULL,16);if(len<16)continue;
 for(i=0;i<ns;i++)if(!_stricmp(name,syms[i].name)&&!syms[i].used){at=bh+16u*syms[i].seg+syms[i].off;if(at+len>bn)break;hits=0;hit=0;
 for(k=th;k+len<=tn;k++)if(built[at]==target[k]&&!memcmp(built+at,target+k,len)){hits++;hit=k;if(hits>1)break;}
 if(hits==1){fprintf(out,"COMMAND.COM,%s,%s,%lu,%u,exact_unique_candidate\n",path,name,(unsigned long)hit,len);syms[i].used=1;count++;}break;}}
 fclose(f);}while(FindNextFileA(h,&fd));FindClose(h);fclose(out);printf("command_exact_unique_candidates=%d; target correspondence needs call-chain confirmation\n",count);return 0;}
