#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static unsigned char a[300000],b[300000];
static size_t load(const char *p,unsigned char *v) {
 FILE *f=fopen(p,"rb"); size_t n; if(!f) exit(2);
 n=fread(v,1,300000,f); fclose(f); return n;
}
int main(void) {
 static const unsigned offsets[]={8,14,17,20,51,94,108};
 static const unsigned old[]={6,12,8,14,10,6,0xca};
 static const unsigned target[]={4,10,6,12,8,4,0xc2};
 FILE *f; char line[256],name[128]; unsigned seg,off,i,j; size_t at=0;
 if(load("out/IO.SYS",a)<214836 || load("../../baselines/targets/IO.SYS",b)!=214836) return 2;
 f=fopen("bios/config.map","r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) if(sscanf(line," %x:%x %127s",&seg,&off,name)==3 && !strcmp(name,"RegCompareN")) { at=187392+16u*seg+off; break; }
 fclose(f); if(!at) return 2;
 for(i=0;i<111;i++) {
  for(j=0;j<7 && offsets[j]!=i;j++);
  if(j<7) { if(a[at+i]!=old[j] || b[212430+i]!=target[j]) return 1; }
  else if(a[at+i]!=b[212430+i]) return 1;
 }
 puts("PASS RegCompareN: 104 literal bytes; 6 FAR frame offsets and FAR return verified");
 return 0;
}
