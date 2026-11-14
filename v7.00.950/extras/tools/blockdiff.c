/* Exact, order-preserving binary anchors. This does not measure source recovery. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#define SEED 32
typedef struct { unsigned char *p; size_t n; } IMAGE;
typedef struct { uint64_t h; size_t at; } KEY;
typedef struct { size_t a,b,prev; } MATCH;
typedef struct { size_t a,b,n; } RUN;
static void fail(const char *s) { fprintf(stderr,"%s\n",s); exit(1); }
static unsigned word(const unsigned char *p) { return p[0]+256u*p[1]; }
static IMAGE read_image(const char *path) {
    IMAGE r; long n; FILE *f=fopen(path,"rb");
    if(!f || fseek(f,0,SEEK_END) || (n=ftell(f))<0) fail("read size");
    rewind(f); r.n=(size_t)n; r.p=malloc(r.n?r.n:1);
    if(!r.p || fread(r.p,1,r.n,f)!=r.n) fail("read bytes");
    fclose(f); return r;
}
static uint64_t hash(const unsigned char *p) {
    uint64_t h=14695981039346656037ULL; unsigned i;
    for(i=0;i<SEED;i++) { h^=p[i]; h*=1099511628211ULL; }
    return h;
}
static int order(const void *x,const void *y) {
    const KEY *a=x,*b=y;
    return a->h<b->h?-1:a->h>b->h?1:0;
}
static void inspect(IMAGE a) {
    size_t i;
    printf("size=%lu\n",(unsigned long)a.n);
    if(a.n>=32 && word(a.p)==0x5a4d)
        printf("MZ header=%u entry=%04x:%04x relocations=%u declared=%lu\n",
            word(a.p+8)*16,word(a.p+22),word(a.p+20),word(a.p+6),
            (unsigned long)((word(a.p+4)-1)*512u+(word(a.p+2)?word(a.p+2):512u)));
    for(i=0;i+8<=a.n;i++) {
        if(!memcmp(a.p+i,"IOSYSMSG",8) && i+10<=a.n)
            printf("IOSYSMSG at=%lu resource=%u\n",(unsigned long)i,word(a.p+i+8));
        if(!memcmp(a.p+i,"NSCO",4)) printf("NSCO at=%lu\n",(unsigned long)i);
        if(!memcmp(a.p+i,"MPADMPAD",8) && (i<4 || memcmp(a.p+i-4,"MPAD",4))) {
            size_t j=i; while(j+4<=a.n && !memcmp(a.p+j,"MPAD",4)) j+=4;
            printf("MPAD at=%lu bytes=%lu\n",(unsigned long)i,(unsigned long)(j-i));
        }
    }
}
int main(int argc,char **argv) {
    IMAGE af,bf,a,b; KEY *keys; MATCH *m; RUN *runs;
    size_t an,bn,i,j,k,lo,hi,n=0,len=0,nr=0,total=0,ao=0,bo=0;
    size_t *tails,*chain;
    if(argc!=3 && argc!=7) fail("usage: blockdiff old new [old-offset old-length new-offset new-length]");
    af=read_image(argv[1]); bf=read_image(argv[2]); a=af; b=bf;
    if(argc==3) { puts("OLD"); inspect(a); puts("NEW"); inspect(b); }
    if(argc==7) {
        ao=strtoul(argv[3],0,0); a.n=strtoul(argv[4],0,0);
        bo=strtoul(argv[5],0,0); b.n=strtoul(argv[6],0,0);
        if(ao>af.n || a.n>af.n-ao || bo>bf.n || b.n>bf.n-bo) fail("slice bounds");
        a.p+=ao; b.p+=bo;
    }
    if(a.n<SEED || b.n<SEED) fail("slice too small");
    an=a.n-SEED+1; bn=b.n-SEED+1;
    keys=malloc(an*sizeof(*keys)); m=malloc(bn*sizeof(*m));
    tails=malloc(bn*sizeof(*tails)); chain=malloc(bn*sizeof(*chain)); runs=calloc(bn,sizeof(*runs));
    if(!keys||!m||!tails||!chain||!runs) fail("allocation");
    for(i=0;i<an;i++) { keys[i].h=hash(a.p+i); keys[i].at=i; }
    qsort(keys,an,sizeof(*keys),order);
    for(i=0;i<bn;i++) {
        uint64_t h=hash(b.p+i);
        lo=0; hi=an;
        while(lo<hi) { j=(lo+hi)/2; if(keys[j].h<h) lo=j+1; else hi=j; }
        if(lo==an || keys[lo].h!=h || (lo+1<an && keys[lo+1].h==h)) continue;
        if(memcmp(a.p+keys[lo].at,b.p+i,SEED)) continue;
        m[n].a=keys[lo].at; m[n].b=i;
        lo=0; hi=len;
        while(lo<hi) { j=(lo+hi)/2; if(m[tails[j]].a<m[n].a) lo=j+1; else hi=j; }
        m[n].prev=lo?tails[lo-1]:(size_t)-1; tails[lo]=n;
        if(lo==len) len++;
        n++;
    }
    if(len) {
        k=tails[len-1]; for(i=len;i>0;i--) { chain[i-1]=k; k=m[k].prev; }
        for(i=0;i<len;i++) {
            MATCH x=m[chain[i]];
            if(nr && x.a-runs[nr-1].a==x.b-runs[nr-1].b && x.a<=runs[nr-1].a+runs[nr-1].n) {
                runs[nr-1].n=x.a+SEED-runs[nr-1].a;
            } else if(!nr || (x.a>=runs[nr-1].a+runs[nr-1].n && x.b>=runs[nr-1].b+runs[nr-1].n)) {
                runs[nr].a=x.a; runs[nr].b=x.b; runs[nr++].n=SEED;
            }
        }
        for(i=0;i<nr;i++) {
            size_t amin=i?runs[i-1].a+runs[i-1].n:0, bmin=i?runs[i-1].b+runs[i-1].n:0;
            size_t amax=i+1<nr?runs[i+1].a:a.n, bmax=i+1<nr?runs[i+1].b:b.n;
            while(runs[i].a>amin && runs[i].b>bmin && a.p[runs[i].a-1]==b.p[runs[i].b-1]) {
                runs[i].a--; runs[i].b--; runs[i].n++;
            }
            while(runs[i].a+runs[i].n<amax && runs[i].b+runs[i].n<bmax &&
                  a.p[runs[i].a+runs[i].n]==b.p[runs[i].b+runs[i].n]) runs[i].n++;
            if(memcmp(a.p+runs[i].a,b.p+runs[i].b,runs[i].n)) fail("run mismatch");
            total+=runs[i].n;
            printf("RUN %lu %lu %lu\n",(unsigned long)(ao+runs[i].a),(unsigned long)(bo+runs[i].b),(unsigned long)runs[i].n);
        }
    }
    printf("SUMMARY old=%lu new=%lu matched=%lu old_unmatched=%lu new_unmatched=%lu runs=%lu target_coverage=%.2f%%\n",
        (unsigned long)a.n,(unsigned long)b.n,(unsigned long)total,(unsigned long)(a.n-total),
        (unsigned long)(b.n-total),(unsigned long)nr,100.0*total/b.n);
    return 0;
}
