/* Resolve OMF library aliases for the original DOS librarian and linker.
 * Code, data and relocation records are copied without modification.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { char from[256],to[256]; } ALIAS;
static ALIAS aliases[1024];
static unsigned alias_count;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static unsigned word(const unsigned char *p) { return p[0]+256u*p[1]; }
static void name(const unsigned char *data,size_t size,size_t *at,char *out) {
    unsigned n;
    if(*at>=size) fail("Missing OMF name");
    n=data[(*at)++];
    if(n>size-*at) fail("Truncated OMF name");
    memcpy(out,data+*at,n); out[n]=0; *at+=n;
}
static void index_end(const unsigned char *data,size_t size,size_t *at) {
    unsigned n;
    if(*at>=size) fail("Missing OMF index");
    n=data[(*at)++];
    if(n&128) { if(*at>=size) fail("Truncated OMF index"); ++*at; }
}
static const char *resolve(const char *s) {
    unsigned i,depth;
    for(depth=0;depth<=alias_count;depth++) {
        for(i=0;i<alias_count;i++) if(!strcmp(aliases[i].from,s)) break;
        if(i==alias_count) return s;
        s=aliases[i].to;
    }
    fail("Cyclic OMF alias"); return NULL;
}
static void write_bytes(FILE *f,const unsigned char *p,size_t n) {
    if(fwrite(p,1,n,f)!=n) fail("Output write");
}
static void write_record(FILE *f,unsigned type,const unsigned char *data,size_t size) {
    unsigned sum,i; unsigned char head[3],checksum;
    if(size>65534) fail("OMF record too large");
    head[0]=(unsigned char)type; head[1]=(unsigned char)(size+1);
    head[2]=(unsigned char)((size+1)>>8);
    sum=head[0]+head[1]+head[2];
    for(i=0;i<size;i++) sum+=data[i];
    checksum=(unsigned char)(0u-sum);
    write_bytes(f,head,3); write_bytes(f,data,size); write_bytes(f,&checksum,1);
}
static size_t record_end(const unsigned char *data,size_t size,size_t at) {
    size_t end,i; unsigned sum=0;
    if(size-at<3) fail("Truncated OMF header");
    end=at+3+word(data+at+1);
    if(end<=at+3 || end>size) fail("Truncated OMF record");
    for(i=at;i<end;i++) sum+=data[i];
    /* OMF permits a zero checksum byte to mark an unchecked record. */
    if(data[end-1] && (sum&255)) fail("OMF checksum mismatch");
    return end;
}
int main(int argc,char **argv) {
    FILE *f,*obj=NULL,*rsp; unsigned char *raw,*changed;
    long length; size_t size,page,at,end,q,n,start,used; unsigned pass,type,member=0;
    unsigned rewrites=0; char path[1024],a[256],b[256],module[256];
    int startup=0,crt0=0;
    if(argc==4 && !strcmp(argv[3],"--dos-startup")) startup=1;
    else if(argc!=3) {
        fprintf(stderr,"Usage: crtlib source.lib output-directory [--dos-startup]\n");
        return 2;
    }
    f=fopen(argv[1],"rb"); if(!f) fail(argv[1]);
    if(fseek(f,0,SEEK_END) || (length=ftell(f))<4) fail("Library size");
    rewind(f); size=(size_t)length; raw=malloc(size); changed=malloc(65535);
    if(!raw || !changed || fread(raw,1,size,f)!=size) fail("Library read");
    fclose(f);
    if(raw[0]!=0xf0) fail("Not an OMF library");
    page=3+word(raw+1); if(page<16 || page>=size) fail("Library page size");
    if(snprintf(path,sizeof(path),"%s/make.rsp",argv[2])>=(int)sizeof(path)) fail("Output path too long");
    rsp=fopen(path,"w"); if(!rsp) fail(path);
    fputs("crtfix.lib /NOIGNORECASE\ny\n",rsp);
    for(pass=0;pass<2;pass++) {
        at=page;
        while(at<size && raw[at]!=0xf1) {
            end=record_end(raw,size,at); type=raw[at]; n=end-at-4;
            if(!pass && type==0xc6) {
                q=0;
                while(q<n) {
                    unsigned i;
                    name(raw+at+3,n,&q,a); name(raw+at+3,n,&q,b);
                    for(i=0;i<alias_count;i++) if(!strcmp(aliases[i].from,a)) break;
                    if(i<alias_count) { if(strcmp(aliases[i].to,b)) fail("Conflicting aliases"); }
                    else {
                        if(alias_count==1024) fail("Too many aliases");
                        strcpy(aliases[alias_count].from,a); strcpy(aliases[alias_count++].to,b);
                    }
                }
            }
            if(pass) {
                if(!obj) {
                    if(type!=0x80) fail("Missing module header");
                    q=0; name(raw+at+3,n,&q,module);
                    crt0=startup && !strcmp(module,"dos\\crt0.asm");
                    if(snprintf(path,sizeof(path),"%s/m%04u.obj",argv[2],member)>=(int)sizeof(path)) fail("Output path too long");
                    obj=fopen(path,"wb"); if(!obj) fail(path);
                    if(member) fputs(" &\n",rsp);
                    fprintf(rsp,"+m%04u.obj",member++);
                }
                if(type==0x8c) {
                    q=0; used=0;
                    while(q<n) {
                        const char *resolved; size_t len;
                        name(raw+at+3,n,&q,a); start=q; index_end(raw+at+3,n,&q);
                        resolved=resolve(a);
                        /* DOS startup returns through the existing far stub. */
                        if(crt0 && !strcmp(resolved,"__fatalexit")) resolved="__farstub";
                        len=strlen(resolved);
                        if(used+1+len+q-start>65534) fail("Expanded EXTDEF too large");
                        changed[used++]=(unsigned char)len;
                        memcpy(changed+used,resolved,len); used+=len;
                        memcpy(changed+used,raw+at+3+start,q-start); used+=q-start;
                        rewrites+=strcmp(resolved,a)!=0;
                    }
                    if(used==n && !memcmp(changed,raw+at+3,n)) write_bytes(obj,raw+at,end-at);
                    else write_record(obj,type,changed,used);
                } else if(type!=0xc6 &&
                          !(crt0 && type==0x88 && n==4 &&
                            !memcmp(raw+at+3,"\x00\xa8\x14\x13",4)))
                    write_bytes(obj,raw+at,end-at);
            }
            if(type==0x8a || type==0x8b) {
                if(pass) { if(fclose(obj)) fail("Object close"); obj=NULL; }
                end=(end+page-1)/page*page;
            }
            at=end;
        }
        if(at>=size || raw[at]!=0xf1 || obj) fail("Missing library terminator");
    }
    fputs("\n;\n",rsp); if(fclose(rsp)) fail("Response close");
    printf("CRT library: %u members, %u aliases, %u external names resolved\n",member,alias_count,rewrites);
    free(raw); free(changed); return 0;
}
