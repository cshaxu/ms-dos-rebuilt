/* Decode the CM/DS stream in a Windows Me IO.SYS for comparison. */
/* Format reference: GRUB4DOS stage2/builtins.c, WinME support. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct {
    const unsigned char *data;
    size_t bit, end;
} BITS;

static void fail(const char *message)
{
    fprintf(stderr, "%s\n", message);
    exit(1);
}

static unsigned word(const unsigned char *p)
{
    return p[0] | ((unsigned)p[1] << 8);
}

static unsigned read_bits(BITS *stream, unsigned count)
{
    unsigned value = 0, n;
    if (count > stream->end - stream->bit)
        fail("Truncated DS bitstream");
    for (n = 0; n < count; ++n, ++stream->bit)
        value |= ((stream->data[stream->bit / 8] >> (stream->bit % 8)) & 1u) << n;
    return value;
}

static void decode_ds(const unsigned char *data, size_t packed,
                      unsigned char *out, size_t length)
{
    BITS stream = {data, 32, packed * 8};
    size_t written = 0, sector;
    if (packed < 4 || memcmp(data, "DS", 2) || !length)
        fail("Invalid DS block");
    for (sector = 0; sector < length; sector += 512) {
        size_t end = length - sector < 512 ? length : sector + 512;
        for (;;) {
            unsigned type = read_bits(&stream, 2), distance, prefix = 0, count;
            if (type == 1 || type == 2) {
                if (written == end)
                    fail("Literal crosses sector boundary");
                out[written++] = (unsigned char)(read_bits(&stream, 7) | (type == 1 ? 128 : 0));
                continue;
            }
            if (!type)
                distance = read_bits(&stream, 6);
            else if (read_bits(&stream, 1))
                distance = read_bits(&stream, 12) + 0x140;
            else
                distance = read_bits(&stream, 8) + 0x40;
            if (distance == 0x113f)
                break;
            while (!read_bits(&stream, 1))
                if (++prefix > 8)
                    fail("Invalid DS match length");
            count = (1u << prefix) + 1 + read_bits(&stream, prefix);
            if (!distance || distance > written || count > end - written)
                fail("Invalid DS back-reference");
            while (count--) {
                out[written] = out[written - distance];
                ++written;
            }
        }
        if (written != end)
            fail("Incomplete DS sector");
    }
}

int main(int argc, char **argv)
{
    unsigned char *image, block[65536];
    FILE *input, *output;
    long file_size;
    size_t size, pos = 0x800, decoded = 0;
    if (argc != 3) {
        fprintf(stderr, "Usage: cmdecode IO.SYS payload.bin\n");
        return 2;
    }
    input = fopen(argv[1], "rb");
    if (!input || fseek(input, 0, SEEK_END) || (file_size = ftell(input)) < 0x802)
        fail("Cannot read IO.SYS header");
    size = (size_t)file_size;
    image = malloc(size);
    rewind(input);
    if (!image || fread(image, 1, size, input) != size || fclose(input))
        fail("Cannot read IO.SYS image");
    if (memcmp(image, "MZ", 2) || memcmp(image + pos, "CM", 2))
        fail("Missing IO.SYS CM header");
    pos += 2;
    output = fopen(argv[2], "wb");
    if (!output)
        fail("Cannot create decoded payload");
    puts("kind\tinput_offset\tinput_bytes\toutput_offset\toutput_bytes");
    while (size - pos >= 3) {
        unsigned flag = image[pos], packed = word(image + pos + 1), length;
        const unsigned char *source;
        pos += 3;
        if (!packed) {
            pos = (pos + 15) & ~(size_t)15;
            if (pos >= size || size - pos < 2 || memcmp(image + pos, "CM", 2))
                fail("Missing IO.SYS CM trailer");
            printf("trailer\t%zu\t%zu\t%zu\t0\n", pos, size - pos, decoded);
            if (fclose(output))
                fail("Cannot close decoded payload");
            free(image);
            return 0;
        }
        length = packed;
        if (flag) {
            if (size - pos < 2)
                fail("Missing DS output length");
            length = word(image + pos);
            pos += 2;
        }
        if (packed > size - pos)
            fail("Truncated CM block");
        source = image + pos;
        if (flag) {
            decode_ds(source, packed, block, length);
            source = block;
        }
        if (fwrite(source, 1, length, output) != length)
            fail("Cannot write decoded payload");
        printf("%s\t%zu\t%u\t%zu\t%u\n", flag ? "DS" : "raw", pos, packed, decoded, length);
        pos += packed;
        decoded += length;
    }
    fail("Missing CM terminator");
    return 1;
}
