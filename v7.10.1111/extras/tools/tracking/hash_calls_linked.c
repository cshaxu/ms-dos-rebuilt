#include <stdio.h>
#include <string.h>
typedef struct { const char *name; unsigned seg,off; int found; } SYM;
static SYM sym[]={{"RegReadFile",0,0,0},{"RegRebuildNameHashes",0,0,0},{"RegLoadKey",0,0,0},{"RegGetKeyRecord",0,0,0},{"RegDirtyKeyBlock",0,0,0},{"RegNameChecksum",0,0,0}};
static unsigned char io[300000];
static unsigned word(size_t p) { return io[p] | ((unsigned)io[p+1]<<8); }
int main(void) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t n,i,site,base=187392; unsigned faroff[]={0x56,0x90,0x147}, farid[]={2,3,4};
 f=fopen("out/IO.SYS","rb"); if(!f) return 2; n=fread(io,1,sizeof io,f); fclose(f);
 f=fopen("bios/config.map","r"); if(!f) return 2; while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<6;i++) if(!strcmp(name,sym[i].name)) { sym[i].seg=seg; sym[i].off=off; sym[i].found=1; } fclose(f);
 for(i=0;i<6;i++) if(!sym[i].found) return 2;
 site=base+16u*sym[0].seg+sym[0].off+0x505; if(site+5>n||io[site]!=0x9a||word(site+1)!=sym[1].off||word(site+3)!=sym[1].seg) { puts("FAIL hash FAR caller"); return 1; }
 for(i=0;i<3;i++) { site=base+16u*sym[1].seg+sym[1].off+faroff[i]; if(site+5>n||io[site]!=0x9a||word(site+1)!=sym[farid[i]].off||word(site+3)!=sym[farid[i]].seg) { printf("FAIL hash FAR dependency %u\n",(unsigned)i); return 1; } }
 site=base+16u*sym[1].seg+sym[1].off+0xa8; if(site+3>n||io[site]!=0xe8||sym[1].seg!=sym[5].seg||((sym[1].off+0xa8+3+word(site+1))&0xffff)!=sym[5].off) { puts("FAIL hash NEAR checksum"); return 1; }
 puts("PASS: hash caller, three FAR dependencies and NEAR checksum resolve correctly"); return 0; }
