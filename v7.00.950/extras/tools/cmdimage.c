/* Package linked COMMAND code and message classes in a DOS 7 MZ image. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

typedef struct { unsigned char *data; size_t size; } IMAGE;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static unsigned word(const unsigned char *p) { return p[0]+256u*p[1]; }
static void putword(unsigned char *p,size_t n) {
    if(n>65535) fail("Word overflow");
    p[0]=(unsigned char)n; p[1]=(unsigned char)(n>>8);
}
static IMAGE read_image(const char *name) {
    IMAGE b; long n; FILE *f=fopen(name,"rb");
    if(!f) fail(name);
    if(fseek(f,0,SEEK_END) || (n=ftell(f))<0) fail("Input size");
    rewind(f); b.size=(size_t)n; b.data=malloc(b.size?b.size:1);
    if(!b.data || fread(b.data,1,b.size,f)!=b.size) fail("Input read");
    fclose(f); return b;
}
static IMAGE load_image(IMAGE b) {
    IMAGE result; size_t header,declared;
    if(b.size<64 || word(b.data)!=0x5a4d || !word(b.data+4)) fail("Invalid MZ");
    declared=(word(b.data+4)-1)*512u+(word(b.data+2)?word(b.data+2):512u);
    header=word(b.data+8)*16u;
    if(declared!=b.size || header<64 || header>b.size || word(b.data+6))
        fail("Invalid MZ extent or relocation");
    result.data=b.data+header; result.size=b.size-header; return result;
}
static int same_name(const char *a,const char *b) {
    while(*a && *b) {
        if(toupper((unsigned char)*a++)!=toupper((unsigned char)*b++)) return 0;
    }
    return *a==*b;
}
static size_t symbol(const char *map,const char *wanted,int offset_only) {
    char line[512],name[128]; unsigned seg,off; FILE *f=fopen(map,"r");
    if(!f) fail(map);
    while(fgets(line,sizeof(line),f)) {
        if(sscanf(line," %x:%x %127s",&seg,&off,name)==3 && same_name(name,wanted)) {
            fclose(f); return (offset_only?0:seg*16u)+off;
        }
    }
    fprintf(stderr,"Missing symbol: %s\n",wanted); exit(1);
}
static IMAGE slice(IMAGE b,size_t first,size_t end) {
    IMAGE r;
    if(first>=end || end>b.size) fail("Invalid resource extent");
    r.data=b.data+first; r.size=end-first; return r;
}
static size_t paragraph(size_t n) { return (n+15u)&~(size_t)15; }

/* Each text pointer is relative to the beginning of its four-byte record. */
static void check_class(IMAGE b,size_t at,unsigned id,size_t text_start) {
    unsigned count,i; size_t record,text;
    if(at+2>b.size || b.data[at]!=id) fail("Invalid message class");
    count=b.data[at+1];
    if(!count || at+2+4u*count>b.size) fail("Invalid message table");
    for(i=0;i<count;i++) {
        record=at+2+4u*i;
        text=record+word(b.data+record+2);
        if(text<text_start || text>=b.size || text+1+b.data[text]>b.size)
            fail("Invalid message text extent");
    }
}
static size_t append_resource(unsigned char *out,size_t pos,IMAGE b,
                              const size_t *offsets,unsigned count,unsigned id) {
    unsigned i; size_t size=17+2u*count+b.size;
    if(size>65535) fail("Resource size overflow");
    putword(out+pos,size); putword(out+pos+2,size);
    memcpy(out+pos+4,"ENU",3); putword(out+pos+7,1);
    putword(out+pos+9,437); memcpy(out+pos+11,"NSCO",4);
    out[pos+15]=(unsigned char)id; out[pos+16]=(unsigned char)count;
    for(i=0;i<count;i++) putword(out+pos+17+2u*i,2u*count+offsets[i]-2u*i);
    memcpy(out+pos+17+2u*count,b.data,b.size);
    return paragraph(pos+size);
}
int main(int argc,char **argv) {
    IMAGE files[4],code,primary,init,resident;
    size_t offsets[3],zero=0,first,last,header,total,pos,table_end;
    unsigned char *out; unsigned i; FILE *f;
    if(argc!=9) {
        fprintf(stderr,"Usage: cmdimage command.exe command.map res0.exe iniclass.exe iniclass.map resclass.exe resclass.map output\n");
        return 2;
    }
    files[0]=read_image(argv[1]); files[1]=read_image(argv[3]);
    files[2]=read_image(argv[4]); files[3]=read_image(argv[6]);
    code=load_image(files[0]); primary=load_image(files[1]);
    init=load_image(files[2]); resident=load_image(files[3]);
    if(symbol(argv[2],"TranSpaceEnd",1)+0x1400+0xff+15>65535)
        fail("Transient startup workspace overflow");
    offsets[0]=0;
    for(i=0;i<3;i++) {
        if(offsets[i]+2>primary.size) fail("Primary class extent");
        table_end=offsets[i]+2+4u*primary.data[offsets[i]+1];
        if(i<2) offsets[i+1]=table_end;
    }
    for(i=0;i<3;i++) check_class(primary,offsets[i],i+1,table_end);
    first=symbol(argv[5],"InitMsgClass",0); last=symbol(argv[5],"Help16Msg",0);
    if(last>=init.size) fail("Initialization final message extent");
    init=slice(init,first,last+1+init.data[last]);
    check_class(init,0,5,2+4u*init.data[1]);
    resident=slice(resident,symbol(argv[7],"ResMsgClass",0),
                   symbol(argv[7],"ResidentClassEnd",0));
    check_class(resident,0,6,2+4u*resident.data[1]);
    header=paragraph(64+23+primary.size);
    header=paragraph(header+19+init.size);
    header=paragraph(header+19+resident.size);
    total=header+code.size; out=calloc(total,1); if(!out) fail("Allocation");
    memcpy(out,files[0].data,64);
    pos=append_resource(out,64,primary,offsets,3,0);
    pos=append_resource(out,pos,init,&zero,1,5);
    pos=append_resource(out,pos,resident,&zero,1,6);
    if(pos!=header) fail("Resource layout mismatch");
    memcpy(out+header,code.data,code.size);
    putword(out+2,total%512); putword(out+4,(total+511)/512);
    putword(out+8,header/16); putword(out+18,0);
    f=fopen(argv[8],"wb"); if(!f) fail(argv[8]);
    if(fwrite(out,1,total,f)!=total || fclose(f)) fail("Output write");
    printf("COMMAND image: %lu bytes; linked code at %lu\n",
           (unsigned long)total,(unsigned long)header);
    free(out); for(i=0;i<4;i++) free(files[i].data);
    return 0;
}
