#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
typedef struct {char name[128];unsigned seg,off;int used;} Sym;
static Sym sym[5000]; static int ns;
static unsigned char a[300000],b[300000];
static size_t load(const char*p,unsigned char*v){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,300000,f);fclose(f);return n;}
int main(int argc,char**argv){static const char*files[]={"bios/MSBIO1.LST","bios/MSBIO2.LST","bios/MSCHAR.LST","bios/MSDISK.LST","bios/SYSINIT1.LST","bios/SYSCONF.LST","bios/SI1TAIL.LST","bios/SI2FRONT.LST","bios/SYSPRE.LST","bios/MBLATE.LST","bios/STKINIT.LST","bios/STSTATE.LST",NULL};
 FILE*f,*out;char line[4096],name[128],*p,*q;unsigned seg,off,len;int active=0,i,count=0,j;size_t n,at;
 if(argc!=2||load("out/IO.SYS",a)<187392||(n=load("../../baselines/targets/IO.SYS",b))<187392||memcmp(a+512,b+512,186880))return 2;
 f=fopen("bios/MSBIO.MAP","r");if(!f)return 2;
 while(fgets(line,sizeof line,f)){if(strstr(line,"Publics by Name")){active=1;continue;}if(strstr(line,"Publics by Value"))break;if(!active)continue;if(sscanf(line," %x:%x %127s",&seg,&off,name)==3&&strcmp(name,"Abs")&&ns<5000){strcpy(sym[ns].name,name);sym[ns].seg=seg;sym[ns].off=off;ns++;}}
 fclose(f);out=fopen(argv[1],"w");if(!out)return 2;fprintf(out,"component,source_listing,symbol,target_offset,length,status\n");
 for(i=0;files[i];i++){f=fopen(files[i],"rb");if(!f)continue;active=0;
  while(fgets(line,sizeof line,f)){if(strstr(line,"Procedures,  parameters and locals:")){active=1;continue;}if(!active)continue;
   p=strstr(line,"P Near");if(!p)p=strstr(line,"P Far");q=strstr(line,"Length=");if(!p||!q||sscanf(line," %127s",name)!=1)continue;
   q+=7;while(isspace((unsigned char)*q))q++;len=(unsigned)strtoul(q,NULL,16);if(!len)continue;
   for(j=0;j<ns;j++)if(!_stricmp(name,sym[j].name)&&!sym[j].used){at=2048u+16u*sym[j].seg+sym[j].off;
    if(at>=2048u+0x1a00u&&at+len<=2048u+0x10030u&&at+len<=n&&!memcmp(a+at,b+at,len)){
     fprintf(out,"IO.SYS,%s,%s,%lu,%u,exact\n",files[i],name,(unsigned long)at,len);sym[j].used=1;count++;}break;}
  }fclose(f);
 }
 fclose(out);printf("verified_whole_public_functions=%d; target denominator unknown\n",count);return 0;}
