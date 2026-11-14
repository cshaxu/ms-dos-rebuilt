/* Arrange BUILDMSG classes into a DOS 7 indexed resource assembly unit. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct {
    char name[80];
    char *id, *message;
} MESSAGE;
typedef struct { MESSAGE item[300]; unsigned count; } CLASS;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static char *copy(const char *p, size_t n) {
    char *s=malloc(n+1); if (!s) fail("Allocation");
    memcpy(s,p,n); s[n]=0; return s;
}
static char *read_text(const char *name) {
    FILE *f=fopen(name,"rb"); long n; char *s;
    if (!f) fail(name);
    if (fseek(f,0,SEEK_END) || (n=ftell(f))<0) fail("Input size");
    rewind(f); s=malloc((size_t)n+1); if (!s) fail("Allocation");
    if (fread(s,1,(size_t)n,f)!=(size_t)n) fail("Input read");
    s[n]=0; fclose(f); return s;
}
static char *line_end(char *p) { char *q=strchr(p,'\n'); return q?q+1:p+strlen(p); }
static MESSAGE *find(CLASS *c, const char *name) {
    unsigned i;
    for (i=0;i<c->count;i++) if (!strcmp(c->item[i].name,name)) return &c->item[i];
    fail("Message without index"); return NULL;
}
static void load(CLASS *c, const char *file, char number) {
    char prefix[16], label[100], *data=read_text(file), *p=data;
    snprintf(prefix,sizeof(prefix),"$M_%c_",number);
    while (*p) {
        if (!strncmp(p,prefix,strlen(prefix)) && sscanf(p,"%99s",label)==1) {
            char *end=strstr(label,"_STRUC");
            if (end && !strcmp(end,"_STRUC")) {
                MESSAGE *m; char *q=line_end(p), *r=line_end(q);
                if (c->count==300 || !strstr(q,"$M_ID")) fail("Invalid index");
                *end=0; m=&c->item[c->count++];
                if (strlen(label)>=sizeof(m->name)) fail("Message label too long");
                strcpy(m->name,label); m->id=copy(p,(size_t)(r-p)); m->message=NULL;
            }
        }
        p=line_end(p);
    }
    p=data;
    while (*p) {
        if (!strncmp(p,prefix,strlen(prefix)) && sscanf(p,"%99s",label)==1) {
            char *end=strstr(label,"_MSG");
            if (end && !strcmp(end,"_MSG")) {
                char marker[128], *q; MESSAGE *m;
                *end=0; m=find(c,label);
                if (m->message) fail("Duplicate message");
                snprintf(marker,sizeof(marker),"%s_END LABEL BYTE",label);
                q=strstr(p,marker); if (!q) fail("Unterminated message");
                m->message=copy(p,(size_t)(line_end(q)-p));
                p=line_end(q); continue;
            }
        }
        p=line_end(p);
    }
    free(data);
    if (!c->count) fail("Empty class");
    {
        unsigned i;
        for(i=0;i<c->count;i++) if(!c->item[i].message) fail("Missing message");
        if(number=='1' || number=='2') {
            for(i=0;i<c->count;i++) if(strstr(c->item[i].name,"_FF")) break;
            if(i==c->count) fail("Missing default message");
            { MESSAGE m=c->item[i]; memmove(c->item+1,c->item,i*sizeof(m)); c->item[0]=m; }
        }
    }
}
static void emit(FILE *f, char *text, int messages) {
    char *p=text;
    while(*p) {
        char *end=line_end(p), *q=p; size_t n=(size_t)(end-p);
        int empty=0;
        while(q<end && isspace((unsigned char)*q)) q++;
        if (messages && end-q>=3 && !strncmp(q,"DB",2) &&
            isspace((unsigned char)q[2])) {
            q+=2;
            q+=strspn(q," \t");
            empty=(end-q>=2 && !strncmp(q,"\"\"",2));
        }
        if (!empty) {
            while(n && (p[n-1]=='\r' || p[n-1]=='\n')) n--;
            if(fwrite(p,1,n,f)!=n || fputs("\n",f)==EOF) fail("Output write");
        }
        p=end;
    }
}
int main(int argc,char **argv) {
    CLASS *c; FILE *f; unsigned i,j;
    if(argc!=5) { fprintf(stderr,"Usage: msgindex class1 class2 classf output.asm\n"); return 2; }
    c=calloc(3,sizeof(*c)); if(!c) fail("Allocation");
    load(c,argv[1],'1'); load(c+1,argv[2],'2'); load(c+2,argv[3],'F');
    f=fopen(argv[4],"w"); if(!f) fail(argv[4]);
    fputs("$M_CLASS_ID STRUC\n    $M_CLS_ID DB -1\n    $M_NUM_CLS_MSG DB 0\n$M_CLASS_ID ENDS\n"
          "$M_ID STRUC\n    $M_NUM DW -1\n    $M_TXT_PTR DW ?\n$M_ID ENDS\n"
          "CR EQU 13\nLF EQU 10\nTBLSEG SEGMENT BYTE PUBLIC 'DATA'\n",f);
    for(i=0;i<3;i++) {
        fprintf(f,"    $M_CLASS_ID <%u,%u>\n",i+1,c[i].count);
        for(j=0;j<c[i].count;j++) emit(f,c[i].item[j].id,0);
    }
    for(i=0;i<3;i++) for(j=0;j<c[i].count;j++) emit(f,c[i].item[j].message,1);
    fputs("TBLSEG ENDS\nEND\n",f); if(fclose(f)) fail("Output close");
    printf("Resource classes: %u, %u, %u messages\n",c[0].count,c[1].count,c[2].count);
    for(i=0;i<3;i++) for(j=0;j<c[i].count;j++) { free(c[i].item[j].id); free(c[i].item[j].message); }
    free(c); return 0;
}
