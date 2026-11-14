/* Extract the three root core files from a FAT12 floppy image. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static unsigned short word(const unsigned char *p)
{
    return (unsigned short)(p[0] | (p[1] << 8));
}

static unsigned long dword(const unsigned char *p)
{
    return word(p) | ((unsigned long)word(p + 2) << 16);
}

int main(int argc, char **argv)
{
    static const char *names[] = { "IO      SYS", "MSDOS   SYS", "COMMAND COM" };
    static const char *outnames[] = { "IO.SYS", "MSDOS.SYS", "COMMAND.COM" };
    unsigned char *image, *entry, *seen;
    unsigned long length, root, data, fatsize, clusterbytes, total, remain, pos;
    unsigned long cat, start, bytes;
    unsigned int sector, reserved, roots, clusters, cluster, next, i, j, found = 0;
    FILE *f;
    char path[1024];
    if (argc != 3) { fprintf(stderr, "usage: fatcore image output-directory\n"); return 2; }
    f = fopen(argv[1], "rb");
    if (!f) { perror(argv[1]); return 2; }
    if (fseek(f, 0, SEEK_END) || ftell(f) < 512 || ftell(f) > 8388608) return 2;
    length = (unsigned long)ftell(f);
    rewind(f);
    image = (unsigned char *)malloc(length);
    if (!image || fread(image, 1, length, f) != length) return 2;
    fclose(f);
    /* El Torito floppy-emulation CDs contain a complete FAT floppy. */
    if (word(image + 11) != 512) {
        start = 0; bytes = 0;
        for (pos = 16 * 2048; pos + 2048 <= length; pos += 2048) {
            if (memcmp(image + pos + 1, "CD001", 5)) return 3;
            if (image[pos] == 255) break;
            if (image[pos] != 0 || memcmp(image + pos + 7, "EL TORITO SPECIFICATION", 23)) continue;
            cat = dword(image + pos + 71) * 2048;
            if (cat + 64 > length || image[cat + 32] != 0x88) return 3;
            switch (image[cat + 33]) {
            case 1: bytes = 1228800; break;
            case 2: bytes = 1474560; break;
            case 3: bytes = 2949120; break;
            default: return 3;
            }
            start = dword(image + cat + 40) * 2048;
            break;
        }
        if (!bytes || start > length || bytes > length - start) return 3;
        printf("El Torito floppy offset=%lu bytes=%lu\n", start, bytes);
        memmove(image, image + start, bytes);
        length = bytes;
    }
    sector = word(image + 11); reserved = word(image + 14); roots = word(image + 17);
    fprintf(stderr, "Image=%lu sector=%u reserved=%u spc=%u fats=%u roots=%u spf=%u signature=%02x%02x\n",
            length, sector, reserved, image[13], image[16], roots, word(image + 22), image[510], image[511]);
    if (sector != 512 || !reserved || !image[13] || image[16] != 2 || !roots ||
        !word(image + 22) || image[510] != 0x55 || image[511] != 0xaa) return 3;
    total = word(image + 19); if (!total) total = dword(image + 32);
    if (total > length / sector) { fprintf(stderr, "Truncated BPB volume\n"); return 3; }
    if (total * sector < length) {
        printf("Trailing bytes outside BPB volume=%lu (not file data)\n", length - total * sector);
        length = total * sector;
    }
    fatsize = (unsigned long)word(image + 22) * sector;
    root = (unsigned long)reserved * sector + 2 * fatsize;
    data = root + (((unsigned long)roots * 32 + sector - 1) / sector) * sector;
    clusterbytes = (unsigned long)image[13] * sector;
    if (data >= length) return 3;
    clusters = (unsigned int)((length - data) / clusterbytes);
    if (!clusters || clusters >= 4085 || (clusters + 2) * 3 / 2 + 1 > fatsize) return 3;
    if (memcmp(image + reserved * sector, image + reserved * sector + fatsize, fatsize)) { fprintf(stderr, "FAT copies differ\n"); return 3; }
    seen = (unsigned char *)malloc(clusters + 2);
    if (!seen) return 2;
    for (i = 0; i < roots; ++i) {
        entry = image + root + i * 32;
        if (!entry[0]) break;
        if (entry[0] == 0xe5 || (entry[11] & 0x18)) continue;
        for (j = 0; j < 3; ++j) if (!memcmp(entry, names[j], 11)) break;
        if (j == 3) continue;
        if (found & (1u << j)) return 3;
        found |= 1u << j;
        remain = dword(entry + 28); cluster = word(entry + 26);
        if (snprintf(path, sizeof(path), "%s/%s", argv[2], outnames[j]) >= (int)sizeof(path)) return 2;
        f = fopen(path, "wb"); if (!f) return 2;
        memset(seen, 0, clusters + 2);
        while (remain) {
            unsigned long n = remain < clusterbytes ? remain : clusterbytes;
            if (cluster < 2 || cluster >= clusters + 2 || seen[cluster]) return 3;
            seen[cluster] = 1;
            pos = data + (cluster - 2) * clusterbytes;
            if (pos + n > length || fwrite(image + pos, 1, n, f) != n) return 3;
            pos = (unsigned long)reserved * sector + cluster + cluster / 2;
            next = word(image + pos);
            cluster = (cluster & 1) ? next >> 4 : next & 0xfff;
            remain -= n;
        }
        if (dword(entry + 28) && cluster < 0xff8) return 3;
        if (fclose(f)) return 2;
        printf("%s %lu bytes date=%04u-%02u-%02u FAT12-chain=OK\n", outnames[j],
               dword(entry + 28), 1980 + (word(entry + 24) >> 9),
               (word(entry + 24) >> 5) & 15, word(entry + 24) & 31);
    }
    free(seen); free(image);
    return found == 7 ? 0 : 4;
}
