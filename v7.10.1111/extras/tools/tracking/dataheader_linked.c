#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char *p,unsigned char *b){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(b,1,300000,f);fclose(f);return n;}
int main(int argc,char **argv){FILE*f;char line[256],name[128];unsigned s=0,o=0,x,y;size_t at,i,n,hits=0,hit=0;
 if(argc>2)return 2;
 if(load("out/IO.SYS",a)<214836||(n=load("../../baselines/targets/IO.SYS",b))!=214836)return 2;
 f=fopen("bios/config.map","r");if(!f)return 2;while(fgets(line,sizeof line,f))if(sscanf(line," %x:%x %127s",&x,&y,name)==3&&!strcmp(name,"RegValidateDataBlock")){s=x;o=y;break;}fclose(f);if(!s)return 2;
 at=187392+16u*s+o;for(i=0;i+39<=n;i++)if(!memcmp(a+at,b+i,39)){hits++;hit=i;}
 if(hits!=1){printf("FAIL: %lu target matches\n",(unsigned long)hits);return 1;}
 if(argc==2){f=fopen(argv[1],"a");if(!f)return 2;fprintf(f,"IO.SYS,bios/REGREAD.LST,RegValidateDataBlock,%lu,39,exact_config_verified\n",(unsigned long)hit);if(fclose(f))return 2;}
 printf("PASS: 39 linked bytes match target at %lu\n",(unsigned long)hit);return 0;}
