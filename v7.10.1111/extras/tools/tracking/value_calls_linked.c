#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { const char *name; unsigned seg,off; int found; } SYM;
static SYM symbols[]={{"RegOpenPath",0,0,0},{"RegOpenKey",0,0,0},{"RegFindValue",0,0,0},{"RegCompareName",0,0,0}};
static unsigned char io[300000];
static unsigned word(size_t p) { return io[p] | ((unsigned)io[p+1]<<8); }
int main(void) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t n,i,site,base=187392; unsigned offsets[]={0x360,0x5e9,0x715};
 f=fopen("out/IO.SYS","rb"); if(!f) return 2; n=fread(io,1,sizeof io,f); fclose(f);
 f=fopen("bios/config.map","r"); if(!f) return 2; while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<4;i++) if(!strcmp(name,symbols[i].name)) { symbols[i].seg=seg; symbols[i].off=off; symbols[i].found=1; } fclose(f);
 for(i=0;i<4;i++) if(!symbols[i].found) return 2;
 for(i=0;i<4;i++) { site=base+16u*symbols[i==3?1:0].seg+symbols[i==3?1:0].off+(i==3?0x273:offsets[i]); if(site+5>n||io[site]!=0x9a||word(site+1)!=symbols[2].off||word(site+3)!=symbols[2].seg) { printf("FAIL far call %u at %lu\n",(unsigned)i,(unsigned long)site); return 1; } }
 site=base+16u*symbols[2].seg+symbols[2].off+0x92; if(site+3>n||io[site]!=0xe8||symbols[2].seg!=symbols[3].seg||((symbols[2].off+0x92+3+word(site+1))&0xffff)!=symbols[3].off) { puts("FAIL near compare binding"); return 1; }
 puts("PASS: four FAR callers resolve to RegFindValue; its NEAR call resolves to RegCompareName"); return 0; }
