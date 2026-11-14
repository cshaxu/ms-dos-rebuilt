#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct { char path[1024]; unsigned sides; } ENTRY;
static ENTRY entries[4096]; static unsigned count;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static void walk(const char *root,const char *relative,unsigned side) {
    char path[2048],child[1024]; WIN32_FIND_DATAA data; HANDLE h; unsigned i;
    snprintf(path,sizeof(path),"%s\\%s\\*",root,relative);
    h=FindFirstFileA(path,&data); if(h==INVALID_HANDLE_VALUE) fail(path);
    do {
        if(!strcmp(data.cFileName,".") || !strcmp(data.cFileName,"..")) continue;
        if(data.dwFileAttributes&FILE_ATTRIBUTE_REPARSE_POINT) fail("Unexpected reparse point");
        snprintf(child,sizeof(child),"%s\\%s",relative,data.cFileName);
        if(data.dwFileAttributes&FILE_ATTRIBUTE_DIRECTORY) { walk(root,child,side); continue; }
        for(i=0;i<count;i++) if(!_stricmp(entries[i].path,child)) break;
        if(i==count) {
            if(count==4096) fail("Inventory limit");
            strcpy(entries[count++].path,child);
        }
        entries[i].sides|=side;
    } while(FindNextFileA(h,&data));
    if(GetLastError()!=ERROR_NO_MORE_FILES) fail("Enumeration failed");
    FindClose(h);
}
static int cmp(const void *a,const void *b) { return _stricmp(((const ENTRY*)a)->path,((const ENTRY*)b)->path); }
static int identical(const char *a,const char *b,const char *rel) {
    char path[2048]; unsigned char x[8192],y[8192]; FILE *f,*g; size_t n,m; int same=1;
    snprintf(path,sizeof(path),"%s\\%s",a,rel); f=fopen(path,"rb"); if(!f) fail(path);
    snprintf(path,sizeof(path),"%s\\%s",b,rel); g=fopen(path,"rb"); if(!g) fail(path);
    do {
        n=fread(x,1,sizeof(x),f); m=fread(y,1,sizeof(y),g);
        if(ferror(f)||ferror(g)) fail("Read failed");
        if(n!=m || memcmp(x,y,n)) { same=0; break; }
    } while(n);
    fclose(f); fclose(g); return same;
}
int main(int argc,char **argv) {
    const char *roots[]={"bios","dos","inc","cmd","lang"};
    unsigned i,same=0,changed=0,added=0,removed=0; const char *status;
    if(argc!=3) return 2;
    for(i=0;i<5;i++) { walk(argv[1],roots[i],1); walk(argv[2],roots[i],2); }
    qsort(entries,count,sizeof(*entries),cmp);
    puts("path,status_vs_950");
    for(i=0;i<count;i++) {
        if(entries[i].sides==1) { status="removed"; removed++; }
        else if(entries[i].sides==2) { status="added"; added++; }
        else if(identical(argv[1],argv[2],entries[i].path)) { status="identical"; same++; }
        else { status="modified"; changed++; }
        printf("%s,%s\n",entries[i].path,status);
    }
    fprintf(stderr,"Core files: %u current; %u identical, %u modified, %u added; %u removed from baseline (%u).\n",same+changed+added,same,changed,added,removed,same+changed+removed);
    return 0;
}
