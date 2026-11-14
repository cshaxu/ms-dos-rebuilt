#include <stdio.h>
#include <string.h>
typedef struct { const char *name; unsigned seg,off; int found; } SYM;
static SYM sym[]={{"RegOpenPath",0,0,0},{"RegOpenKey",0,0,0},{"RegFindAlias",0,0,0},{"RegNameChecksum",0,0,0},{"RegCompareName",0,0,0}};
static unsigned char io[300000];
static unsigned word(size_t p) { return io[p] | ((unsigned)io[p+1]<<8); }
int main(void) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t n,i,site,base=187392; unsigned faroff[]={0x123,0x151,0x5d1,0x601,0xf30}; unsigned nearoff[]={0x5a,0xa3};
 f=fopen("out/IO.SYS","rb"); if(!f) return 2; n=fread(io,1,sizeof io,f); fclose(f);
 f=fopen("bios/config.map","r"); if(!f) return 2; while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<5;i++) if(!strcmp(name,sym[i].name)) { sym[i].seg=seg; sym[i].off=off; sym[i].found=1; } fclose(f);
 for(i=0;i<5;i++) if(!sym[i].found) return 2;
 for(i=0;i<5;i++) { unsigned s=i<2?0:1; site=base+16u*sym[s].seg+sym[s].off+faroff[i]; if(site+5>n||io[site]!=0x9a||word(site+1)!=sym[2].off||word(site+3)!=sym[2].seg) { printf("FAIL alias FAR call %u\n",(unsigned)i); return 1; } }
 for(i=0;i<2;i++) { site=base+16u*sym[2].seg+sym[2].off+nearoff[i]; if(site+3>n||io[site]!=0xe8||sym[2].seg!=sym[3+i].seg||((sym[2].off+nearoff[i]+3+word(site+1))&0xffff)!=sym[3+i].off) { printf("FAIL alias NEAR call %u\n",(unsigned)i); return 1; } }
 puts("PASS: five FAR alias callers and two NEAR name calls resolve correctly"); return 0; }
