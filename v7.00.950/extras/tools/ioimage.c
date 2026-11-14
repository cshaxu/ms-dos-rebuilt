/* DOS 7 IO container writer. Inputs are linked images and a logo resource. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct { unsigned char *p; size_t n; } IMAGE;

static void fail(const char *s) { fprintf(stderr, "%s\n", s); exit(1); }
static unsigned word(const unsigned char *p) { return p[0] | ((unsigned)p[1] << 8); }
static void putword(unsigned char *p, unsigned n) {
    if (n > 65535) fail("16-bit field overflow");
    p[0] = (unsigned char)n; p[1] = (unsigned char)(n >> 8);
}
static IMAGE read_image(const char *name) {
    IMAGE b; long size; FILE *f = fopen(name, "rb");
    if (!f) fail(name);
    if (fseek(f, 0, SEEK_END) || (size = ftell(f)) < 0) fail("Input size");
    rewind(f); b.n = (size_t)size; b.p = malloc(b.n ? b.n : 1);
    if (!b.p || fread(b.p, 1, b.n, f) != b.n) fail("Input read");
    fclose(f); return b;
}
static size_t mz_header(IMAGE b) {
    size_t h, declared;
    if (b.n < 32 || word(b.p) != 0x5a4d || !word(b.p+4)) fail("Invalid MZ");
    h = word(b.p+8)*16;
    declared = (word(b.p+4)-1)*512 + (word(b.p+2) ? word(b.p+2) : 512);
    if (word(b.p+6) || h < 32 || h > b.n || declared != b.n) fail("MZ extent/relocations");
    return h;
}
static size_t symbol(const char *map, const char *wanted) {
    char line[512], name[128]; unsigned seg, off; FILE *f = fopen(map, "r");
    if (!f) fail(map);
    while (fgets(line, sizeof(line), f)) {
        if (sscanf(line, " %x:%x %127s", &seg, &off, name) == 3 &&
            !_stricmp(name, wanted)) { fclose(f); return seg*16u + off; }
    }
    fail("Missing map symbol"); return 0;
}
static size_t align_to(size_t n, size_t a) { return (n+a-1) / a * a; }

int main(int argc, char **argv) {
    IMAGE load, bios, kernel, config, logo;
    unsigned char *out, header[512] = {0};
    size_t lh, ch, message, resource, pos, core_end, config_start, total, i;
    FILE *f;
    if (argc != 9) {
        fprintf(stderr, "Usage: ioimage loader.exe bios.bin kernel.bin config.exe logo.mrc bios.map reserve-bytes output\n");
        return 2;
    }
    load=read_image(argv[1]); bios=read_image(argv[2]); kernel=read_image(argv[3]);
    config=read_image(argv[4]); logo=read_image(argv[5]);
    lh=mz_header(load); ch=mz_header(config);
    if (word(load.p+20)!=0x200 || word(load.p+22) || load.n<lh+0x600) fail("Loader entry");
    message=symbol(argv[6],"SI_end");
    if (message>=bios.n || bios.n-message>65535) fail("Message extent");
    resource=bios.n-message;
    {
        char *end; unsigned long reserve=strtoul(argv[7],&end,10);
        if (*end || reserve>65535 || reserve%4) fail("Reserve extent");
        pos=512+1024+bios.n+10+reserve;
        core_end=align_to(pos,16)+kernel.n;
        config_start=align_to(align_to(core_end,16)+logo.n,512);
        total=config_start+config.n-ch;
        out=calloc(total,1); if (!out) fail("Allocation");
        memcpy(header,config.p,32);
        putword(header+2,(unsigned)(total%512));
        putword(header+4,(unsigned)((total+511)/512));
        putword(header+8,(unsigned)(config_start/16));
        memcpy(out,header,512); pos=512;
        memcpy(out+pos,load.p+lh+0x200,1024); pos+=1024;
        memcpy(out+pos,bios.p,bios.n); pos+=bios.n;
        memcpy(out+pos,"IOSYSMSG",8); putword(out+pos+8,(unsigned)resource); pos+=10;
        for (i=0;i<reserve;i+=4) memcpy(out+pos+i,"MPAD",4);
        pos=align_to(pos+reserve,16);
    }
    memcpy(out+pos,kernel.p,kernel.n); pos=align_to(pos+kernel.n,16);
    memcpy(out+pos,logo.p,logo.n);
    memcpy(out+config_start,config.p+ch,config.n-ch);
    f=fopen(argv[8],"wb"); if (!f) fail(argv[8]);
    if (fwrite(out,1,total,f)!=total || fclose(f)) fail("Output write");
    printf("IO image: %lu bytes; configuration at %lu\n",(unsigned long)total,(unsigned long)config_start);
    free(out); free(load.p); free(bios.p); free(kernel.p); free(config.p); free(logo.p);
    return 0;
}
