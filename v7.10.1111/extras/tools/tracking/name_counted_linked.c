#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char*p,unsigned char*v){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,300000,f);fclose(f);return n;}
int main(void){FILE*f;char s[256],name[128];unsigned seg,off,i;size_t at=0;if(load("out/IO.SYS",a)<214836||load("../../baselines/targets/IO.SYS",b)!=214836)return 2;f=fopen("bios/config.map","r");if(!f)return 2;while(fgets(s,sizeof s,f))if(sscanf(s," %x:%x %127s",&seg,&off,name)==3&&!strcmp(name,"RegNameSum")){at=187392+16u*seg+off;break;}fclose(f);if(!at)return 2;
 for(i=0;i<84;i++){if(i==7){if(a[at+i]!=6||b[212346+i]!=4)return 1;}else if(i==22||i==25){if(a[at+i]!=8||b[212346+i]!=6)return 1;}else if(i==81){if(a[at+i]!=0xCA||b[212346+i]!=0xC2)return 1;}else if(a[at+i]!=b[212346+i])return 1;}
 puts("PASS RegNameSum: 80 literal bytes; 3 FAR frame offsets and FAR return verified");return 0;}
