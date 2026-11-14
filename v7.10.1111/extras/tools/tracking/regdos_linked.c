#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char *p,unsigned char *v) { FILE *f=fopen(p,"rb"); size_t n; if(!f) exit(2); n=fread(v,1,300000,f); fclose(f); return n; }
typedef struct { const char *name; unsigned offset,length; int seen; } ENTRY;
static ENTRY entries[]={
 {"RegDosCreate",0x000,0x21,0},{"RegDosOpen",0x021,0x1c,0},
 {"RegDosWrite",0x03d,0x04,0},{"RegDosRead",0x041,0x23,0},
 {"RegDosSeek",0x064,0x2c,0},{"RegDosClose",0x090,0x12,0},
 {"RegMoveMemory",0x0a2,0x5a,0},{"RegZeroMemory",0x0fc,0x26,0},
 {"RegDosAlloc",0x122,0x22,0},{"RegDosFree",0x144,0x12,0},
 {"RegDosRealloc",0x156,0x4e,0},{"RegDosGetAttr",0x1a4,0x22,0},
 {"RegDosSetAttr",0x1c6,0x1b,0},{"RegDosDelete",0x1e1,0x17,0},
 {"RegDosRename",0x1f8,0x1a,0},{"RegDosTempFile",0x212,0x1b,0}
};
int main(int argc,char **argv) {
 FILE *f; char line[256],name[128]; unsigned seg,off; size_t at=0,i,j,linked_size;
 linked_size=load("out/IO.SYS",a);
 if(linked_size<214836 || load("../../baselines/targets/IO.SYS",b)!=214836) return 2;
 f=fopen("bios/config.map","r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3 && !strcmp(name,"RegDosCreate")) { at=187392+16u*seg+off; break; }
 fclose(f); if(!at || at+557>linked_size) return 2;
 for(i=0;i<557;i++) if(a[at+i]!=b[192756+i]) { printf("FAIL offset %lu linked=%02x target=%02x\n",(unsigned long)i,a[at+i],b[192756+i]); return 1; }
 f=fopen("bios/config.map","r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3)
  for(j=0;j<sizeof entries/sizeof *entries;j++) if(!strcmp(name,entries[j].name) && 187392+16u*seg+off==at+entries[j].offset) entries[j].seen=1;
 fclose(f);
 for(j=0;j<sizeof entries/sizeof *entries;j++) if(!entries[j].seen) { printf("FAIL missing or shifted symbol %s\n",entries[j].name); return 1; }
 if(argc==2) {
  f=fopen(argv[1],"a"); if(!f) return 2;
  for(j=0;j<sizeof entries/sizeof *entries;j++) fprintf(f,"IO.SYS,bios/CONFIGIO.LST,%s,%lu,%u,exact_config_group\n",entries[j].name,(unsigned long)(192756+entries[j].offset),entries[j].length);
  fclose(f);
 } else if(argc!=1) return 2;
 printf("PASS registry DOS service group: 557 bytes at linked %lu match target 192756; 16 entries\n",(unsigned long)at); return 0;
}
