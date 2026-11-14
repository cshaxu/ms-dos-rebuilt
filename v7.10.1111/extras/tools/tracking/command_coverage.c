#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct{unsigned long a,b;} RANGE;
static int cmp(const void*x,const void*y){const RANGE*a=x,*b=y;return a->a<b->a?-1:a->a>b->a?1:0;}
int main(int argc,char**argv){FILE*f;char line[2048];RANGE r[10000];unsigned long a,b,start,end,total=0;int n=0,i;if(argc!=2||!(f=fopen(argv[1],"r")))return 2;while(fgets(line,sizeof line,f))if(!strncmp(line,"COMMAND.COM,",12)&&strstr(line,",exact_unique_candidate")&&sscanf(line,"%*[^,],%*[^,],%*[^,],%lu,%lu",&a,&b)==2&&n<10000){r[n].a=a;r[n++].b=a+b;}fclose(f);if(!n)return 3;qsort(r,n,sizeof r[0],cmp);start=r[0].a;end=r[0].b;for(i=1;i<n;i++){if(r[i].a>end){total+=end-start;start=r[i].a;end=r[i].b;}else if(r[i].b>end)end=r[i].b;}total+=end-start;printf("candidate_functions=%d target_unique_bytes=%lu target_bytes=93812 ratio=%.2f%%\n",n,total,100.0*total/93812.0);return 0;}
