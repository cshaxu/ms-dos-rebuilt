#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { const char *name; unsigned target,length; size_t at; } ENTRY;
static ENTRY entries[]={{"RegNameChecksum",212346,84,0},{"RegCompareName",212430,111,0}};
static unsigned char linked[300000],target[300000];
static size_t load(const char *p,unsigned char *v) { FILE *f=fopen(p,"rb"); size_t n; if(!f) exit(2); n=fread(v,1,300000,f); fclose(f); return n; }
int main(int argc,char **argv) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t i,n,tn;
 n=load("out/IO.SYS",linked); tn=load("../../baselines/targets/IO.SYS",target); if(tn!=214836) return 2;
 f=fopen("bios/config.map","r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<2;i++) if(!strcmp(name,entries[i].name)) entries[i].at=187392u+16u*seg+off;
 fclose(f); for(i=0;i<2;i++) { ENTRY *e=&entries[i]; if(!e->at||e->at+e->length>n||e->target+e->length>tn||memcmp(linked+e->at,target+e->target,e->length)) { printf("FAIL %s\n",e->name); return 1; } printf("PASS %s: %u exact bytes at target %u\n",e->name,e->length,e->target); }
 if(argc==2) { f=fopen(argv[1],"a"); if(!f) return 2; for(i=0;i<2;i++) fprintf(f,"IO.SYS,bios/REGSTR.LST,%s,%u,%u,exact_config_names\n",entries[i].name,entries[i].target,entries[i].length); if(fclose(f)) return 2; } else if(argc!=1) return 2;
 return 0; }
