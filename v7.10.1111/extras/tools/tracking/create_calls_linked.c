#include <stdio.h>
#include <string.h>
typedef struct { const char *name; unsigned seg,off; int found; } SYM;
static SYM s[]={{"RegOpenPath",0,0,0},{"RegInitialize",0,0,0},{"RegCreatePath",0,0,0},{"RegLoadKey",0,0,0},{"RegAllocateRecord",0,0,0},{"RegGetDataBlock",0,0,0},{"RegFreeRecordId",0,0,0},{"RegDeleteKeyTree",0,0,0},{"RegPathPart",0,0,0},{"RegSearchPath",0,0,0},{"RegCopyPart",0,0,0},{"RegGrowKeyBlock",0,0,0},{"RegMaintainCache",0,0,0},{"RegDirtyKeyBlock",0,0,0},{"RegNameChecksum",0,0,0}};
static unsigned char io[300000]; static unsigned word(size_t p) { return io[p] | ((unsigned)io[p+1]<<8); }
int main(void) { FILE *f; char line[256],name[128]; unsigned seg,off; size_t n,i,site,base=187392;
 static const unsigned fs[]={0x29,0x146,0x18d,0x1fc,0x23a,0x26a,0x306,0x410,0x46e,0x51e,0x65,0x9d,0x119,0x1ce,0x214,0x222,0x4cb};
 static const unsigned fi[]={3,4,3,5,6,3,3,3,3,7,8,9,10,11,12,11,13};
 static const unsigned ns[]={0xec,0x4ff,0x3f6}, ni[]={2,2,14};
 f=fopen("out/IO.SYS","rb"); if(!f) return 2; n=fread(io,1,sizeof io,f); fclose(f);
 f=fopen("bios/config.map","r"); if(!f) return 2; while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3) for(i=0;i<15;i++) if(!strcmp(name,s[i].name)) { s[i].seg=seg; s[i].off=off; s[i].found=1; } fclose(f);
 for(i=0;i<15;i++) if(!s[i].found) { printf("Missing %s\n",s[i].name); return 2; }
 for(i=0;i<2;i++) { site=base+16u*s[i].seg+s[i].off+(i?0x45d:0x201); if(site+5>n||io[site]!=0x9a||word(site+1)!=s[2].off||word(site+3)!=s[2].seg) { printf("FAIL create caller %u\n",(unsigned)i); return 1; } }
 for(i=0;i<sizeof fs/sizeof *fs;i++) { unsigned rel=fs[i]-(fs[i]>0x9d); if(fs[i]==0x9d) continue; site=base+16u*s[2].seg+s[2].off+rel; if(site+5>n||io[site]!=0x9a||word(site+1)!=s[fi[i]].off||word(site+3)!=s[fi[i]].seg) { printf("FAIL create FAR dependency %u at %04x\n",(unsigned)i,rel); return 1; } }
 for(i=0;i<3;i++) { unsigned rel=ns[i]-(ns[i]>0x9d); site=base+16u*s[2].seg+s[2].off+rel; if(site+3>n||io[site]!=0xe8||s[2].seg!=s[ni[i]].seg||((s[2].off+rel+3+word(site+1))&0xffff)!=s[ni[i]].off) { printf("FAIL create NEAR dependency %u\n",(unsigned)i); return 1; } }
 site=base+16u*s[2].seg+s[2].off+0x9d;
 if(site+4>n||io[site]!=0x0e||io[site+1]!=0xe8||s[2].seg!=s[9].seg||((s[2].off+0x9d+4+word(site+2))&0xffff)!=s[9].off) { puts("FAIL near search call"); return 1; }
 puts("PASS: two FAR callers, 16 FAR dependencies, near search, recursion and checksum resolve correctly"); return 0; }
