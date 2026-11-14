#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char *p,unsigned char *b){FILE *f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(b,1,300000,f);fclose(f);return n;}
int main(int argc,char **argv){FILE *f;char line[256],name[128];unsigned s=0,o=0,x,y;size_t at;
 if(argc>2)return 2;
 if(load("out/IO.SYS",a)<214836||load("../../baselines/targets/IO.SYS",b)!=214836)return 2;
 f=fopen("bios/config.map","r");if(!f)return 2;
 while(fgets(line,sizeof(line),f))if(sscanf(line," %x:%x %127s",&x,&y,name)==3&&!strcmp(name,"RegChecksum")){s=x;o=y;break;}
 fclose(f);if(!s)return 2;at=187392+16u*s+o;
 if(memcmp(a+at,b+212280,66)){printf("FAIL linked checksum at %lu\n",(unsigned long)at);return 1;}
 if(argc==2){f=fopen(argv[1],"a");if(!f)return 2;fprintf(f,"IO.SYS,bios/REGREAD.LST,RegChecksum,212280,66,exact_config_verified\n");if(fclose(f))return 2;}
 printf("PASS linked RegChecksum: 66 bytes exactly match target at 212280\n");return 0;}
