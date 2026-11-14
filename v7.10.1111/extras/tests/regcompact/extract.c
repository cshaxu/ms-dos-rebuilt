#include <stdio.h>
#include <stdlib.h>
#include <string.h>
static void copy(FILE*out,const char*path){FILE*f=fopen(path,"r");char s[2048];if(!f)exit(2);while(fgets(s,sizeof s,f))fputs(s,out);fclose(f);}
static void proc(FILE*out,const char*path,const char*name){FILE*f=fopen(path,"r");char s[2048],a[128],b[128];int on=0,done=0;if(!f)exit(2);while(fgets(s,sizeof s,f)){a[0]=b[0]=0;sscanf(s,"%127s %127s",a,b);if(!strcmp(a,name)&&!strcmp(b,"proc"))on=1;if(on)fputs(s,out);if(on&&!strcmp(a,name)&&!strcmp(b,"endp")){done=1;break;}}fclose(f);if(!done)exit(3);}
int main(int n,char**v){
 FILE*f;
 if(n!=7&&n!=8&&n!=9)return 1;
 f=fopen(v[6],"w");if(!f)return 2;
 copy(f,v[4]);proc(f,v[1],"RegIndexBlock");proc(f,v[1],"RegPackDataBlock");
 if(n==9&&!strcmp(v[7],"extent"))proc(f,v[8],"RegTakeFreeSpace");
 if(n==8&&!strcmp(v[7],"old"))proc(f,v[1],"RegRelocateIndex");
 if(n==8&&!strcmp(v[7],"grow")){proc(f,v[1],"RegGrowDataBlock");proc(f,v[1],"RegDirtyDataBlock");}
 if(n==8&&!strcmp(v[7],"create")){
  proc(f,v[1],"RegAppendDataBlock");proc(f,v[1],"RegNewDataBlock");
  proc(f,v[1],"RegFreeDataBlock");proc(f,v[1],"RegBlockEndOffset");
  proc(f,v[1],"RegDirtyHeader");
 }
 proc(f,v[2],"RegCopyBytes");proc(f,v[3],"RegMoveMemory");
 copy(f,v[5]);return fclose(f)!=0;
}
