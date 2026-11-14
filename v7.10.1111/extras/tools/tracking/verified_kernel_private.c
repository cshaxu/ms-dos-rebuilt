#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <windows.h>
typedef struct { char name[128]; unsigned seg,off; } SYM;
typedef struct { char name[128],seg[128]; unsigned off,len; int pub; } KPROC;
typedef struct { char seg[128]; long base; int anchors,conflict; } BASE;
static SYM syms[5000]; static KPROC procs[5000]; static BASE bases[128];
static size_t seenat[10000]; static unsigned seenlen[10000];
static unsigned char io[300000],target[300000],bin[100000],sys[100000];
static size_t load(const char *p,unsigned char *v,size_t cap) { FILE *f=fopen(p,"rb"); size_t n; if(!f) exit(2); n=fread(v,1,cap,f); fclose(f); return n; }
static size_t unique(const unsigned char *a,size_t n,const unsigned char *b,size_t m) { size_t i,at=0,count=0; if(m>n) exit(3); for(i=0;i+m<=n;i++) if(!memcmp(a+i,b,m)) { at=i; count++; } if(count!=1) exit(3); return at; }
int main(int argc,char **argv) {
 FILE *f,*out; WIN32_FIND_DATAA fd; HANDLE h; char line[4096],name[128],segname[128],path[512],*p,*q,*after;
 unsigned s,o; int ns=0,np,nb,active=0,nseen=0,i,j,k,m,count=0; long base; size_t ion,tn,bn,sn,ioat,skip,at;
 if(argc!=2) return 2;
 ion=load("out/IO.SYS",io,sizeof io); tn=load("../../baselines/targets/IO.SYS",target,sizeof target);
 bn=load("dos/MSDOS.BIN",bin,sizeof bin); sn=load("dos/MSDOS.SYS",sys,sizeof sys);
 ioat=unique(io,ion,sys,sn); skip=unique(bin,bn,sys,sn);
 if(ioat+sn>tn || memcmp(io+ioat,target+ioat,sn)) return 3;
 f=fopen("dos/MSDOS.MAP","r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) { if(strstr(line,"Publics by Name")) { active=1; continue; } if(strstr(line,"Publics by Value")) break; if(active && sscanf(line," %x:%x %127s",&s,&o,name)==3 && strcmp(name,"Abs") && ns<5000) { strcpy(syms[ns].name,name); syms[ns].seg=s; syms[ns++].off=o; } } fclose(f);
 f=fopen(argv[1],"r"); if(!f) return 2;
 while(fgets(line,sizeof line,f)) { unsigned long pos; unsigned len; if(sscanf(line,"%*[^,],%*[^,],%*[^,],%lu,%u",&pos,&len)==2 && nseen<10000) { seenat[nseen]=pos; seenlen[nseen++]=len; } } fclose(f);
 out=fopen(argv[1],"a"); if(!out) return 2; h=FindFirstFileA("dos/*.LST",&fd); if(h==INVALID_HANDLE_VALUE) return 2;
 do {
  snprintf(path,sizeof path,"dos/%s",fd.cFileName); f=fopen(path,"rb"); if(!f) continue; active=np=nb=0;
  while(fgets(line,sizeof line,f)) { if(strstr(line,"Procedures,  parameters and locals:")) { active=1; continue; } if(!active) continue;
   p=strstr(line,"P Near"); if(!p) p=strstr(line,"P Far"); q=strstr(line,"Length="); if(!p||!q||sscanf(line," %127s",name)!=1||np>=5000) continue;
   p+=6; while(isspace((unsigned char)*p)) p++; o=(unsigned)strtoul(p,&after,16); while(isspace((unsigned char)*after)) after++; if(sscanf(after,"%127s",segname)!=1) continue;
   q+=7; while(isspace((unsigned char)*q)) q++; s=(unsigned)strtoul(q,NULL,16); if(!s) continue;
   strcpy(procs[np].name,name); strcpy(procs[np].seg,segname); procs[np].off=o; procs[np].len=s; procs[np].pub=strstr(q,"Public")!=NULL; np++;
  } fclose(f);
  for(j=0;j<np;j++) if(procs[j].pub) for(k=0;k<ns;k++) if(!_stricmp(procs[j].name,syms[k].name)) {
   base=16L*syms[k].seg+syms[k].off-procs[j].off;
   for(m=0;m<nb && _stricmp(bases[m].seg,procs[j].seg);m++);
   if(m==nb && nb<128) { strcpy(bases[nb].seg,procs[j].seg); bases[nb].base=base; bases[nb].anchors=0; bases[nb].conflict=0; nb++; }
   if(m<nb) { bases[m].anchors++; if(bases[m].base!=base) bases[m].conflict=1; } break;
  }
  for(j=0;j<np;j++) if(!procs[j].pub) {
   for(m=0;m<nb && _stricmp(bases[m].seg,procs[j].seg);m++); if(m==nb||bases[m].conflict||bases[m].anchors<2) continue;
   base=bases[m].base+procs[j].off; if(base<0 || (size_t)base<skip || (size_t)base+procs[j].len>skip+sn || (size_t)base+procs[j].len>bn) continue;
   at=ioat+(size_t)base-skip; if(at+procs[j].len>tn || memcmp(bin+base,target+at,procs[j].len)) continue;
   for(k=0;k<nseen;k++) if(seenat[k]==at && seenlen[k]==procs[j].len) break; if(k<nseen||nseen>=10000) continue;
   seenat[nseen]=at; seenlen[nseen++]=procs[j].len; fprintf(out,"IO.SYS,%s,%s,%lu,%u,exact_kernel_private\n",path,procs[j].name,(unsigned long)at,procs[j].len); count++;
  }
 } while(FindNextFileA(h,&fd)); FindClose(h); fclose(out); printf("verified_kernel_private_functions=%d (two agreeing public anchors; full target byte comparison)\n",count); return 0;
}
