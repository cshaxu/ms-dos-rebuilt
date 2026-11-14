#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
typedef struct{char name[128];unsigned seg,off;} SYM;
typedef struct{char name[128],segment[128];unsigned off,len;int pub;} PROC;
typedef struct{char segment[128];long base;int anchors,conflict;} BASE;
static SYM syms[5000];static PROC procs[5000];static BASE bases[128];static int ns,np,nb;
static size_t seenat[10000]; static unsigned seenlen[10000]; static int nseen;
static unsigned char io[300000],target[300000];
static size_t load(const char*p,unsigned char*v){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,300000,f);fclose(f);return n;}
int main(int argc,char**argv){const char*files[]={"bios/MSBIO1.LST","bios/MSBIO2.LST","bios/MSCHAR.LST","bios/SYSINIT1.LST","bios/SYSCONF.LST","bios/SI1TAIL.LST","bios/SI2FRONT.LST","bios/SYSPRE.LST","bios/MBLATE.LST","bios/STKINIT.LST","bios/STSTATE.LST",NULL};FILE*f,*out;char line[4096],name[128],segname[128],*p,*q,*after;unsigned s,o;int active=0,i,j,k,m,count=0;size_t n,at;long base;
 if(argc!=2||load("out/IO.SYS",io)<187392||(n=load("../../baselines/targets/IO.SYS",target))<187392||memcmp(io+512,target+512,186880))return 2;
 f=fopen("bios/MSBIO.MAP","r");if(!f)return 2;while(fgets(line,sizeof line,f)){if(strstr(line,"Publics by Name")){active=1;continue;}if(strstr(line,"Publics by Value"))break;if(active&&sscanf(line," %x:%x %127s",&s,&o,name)==3&&strcmp(name,"Abs")&&ns<5000){strcpy(syms[ns].name,name);syms[ns].seg=s;syms[ns].off=o;ns++;}}fclose(f);
 f=fopen(argv[1],"r");if(!f)return 2;while(fgets(line,sizeof line,f)){unsigned long pos;unsigned length;if(sscanf(line,"%*[^,],%*[^,],%*[^,],%lu,%u",&pos,&length)==2&&nseen<10000){seenat[nseen]=pos;seenlen[nseen++]=length;}}fclose(f);
 out=fopen(argv[1],"a");if(!out)return 2;
 for(i=0;files[i];i++){f=fopen(files[i],"rb");if(!f)continue;active=np=nb=0;
  while(fgets(line,sizeof line,f)){if(strstr(line,"Procedures,  parameters and locals:")){active=1;continue;}if(!active)continue;p=strstr(line,"P Near");if(!p)p=strstr(line,"P Far");q=strstr(line,"Length=");if(!p||!q||sscanf(line," %127s",name)!=1||np>=5000)continue;
   p+=6;while(isspace((unsigned char)*p))p++;o=(unsigned)strtoul(p,&after,16);while(isspace((unsigned char)*after))after++;if(sscanf(after,"%127s",segname)!=1)continue;q+=7;while(isspace((unsigned char)*q))q++;s=(unsigned)strtoul(q,NULL,16);if(!s)continue;
   strcpy(procs[np].name,name);strcpy(procs[np].segment,segname);procs[np].off=o;procs[np].len=s;procs[np].pub=strstr(q,"Public")!=NULL;np++;
  }fclose(f);
  for(j=0;j<np;j++)if(procs[j].pub){for(k=0;k<ns;k++)if(!_stricmp(procs[j].name,syms[k].name)){base=16L*syms[k].seg+syms[k].off-procs[j].off;for(m=0;m<nb&&_stricmp(bases[m].segment,procs[j].segment);m++);if(m==nb&&nb<128){strcpy(bases[nb].segment,procs[j].segment);bases[nb].base=base;bases[nb].anchors=0;bases[nb].conflict=0;nb++;}if(m<nb){bases[m].anchors++;if(bases[m].base!=base)bases[m].conflict=1;}break;}}
  for(j=0;j<np;j++)if(!procs[j].pub){for(m=0;m<nb&&_stricmp(bases[m].segment,procs[j].segment);m++);if(m==nb||bases[m].conflict||bases[m].anchors<2)continue;base=bases[m].base+procs[j].off;at=2048u+(size_t)base;if(base<0||at<2048u+0x1a00u||at+procs[j].len>2048u+0x10030u||at+procs[j].len>n||memcmp(io+at,target+at,procs[j].len))continue;
   for(k=0;k<nseen;k++){if(seenat[k]==at&&seenlen[k]==procs[j].len)break;}
   if(k<nseen||nseen>=10000)continue;
   seenat[nseen]=at;seenlen[nseen++]=procs[j].len;
   fprintf(out,"IO.SYS,%s,%s,%lu,%u,exact_private\n",files[i],procs[j].name,(unsigned long)at,procs[j].len);count++;
  }
 }fclose(out);printf("verified_private_functions=%d (module segment requires >=2 agreeing public anchors)\n",count);return 0;}
