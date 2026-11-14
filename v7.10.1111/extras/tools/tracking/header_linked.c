#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char*p,unsigned char*v){FILE*f=fopen(p,"rb");size_t n;if(!f)exit(2);n=fread(v,1,300000,f);fclose(f);return n;}
static unsigned sym(const char*want){FILE*f=fopen("bios/config.map","r");char s[256],name[128];unsigned seg,off;if(!f)exit(2);while(fgets(s,sizeof s,f))if(sscanf(s," %x:%x %127s",&seg,&off,name)==3&&!strcmp(name,want)){fclose(f);return 187392+16u*seg+off;}fclose(f);exit(2);}
int main(void){size_t at,i,j,skip=0,hits=0,hit=0,n;unsigned csum;int disp;
 if(load("out/IO.SYS",a)<214836||(n=load("../../baselines/targets/IO.SYS",b))!=214836)return 2;
 at=sym("RegValidateHeader");csum=sym("RegChecksum");for(i=0;i+5<72;i++)if(a[at+i]==0x6a&&a[at+i+1]==0x20&&a[at+i+2]==0xe8){skip=i+3;break;}if(!skip)return 3;
 disp=(short)(a[at+skip]|(a[at+skip+1]<<8));if(at+skip+2+disp!=csum)return 4;
 for(i=0;i+72<=n;i++){for(j=0;j<72;j++)if(j!=skip&&j!=skip+1&&a[at+j]!=b[i+j])break;if(j==72){disp=(short)(b[i+skip]|(b[i+skip+1]<<8));if(i+skip+2+disp==212280){hit=i;hits++;}}}
 if(hits!=1){printf("FAIL header candidate matches %lu\n",(unsigned long)hits);return 1;}
 printf("PASS header: 70 literal bytes and 2 verified checksum-call bytes; target offset %lu\n",(unsigned long)hit);return 0;}
