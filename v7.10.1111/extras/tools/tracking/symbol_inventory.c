/* Inventory current linker publics and explicitly declared public procedures.
 * Whole-image verification is required; symbol names do not prove identity.
 */
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
typedef struct {
    char name[256],listing[512]; unsigned seg,off,length,definitions;
    int unit;
} SYMBOL;
static SYMBOL symbols[16384]; static unsigned count;
static const char *units[]={"MSBIO","KERNEL","CONFIG","COMMAND"};
static const char *maps[]={"bios/MSBIO.MAP","dos/MSDOS.MAP","bios/CONFIG.MAP","cmd/command/COMMAND.MAP"};
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static void path(char *out,size_t n,const char *root,const char *rel) {
    if(snprintf(out,n,"%s/%s",root,rel)>=(int)n) fail("Path overflow");
}
static void verify(const char *stage,const char *targets,const char *name) {
    unsigned char a[8192],b[8192]; size_t n,m,total=0;
    char p[2048],rel[256]; FILE *f,*g;
    snprintf(rel,sizeof(rel),"out/%s",name); path(p,sizeof(p),stage,rel);
    f=fopen(p,"rb"); if(!f) fail(p);
    path(p,sizeof(p),targets,name); g=fopen(p,"rb"); if(!g) fail(p);
    do {
        n=fread(a,1,sizeof(a),f); m=fread(b,1,sizeof(b),g);
        if(ferror(f)||ferror(g)||n!=m||memcmp(a,b,n)) fail("Full image comparison failed");
        total+=n;
    } while(n);
    fclose(f); fclose(g); if(!total) fail("Empty target");
    printf("%s: exact, %lu bytes\n",name,(unsigned long)total);
}
static void readmap(const char *root,int unit) {
    char p[2048],s[4096],name[256]; FILE *f; int active=0; unsigned seg,off,n=0;
    path(p,sizeof(p),root,maps[unit]); f=fopen(p,"rb"); if(!f) fail(p);
    while(fgets(s,sizeof(s),f)) {
        if(strstr(s,"Publics by Name")) { active=1; continue; }
        if(strstr(s,"Publics by Value")) break;
        if(!active || sscanf(s," %x:%x %255s",&seg,&off,name)!=3 || !strcmp(name,"Abs")) continue;
        if(count==16384 || strchr(name,',')) fail("Invalid public symbol");
        strcpy(symbols[count].name,name); symbols[count].seg=seg;
        symbols[count].off=off; symbols[count++].unit=unit; n++;
    }
    fclose(f); if(!n) fail("Empty linker public inventory");
}
static void listing(const char *root,const char *relative,int directory) {
    char p[2048],line[8192],name[256],segment[256]; FILE *f;
    char *type,*length; unsigned offset,len,i,found; int modern;
    path(p,sizeof(p),root,relative); f=fopen(p,"rb"); if(!f) fail(p);
    while(fgets(line,sizeof(line),f)) {
        type=strstr(line,"P Near"); if(!type) type=strstr(line,"P Far");
        modern=type!=NULL;
        if(!type) type=strstr(line,"N PROC");
        if(!type) type=strstr(line,"F PROC");
        length=strstr(line,"Length");
        if(!type || !length || (!strstr(line,"Public") && !strstr(line,"Global"))) continue;
        length=strchr(length,'='); if(!length) fail("Missing procedure length");
        if(sscanf(line,"%255s",name)!=1 || sscanf(length+1,"%x",&len)!=1) fail("Procedure syntax");
        type+=modern?(type[2]=='N'?6:5):6;
        if(sscanf(type," %x %255s",&offset,segment)!=2) fail("Procedure address syntax");
        (void)offset; (void)segment;
        found=count;
        for(i=0;i<count;i++) if(!_stricmp(name,symbols[i].name) &&
            ((directory==0 && (symbols[i].unit==0 || symbols[i].unit==2)) ||
             (directory==1 && symbols[i].unit==1) || (directory==2 && symbols[i].unit==3))) {
            if(found!=count) fail("Ambiguous public procedure across linked units");
            found=i;
        }
        if(found==count) continue; /* Listing may declare an unlinked resource. */
        if(++symbols[found].definitions>1) fail("Multiple listing definitions for a public procedure");
        symbols[found].length=len;
        if(strlen(relative)>=sizeof(symbols[found].listing)) fail("Listing path overflow");
        strcpy(symbols[found].listing,relative);
    }
    fclose(f);
}
static void lists(const char *root,const char *rel,int dir) {
    WIN32_FIND_DATAA d; HANDLE h; char p[2048],sub[512];
    snprintf(sub,sizeof(sub),"%s/*.lst",rel); path(p,sizeof(p),root,sub);
    h=FindFirstFileA(p,&d); if(h==INVALID_HANDLE_VALUE) fail(p);
    do {
        snprintf(sub,sizeof(sub),"%s/%s",rel,d.cFileName); listing(root,sub,dir);
    } while(FindNextFileA(h,&d));
    if(GetLastError()!=ERROR_NO_MORE_FILES) fail("Listing enumeration failed");
    FindClose(h);
}
int main(int argc,char **argv) {
    FILE *f; unsigned i,n[4]={0},proc[4]={0},unique[4]={0},j; int duplicate;
    if(argc!=4) { fputs("Usage: symbol_inventory build-directory target-directory output.csv\n",stderr); return 2; }
    verify(argv[1],argv[2],"IO.SYS"); verify(argv[1],argv[2],"MSDOS.SYS"); verify(argv[1],argv[2],"COMMAND.COM");
    for(i=0;i<4;i++) readmap(argv[1],(int)i);
    lists(argv[1],"bios",0); lists(argv[1],"dos",1); lists(argv[1],"cmd/command",2);
    f=fopen(argv[3],"wb"); if(!f) fail(argv[3]);
    fputs("component,linked_unit,public_symbol,segment,offset,kind,listing,procedure_length,status\n",f);
    for(i=0;i<count;i++) {
        SYMBOL *s=symbols+i; n[s->unit]++; duplicate=0;
        for(j=0;j<i;j++) if(symbols[j].unit==s->unit && symbols[j].seg==s->seg && symbols[j].off==s->off) duplicate=1;
        if(!duplicate) unique[s->unit]++;
        if(s->definitions) proc[s->unit]++;
        fprintf(f,"%s,%s,%s,%04X,%04X,%s,%s,%u,whole_image_exact\n",
            s->unit==3?"COMMAND.COM":"IO.SYS",units[s->unit],s->name,s->seg,s->off,
            s->definitions?"declared_public_procedure":"other_public_name",s->listing,s->length);
    }
    if(fclose(f)) fail("Inventory close");
    for(i=0;i<4;i++) printf("%s: %u public names, %u distinct segment:offset pairs, %u declared public procedures\n",units[i],n[i],unique[i],proc[i]);
    puts("Original target function total unknown. Private procedures and label-only routines are not counted as public procedures.");
    return 0;
}
