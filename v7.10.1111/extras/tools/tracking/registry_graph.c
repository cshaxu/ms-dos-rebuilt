/* Inventory direct assembly procedure dependencies. No binary-match claims. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
#define MAXP 4096
#define MAXE 32768
typedef struct { char name[128],file[MAX_PATH]; int line,idx,low,on,group; } ASM_PROC;
typedef struct { int from,to,line; char name[128],op[8]; } EDGE;
static ASM_PROC p[MAXP]; static EDGE e[MAXE];
static int np,ne,serial,stack[MAXP],top,ng,counts[MAXP];
static char rangefile[32][MAX_PATH]; static int rangestart[32],nr,minline;
static int lookup(const char *s) { int i; for(i=0;i<np;i++) if(!_stricmp(p[i].name,s)) return i; return -1; }
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(2); }
static void scan(const char *path,const char *file,int pass) {
 FILE *f=fopen(path,"r"); char line[2048],a[128],b[128],c[128],d[128],*q; int n=0,cur=-1,k;
 if(!f) fail(path);
 while(fgets(line,sizeof line,f)) {
  n++; if(n<minline)continue;
  if((q=strchr(line,';'))!=NULL) *q=0;
  a[0]=b[0]=c[0]=d[0]=0; k=sscanf(line,"%127s %127s %127s %127s",a,b,c,d);
  if(k>=2&&!_stricmp(b,"proc")) {
   if(!pass) { if(np==MAXP||lookup(a)>=0) {fprintf(stderr,"%s:%d: %s\n",path,n,a);fail("duplicate procedure or capacity exceeded");}
    cur=np++; strcpy(p[cur].name,a); strcpy(p[cur].file,file); p[cur].line=n; p[cur].idx=-1;
   } else cur=lookup(a);
  } else if(k>=2&&!_stricmp(b,"endp")) cur=-1;
  else if(pass&&cur>=0&&k>=2&&(!_stricmp(a,"call")||!_stricmp(a,"jmp")||(!_stricmp(a,"push")&&!_stricmp(b,"offset")&&lookup(c)>=0))) {
   const char *dest=b;
   if(!_stricmp(b,"near")||!_stricmp(b,"far")) dest=!_stricmp(c,"ptr")?d:c;
   else if(!_stricmp(b,"short")) dest=c;
   else if(!_stricmp(a,"push")) dest=c;
   /* Keep unresolved calls, but exclude local branches from the call graph. */
   if(!_stricmp(a,"jmp")&&lookup(dest)<0) continue;
   if(ne==MAXE) fail("edge capacity exceeded");
   e[ne].from=cur; e[ne].to=lookup(dest); e[ne].line=n;
   strcpy(e[ne].name,dest); strcpy(e[ne].op,a); ne++;
  }
 }
 if(ferror(f)) fail("source read error");
 fclose(f);
}
static void visit(int v) {
 int i,w; p[v].idx=p[v].low=serial++; stack[top++]=v;p[v].on=1;
 for(i=0;i<ne;i++) if(e[i].from==v&&(w=e[i].to)>=0) {
  if(p[w].idx<0) {visit(w);if(p[w].low<p[v].low)p[v].low=p[w].low;}
  else if(p[w].on&&p[w].idx<p[v].low)p[v].low=p[w].idx;
 }
 if(p[v].low==p[v].idx) {do {w=stack[--top];p[w].on=0;p[w].group=ng;counts[ng]++;}while(w!=v);ng++;}
}
int main(int argc,char **argv) {
 WIN32_FIND_DATAA data; HANDLE h; char pattern[1024],path[1024];int pass,i,g,j;
 FILE *edges,*groups;
 if(argc!=4&&argc!=5) fail("usage: registry_graph source-directory calls.csv groups.txt [ranges.txt]");
 if(argc==5){FILE*r=fopen(argv[4],"r");if(!r)fail("cannot read ranges");while(nr<32&&fscanf(r,"%259s %d",rangefile[nr],&rangestart[nr])==2)nr++;fclose(r);if(!nr)fail("empty ranges");}
 for(pass=0;pass<2;pass++) {
  snprintf(pattern,sizeof pattern,"%s\\*.asm",argv[1]);h=FindFirstFileA(pattern,&data);
  if(h==INVALID_HANDLE_VALUE) fail("no assembly sources");
  do {
   minline=1;
   if(nr){for(i=0;i<nr;i++)if(!_stricmp(rangefile[i],data.cFileName))break;if(i==nr)continue;minline=rangestart[i];}
   if(_strnicmp(data.cFileName,"reg",3)&&_stricmp(data.cFileName,"rapiopen.asm")&&_stricmp(data.cFileName,"rqvalue.asm")&&_stricmp(data.cFileName,"configio.asm")) continue;
   if(strlen(argv[1])+strlen(data.cFileName)+2>sizeof path) fail("source path too long");
   strcpy(path,argv[1]);strcat(path,"\\");strcat(path,data.cFileName);scan(path,data.cFileName,pass);
  }while(FindNextFileA(h,&data));
  FindClose(h);
 }
 for(i=0;i<np;i++)if(p[i].idx<0)visit(i);
 edges=fopen(argv[2],"w");groups=fopen(argv[3],"w");if(!edges||!groups)fail("cannot create reports");
 fprintf(edges,"caller,file,line,operation,callee,resolved,caller_group,callee_group\n");
 for(i=0;i<ne;i++)fprintf(edges,"%s,%s,%d,%s,%s,%s,%d,%d\n",p[e[i].from].name,p[e[i].from].file,e[i].line,e[i].op,e[i].name,e[i].to<0?"no":"yes",p[e[i].from].group,e[i].to<0?-1:p[e[i].to].group);
 fprintf(groups,"Source: %s\nProcedures: %d; direct calls/tail calls: %d; SCCs: %d\n",argv[1],np,ne,ng);
 for(i=0;i<nr;i++)fprintf(groups,"Selected range: %s from line %d\n",rangefile[i],rangestart[i]);
 fprintf(groups,"Scope: reg*.asm, rapiopen.asm, rqvalue.asm, configio.asm.\nDependency-first SCC order. Assembly PROC declarations only.\nIncludes direct calls/tail calls and pushed procedure offsets as conservative dependencies.\nUnresolved/indirect calls, shared data and conditional assembly require review.\nThese are source dependencies, not verified target functions.\n");
 for(g=0;g<ng;g++) {
  fprintf(groups,"\nGROUP %d (%d procedures)\n",g,counts[g]);
  for(i=0;i<np;i++)if(p[i].group==g)fprintf(groups,"  %s %s:%d\n",p[i].name,p[i].file,p[i].line);
  fprintf(groups,"  dependencies:");
  for(j=0;j<g;j++){int found=0;for(i=0;i<ne;i++)if(p[e[i].from].group==g&&e[i].to>=0&&p[e[i].to].group==j){found=1;break;}if(found)fprintf(groups," %d",j);}
  fprintf(groups,"\n");
 }
 if(fclose(edges)||fclose(groups))fail("report write failed");
 printf("%d procedures, %d direct edges, %d SCCs\n",np,ne,ng);return 0;
}
