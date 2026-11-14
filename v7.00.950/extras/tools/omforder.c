/* Preserve independent OMF fixups while serializing them in C procedure order. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct { char name[256]; unsigned seg,offset; } SYMBOL;
typedef struct { unsigned owner,address,ordinal; size_t at,size; } FIXUP;
static SYMBOL symbols[4096];
static unsigned symbol_count,starts[4096],start_count,code_segment;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static unsigned word(const unsigned char *p) { return p[0]+256u*p[1]; }
static unsigned index_value(const unsigned char *d,size_t n,size_t *p) {
    unsigned v;
    if(*p>=n) fail("Missing OMF index");
    v=d[(*p)++];
    if(v&128) { if(*p>=n) fail("Truncated OMF index"); v=((v&127)<<8)|d[(*p)++]; }
    return v;
}
static void get_name(const unsigned char *d,size_t n,size_t *p,char *s) {
    unsigned len;
    if(*p>=n) fail("Missing OMF name");
    len=d[(*p)++]; if(len>n-*p) fail("Truncated OMF name");
    memcpy(s,d+*p,len); s[len]=0; *p+=len;
}
static int same_name(const char *a,const char *b) {
    while(*a && *b) if(toupper((unsigned char)*a++)!=toupper((unsigned char)*b++)) return 0;
    return *a==*b;
}
static SYMBOL *lookup(const char *name) {
    unsigned i;
    for(i=0;i<symbol_count;i++) if(same_name(symbols[i].name,name)) return symbols+i;
    fprintf(stderr,"Missing public symbol: %s\n",name); exit(1);
}
static void add_start(SYMBOL *s) {
    unsigned i;
    if(!s->seg || (start_count && code_segment!=s->seg)) fail("Mixed procedure segments");
    for(i=0;i<start_count;i++) if(starts[i]==s->offset) return;
    if(start_count==4096) fail("Too many procedures");
    starts[start_count++]=s->offset; code_segment=s->seg;
}
static size_t record_end(const unsigned char *d,size_t n,size_t p) {
    size_t end,i; unsigned sum=0;
    if(n-p<3) fail("Truncated OMF record");
    end=p+3+word(d+p+1);
    if(end<=p+3 || end>n) fail("OMF record extent");
    for(i=p;i<end;i++) sum+=d[i];
    if(sum&255) fail("OMF record checksum");
    return end;
}
static int order(const void *a,const void *b) {
    const FIXUP *x=a,*y=b;
    if(x->owner!=y->owner) return x->owner<y->owner?-1:1;
    if(x->address!=y->address) return x->address>y->address?-1:1;
    return x->ordinal<y->ordinal?-1:x->ordinal>y->ordinal;
}
static void write_bytes(FILE *f,const unsigned char *d,size_t n) {
    if(fwrite(d,1,n,f)!=n) fail("Output write");
}
typedef struct {
    unsigned address,width,size,ordinal;
    unsigned char data[16];
} OPERAND;
static int descending(const void *a,const void *b) {
    const OPERAND *x=a,*y=b;
    if(x->address!=y->address) return x->address>y->address?-1:1;
    return x->ordinal<y->ordinal?-1:x->ordinal>y->ordinal;
}
static void emit_record(FILE *f,unsigned type,const unsigned char *d,size_t n) {
    unsigned char h[3],check; unsigned sum; size_t i;
    if(n>65534) fail("OMF record overflow");
    h[0]=(unsigned char)type; h[1]=(unsigned char)(n+1); h[2]=(unsigned char)((n+1)>>8);
    sum=h[0]+h[1]+h[2]; for(i=0;i<n;i++) sum+=d[i];
    check=(unsigned char)(0u-sum);
    write_bytes(f,h,3); write_bytes(f,d,n); write_bytes(f,&check,1);
}
static unsigned put_index(unsigned char *d,unsigned v) {
    if(v>32767) fail("OMF index overflow");
    if(v<128) { d[0]=(unsigned char)v; return 1; }
    d[0]=(unsigned char)(128|(v>>8)); d[1]=(unsigned char)v; return 2;
}
static void reblock(const unsigned char *raw,size_t size,const char *recipe,const char *output) {
    unsigned char *code=calloc(65536,1),*present=calloc(65536,1),*remove=calloc(size,1);
    unsigned char *buffer=malloc(65535); OPERAND *ops=calloc(16384,sizeof(*ops));
    unsigned cuts[128]={0},bounds[512]={0},nc=1,nb=1,seg=0,last_seg=0,last_off=0;
    unsigned length=0,count=0,i,j,lo,hi,cut,prefix,emitted=0;
    size_t p,end,q,n,first=size; FILE *f; char line[512],kind[32],sym[256],extra[8];
    if(!code || !present || !remove || !buffer || !ops) fail("Allocation");
    f=fopen(recipe,"r"); if(!f) fail(recipe);
    while(fgets(line,sizeof(line),f)) {
        long addend=0; int fields;
        char *s=line; SYMBOL *symbol;
        while(isspace((unsigned char)*s)) s++;
        if(!*s || *s==';') continue;
        fields=sscanf(s,"%31s %255s %ld %7s",kind,sym,&addend,extra);
        if(!strcmp(kind,"anchor") && fields==2 && !seg) {
            symbol=lookup(sym); seg=symbol->seg;
            if(!seg || symbol->offset) fail("Layout anchor must start a segment");
        } else if(!strcmp(kind,"cut") && fields==3 && seg) {
            symbol=lookup(sym);
            if(symbol->seg!=seg || addend<0 || addend>65535 || nc==127) fail("Invalid symbolic cut");
            cut=symbol->offset+(unsigned)addend;
            if(cut>65535 || cut<=cuts[nc-1]) fail("Unordered symbolic cuts");
            cuts[nc++]=cut;
        } else fail("Invalid OMF layout recipe");
    }
    fclose(f); if(!seg) fail("Missing layout anchor");
    for(p=0;p<size;p=end) {
        const unsigned char *d=raw+p+3;
        end=record_end(raw,size,p); n=end-p-4;
        if(raw[p]==0xa0) {
            q=0; last_seg=index_value(d,n,&q);
            if(n-q<2) fail("LEDATA offset");
            last_off=word(d+q); q+=2;
            if(last_seg!=seg) continue;
            if(n-q>65536u-last_off) fail("Code segment overflow");
            for(i=0;i<n-q;i++) {
                if(present[last_off+i]) fail("Overlapping code records");
                present[last_off+i]=1; code[last_off+i]=d[q+i];
            }
            if(last_off+n-q>length) length=(unsigned)(last_off+n-q);
            remove[p]=1; if(first==size) first=p;
        } else if(raw[p]==0x9c && last_seg==seg) {
            remove[p]=1; q=0;
            while(q<n) {
                static const unsigned widths[]={1,2,2,4,1,2};
                size_t start=q; unsigned first_byte,fd,frame,location_type; OPERAND *op;
                if(n-q<3 || count==16384) fail("FIXUPP extent");
                op=ops+count; op->ordinal=count++;
                first_byte=d[q]; fd=d[q+2];
                op->address=last_off+((first_byte&3)<<8)+d[q+1]; q+=3;
                location_type=(first_byte>>2)&15;
                if(!(first_byte&128) || (fd&0x88) || location_type>=6) fail("Unsupported fixup encoding");
                frame=(fd>>4)&7; if(frame==3 || (fd&3)==3) fail("Unsupported fixup operand");
                if(frame<=2) index_value(d,n,&q);
                index_value(d,n,&q);
                if(!(fd&4)) { if(n-q<2) fail("Fixup displacement"); q+=2; }
                op->size=(unsigned)(q-start); op->width=widths[location_type];
                if(op->size>sizeof(op->data)) fail("Fixup too large");
                memcpy(op->data,d+start,op->size);
            }
        }
    }
    if(first==size || length<=cuts[nc-1]) fail("Empty or invalid layout extent");
    for(i=0;i<length;i++) if(!present[i]) fail("Gap in source code segment");
    for(i=0;i<count;i++) if(ops[i].address+ops[i].width>length) fail("Fixup outside code");
    cuts[nc++]=length;
    for(i=1;i<nc;i++) {
        lo=cuts[i-1]; hi=cuts[i];
        if(hi-lo>1020) {
            prefix=hi-1020;
            for(j=0;j<count;j++) if(ops[j].address<prefix && prefix<ops[j].address+ops[j].width)
                prefix=ops[j].address+ops[j].width;
            for(j=0;j<count;j++) {
                unsigned t=(ops[j].data[0]>>2)&15;
                if(lo<=ops[j].address && ops[j].address<prefix && (t==2 || t==3))
                    fail("Cannot split loader relocation group");
            }
            while(prefix-lo>1020) {
                cut=lo+1020;
                for(j=0;j<count;j++) if(ops[j].address<cut && cut<ops[j].address+ops[j].width)
                    cut=ops[j].address;
                if(cut<=lo || nb==511) fail("Invalid expanded boundary");
                bounds[nb++]=lo=cut;
            }
            if(bounds[nb-1]!=prefix) {
                if(nb==511) fail("Too many boundaries");
                bounds[nb++]=prefix;
            }
        }
        if(nb==511) fail("Too many boundaries");
        bounds[nb++]=hi;
    }
    qsort(ops,count,sizeof(*ops),descending);
    f=fopen(output,"wb"); if(!f) fail(output);
    for(p=0;p<size;p=end) {
        end=record_end(raw,size,p);
        if(p==first) for(i=1;i<nb;i++) {
            unsigned used,location;
            lo=bounds[i-1]; hi=bounds[i];
            if(hi<=lo || hi-lo>1020) fail("Invalid data record size");
            used=put_index(buffer,seg); buffer[used++]=(unsigned char)lo;
            buffer[used++]=(unsigned char)(lo>>8);
            memcpy(buffer+used,code+lo,hi-lo); used+=hi-lo;
            emit_record(f,0xa0,buffer,used); used=0;
            for(j=0;j<count;j++) if(lo<=ops[j].address && ops[j].address<hi) {
                if(ops[j].address+ops[j].width>hi) fail("Boundary splits a fixup");
                if(used+ops[j].size>65534) fail("FIXUPP record overflow");
                location=ops[j].address-lo;
                memcpy(buffer+used,ops[j].data,ops[j].size);
                buffer[used]=(unsigned char)((ops[j].data[0]&252)|(location>>8));
                buffer[used+1]=(unsigned char)location;
                if(lo+((buffer[used]&3)<<8)+buffer[used+1]!=ops[j].address ||
                   memcmp(buffer+used+2,ops[j].data+2,ops[j].size-2)) fail("Fixup operand changed");
                used+=ops[j].size; emitted++;
            }
            if(used) emit_record(f,0x9c,buffer,used);
        }
        if(!remove[p]) write_bytes(f,raw+p,end-p);
    }
    if(emitted!=count) fail("Fixup count changed");
    if(fclose(f)) fail("Output close");
    printf("OMF layout: %u code bytes, %u fixups, %u data records; code/operands unchanged\n",length,count,nb-1);
    free(code); free(present); free(remove); free(buffer); free(ops);
}
int main(int argc,char **argv) {
    unsigned char *raw,*out; FILE *f; long length; size_t size,p,end,q,n;
    unsigned group,seg,offset,last_seg=0,last_offset=0,changed=0,total=0,i;
    int whole=0,layout=0;
    if(argc<4) {
        fprintf(stderr,"Usage: omforder input.obj output.obj listing [--whole | --data symbol ...]\n"
                       "       omforder input.obj output.obj --layout recipe\n");
        return 2;
    }
    if(!strcmp(argv[1],argv[2])) fail("Use a distinct output file");
    if(argc==5 && !strcmp(argv[3],"--layout")) layout=1;
    else if(argc==5 && !strcmp(argv[4],"--whole")) whole=1;
    else if(argc>4 && (argc<6 || strcmp(argv[4],"--data"))) fail("Invalid mode");
    f=fopen(argv[1],"rb"); if(!f) fail(argv[1]);
    if(fseek(f,0,SEEK_END) || (length=ftell(f))<=0) fail("Object size");
    rewind(f); size=(size_t)length; raw=malloc(size); out=malloc(size);
    if(!raw || !out || fread(raw,1,size,f)!=size) fail("Object read");
    fclose(f); memcpy(out,raw,size);
    for(p=0;p<size;p=end) {
        const unsigned char *d=raw+p+3;
        end=record_end(raw,size,p); n=end-p-4;
        if(raw[p]!=0x90) continue;
        q=0; group=index_value(d,n,&q); seg=index_value(d,n,&q);
        if(!group && !seg) { if(n-q<2) fail("Public frame"); q+=2; }
        while(q<n) {
            SYMBOL *s;
            if(symbol_count==4096) fail("Too many publics");
            s=symbols+symbol_count++; get_name(d,n,&q,s->name);
            if(n-q<2) fail("Public offset");
            s->offset=word(d+q); s->seg=seg; q+=2; index_value(d,n,&q);
        }
    }
    if(layout) {
        reblock(raw,size,argv[4],argv[2]); free(raw); free(out); return 0;
    }
    if(argc>=6) {
        for(i=5;i<(unsigned)argc;i++) add_start(lookup(argv[i]));
    } else {
        char line[2048],previous[256];
        f=fopen(argv[3],"r"); if(!f) fail(argv[3]);
        while(fgets(line,sizeof(line),f)) {
            char *s=line,*token; size_t k;
            while(isspace((unsigned char)*s)) s++;
            for(k=0;k<4 && isxdigit((unsigned char)s[k]);k++) {}
            if(k!=4 || !isspace((unsigned char)s[4])) continue;
            offset=(unsigned)strtoul(s,NULL,16); previous[0]=0;
            token=strtok(s+4," \t\r\n");
            while(token) {
                if(token[0]==';') break;
                if(same_name(token,"proc")) {
                    SYMBOL *sym=lookup(previous);
                    if(sym->offset!=offset) fail("Listing/public offset mismatch");
                    add_start(sym); break;
                }
                if(strlen(token)>=sizeof(previous)) fail("Listing token too long");
                strcpy(previous,token); token=strtok(NULL," \t\r\n");
            }
        }
        fclose(f);
    }
    if(!start_count) fail("No source procedures");
    if(whole) { starts[0]=0; start_count=1; }
    for(p=0;p<size;p=end) {
        const unsigned char *d=raw+p+3; FIXUP entries[16384]; unsigned count=0;
        end=record_end(raw,size,p); n=end-p-4;
        if(raw[p]==0xa0) {
            q=0; last_seg=index_value(d,n,&q);
            if(n-q<2) fail("LEDATA offset");
            last_offset=word(d+q);
        }
        if(raw[p]!=0x9c || last_seg!=code_segment) continue;
        q=0;
        while(q<n) {
            FIXUP *e; unsigned first,fd,frame; int found=0;
            if(count==16384 || n-q<3) fail("FIXUPP extent");
            e=entries+count; e->at=q; e->ordinal=count++;
            first=d[q]; e->address=last_offset+((first&3)<<8)+d[q+1]; fd=d[q+2]; q+=3;
            if(!(first&128) || (fd&0x88)) fail("Threaded FIXUPP unsupported");
            frame=(fd>>4)&7; if(frame==3 || (fd&3)==3) fail("Unsupported FIXUPP operand");
            if(frame<=2) index_value(d,n,&q);
            index_value(d,n,&q);
            if(!(fd&4)) { if(n-q<2) fail("FIXUPP displacement"); q+=2; }
            e->size=q-e->at; e->owner=0;
            for(i=0;i<start_count;i++) if(starts[i]<=e->address && (!found || starts[i]>e->owner)) {
                e->owner=starts[i]; found=1;
            }
            if(!found) fail("FIXUPP before procedure");
        }
        qsort(entries,count,sizeof(*entries),order); q=0;
        for(i=0;i<count;i++) {
            memcpy(out+p+3+q,d+entries[i].at,entries[i].size); q+=entries[i].size;
        }
        if(q!=n) fail("FIXUPP size changed");
        /* Reordering preserves the checksum and every independent operand. */
        if(memcmp(out+p+3,d,n)) changed++;
        total+=count;
    }
    f=fopen(argv[2],"wb"); if(!f) fail(argv[2]);
    write_bytes(f,out,size); if(fclose(f)) fail("Output close");
    printf("OMF fixup order: %u operands, %u records changed; code/data unchanged\n",total,changed);
    free(raw); free(out); return 0;
}
