#include <stdio.h>
#include <string.h>
typedef struct { const char *name; unsigned seg,off; int found; } SYM;
static SYM sym[]={{"RegOpenPath",0,0,0},{"RegSearchPath",0,0,0},{"RegLoadKey",0,0,0},{"RegGetKeyRecord",0,0,0},{"RegNameChecksum",0,0,0},{"RegCompareName",0,0,0},{"RegCreatePath",0,0,0}};
static unsigned char io[300000];
static unsigned word(size_t p) { return io[p] | ((unsigned)io[p+1]<<8); }
int main(void) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t n,i,site,base=187392; unsigned caller[]={0xb3,0x1d7,0x9d}, faroff[]={0x59,0x135,0x169}, farid[]={2,2,3}, nearoff[]={0xfb,0x1a4,0x1ed}, nearid[]={4,5,1};
 f=fopen("out/IO.SYS","rb"); if(!f) return 2; n=fread(io,1,sizeof io,f); fclose(f);
 f=fopen("bios/config.map","r"); if(!f) return 2; while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<7;i++) if(!strcmp(name,sym[i].name)) { sym[i].seg=seg; sym[i].off=off; sym[i].found=1; } fclose(f);
 for(i=0;i<7;i++) if(!sym[i].found) return 2;
 for(i=0;i<2;i++) { site=base+16u*sym[0].seg+sym[0].off+caller[i]; if(site+5>n||io[site]!=0x9a||word(site+1)!=sym[1].off||word(site+3)!=sym[1].seg) { printf("FAIL search caller %u\n",(unsigned)i); return 1; } }
 site=base+16u*sym[6].seg+sym[6].off+caller[2]; if(site+4>n||io[site]!=0x0e||io[site+1]!=0xe8||sym[6].seg!=sym[1].seg||((sym[6].off+caller[2]+4+word(site+2))&0xffff)!=sym[1].off) { puts("FAIL search near caller"); return 1; }
 for(i=0;i<3;i++) { site=base+16u*sym[1].seg+sym[1].off+faroff[i]; if(site+5>n||io[site]!=0x9a||word(site+1)!=sym[farid[i]].off||word(site+3)!=sym[farid[i]].seg) { printf("FAIL search FAR dependency %u\n",(unsigned)i); return 1; } }
 for(i=0;i<3;i++) { site=base+16u*sym[1].seg+sym[1].off+nearoff[i]; if(site+3>n||io[site]!=0xe8||sym[1].seg!=sym[nearid[i]].seg||((sym[1].off+nearoff[i]+3+word(site+1))&0xffff)!=sym[nearid[i]].off) { printf("FAIL search NEAR dependency %u\n",(unsigned)i); return 1; } }
 puts("PASS: two FAR callers, one NEAR caller and six search dependency/recursive calls resolve correctly"); return 0; }
