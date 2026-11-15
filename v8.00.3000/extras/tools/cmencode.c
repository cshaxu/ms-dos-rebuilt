/* Encode the Windows Me CM/DS container stream from a linked IO payload. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define SECTOR_SIZE 512u
#define BLOCK_SIZE (96u * SECTOR_SIZE)
#define MAX_DISTANCE 0x113eu
#define PACKED_LIMIT (4u + BLOCK_SIZE * 9u / 8u + (96u * 15u + 7u) / 8u)
#define CM_OFFSET 0x800u

typedef struct {
    unsigned char data[PACKED_LIMIT];
    size_t bits;
} STREAM;

typedef struct {
    int head[65536];
    int previous[BLOCK_SIZE];
} DICTIONARY;

static void fail(const char *message)
{
    fprintf(stderr, "%s\n", message);
    exit(1);
}

static void write_bytes(FILE *file, const void *data, size_t length)
{
    if (fwrite(data, 1, length, file) != length)
        fail("Cannot write CM stream");
}

static void emit(STREAM *stream, unsigned value, unsigned count)
{
    unsigned bit;
    for (bit = 0; bit < count; ++bit, ++stream->bits)
        if (value & (1u << bit))
            stream->data[stream->bits / 8] |= (unsigned char)(1u << (stream->bits % 8));
}

static void emit_match(STREAM *stream, unsigned distance, unsigned length)
{
    unsigned prefix = 0, base = 1;
    if (distance < 64)
        emit(stream, distance << 2, 8);
    else if (distance < 320)
        emit(stream, ((distance - 64) << 3) | 3, 11);
    else
        emit(stream, ((distance - 320) << 3) | 7, 15);
    while (length - 1 >= base * 2) {
        base *= 2;
        ++prefix;
    }
    emit(stream, 0, prefix);
    emit(stream, 1, 1);
    emit(stream, length - base - 1, prefix);
}

static void index_bytes(DICTIONARY *dictionary, const unsigned char *input, size_t size)
{
    size_t pos;
    for (pos = 0; pos < 65536; ++pos)
        dictionary->head[pos] = -1;
    for (pos = 0; pos + 1 < size; ++pos) {
        unsigned pair = ((unsigned)input[pos] << 8) | input[pos + 1];
        dictionary->previous[pos] = dictionary->head[pair];
        dictionary->head[pair] = (int)pos;
    }
}

static void encode_block(STREAM *stream, DICTIONARY *dictionary,
                         const unsigned char *input, size_t size)
{
    size_t pos = 0;
    memset(stream, 0, sizeof(*stream));
    memcpy(stream->data, "DS\0\1", 4);
    stream->bits = 32;
    index_bytes(dictionary, input, size);
    while (pos < size) {
        size_t end = (pos & ~(size_t)(SECTOR_SIZE - 1)) + SECTOR_SIZE;
        if (end > size)
            end = size;
        while (pos < end) {
            unsigned best = 1, distance = 0;
            if (pos + 1 < end) {
                int candidate = dictionary->previous[pos];
                while (candidate >= 0 && pos - (size_t)candidate <= MAX_DISTANCE) {
                    size_t back = (size_t)candidate;
                    unsigned length = 2;
                    while (pos + length < end && input[pos + length] == input[back + length])
                        ++length;
                    if (length > best) {
                        best = length;
                        distance = (unsigned)(pos - back);
                        if (pos + best == end)
                            break;
                    }
                    candidate = dictionary->previous[back];
                }
            }
            if (distance)
                emit_match(stream, distance, best);
            else
                emit(stream, ((input[pos] & 127u) << 2) | (input[pos] < 128 ? 2 : 1), 9);
            pos += best;
        }
        emit(stream, 0x7fff, 15);
    }
}

static void compare_stream(const char *name, const char *reference, size_t length)
{
    FILE *output = fopen(name, "rb"), *target = fopen(reference, "rb");
    size_t pos;
    if (!output || !target || fseek(target, CM_OFFSET, SEEK_SET))
        fail("Cannot open CM comparison inputs");
    for (pos = 0; pos < length; ++pos) {
        int actual = fgetc(output), expected = fgetc(target);
        if (actual == EOF || actual != expected) {
            fprintf(stderr, "First CM difference at IO.SYS offset %zu (stream offset %zu)\n",
                    pos + CM_OFFSET, pos);
            exit(1);
        }
    }
    if (fgetc(output) != EOF || fgetc(target) != 'C' || fgetc(target) != 'M')
        fail("CM stream extent or trailer mismatch");
    fclose(target);
    fclose(output);
    printf("CM stream matches all %zu bytes through the aligned trailer boundary.\n", length);
}

/* Copy the load module of a linked real-mode component. */
static size_t append_component(FILE *file, const char *name, int loader)
{
    unsigned char header[28], data[SECTOR_SIZE];
    FILE *component = fopen(name, "rb");
    size_t start, length, remaining;
    long end;

    if (!component || fread(header, 1, sizeof(header), component) != sizeof(header) ||
        memcmp(header, "MZ", 2) || header[6] || header[7])
        fail("Invalid linked IO component");
    start = 16u * (header[8] + 256u * header[9]);
    if (start < sizeof(header) || fseek(component, 0, SEEK_END) ||
        (end = ftell(component)) < 0 || (unsigned long)end <= start ||
        fseek(component, (long)start, SEEK_SET))
        fail("Cannot read linked IO component");
    length = (size_t)end - start;
    if ((loader && length != CM_OFFSET) || (!loader && length < 26))
        fail("Wrong linked IO component size");
    for (remaining = length; remaining; ) {
        size_t count = remaining < sizeof(data) ? remaining : sizeof(data);
        if (fread(data, 1, count, component) != count)
            fail("Cannot read linked IO component");
        if (remaining == length && !loader && memcmp(data, "CM", 2))
            fail("Invalid CM decompressor signature");
        write_bytes(file, data, count);
        remaining -= count;
    }
    fclose(component);
    return length;
}

static void finish_image(FILE *file, size_t length)
{
    unsigned char zero[SECTOR_SIZE] = {0};
    unsigned char header[10] = {'M', 'Z'};
    size_t padding = (SECTOR_SIZE - length % SECTOR_SIZE) % SECTOR_SIZE;
    size_t paragraphs = (length + padding + SECTOR_SIZE) / 16;

    if (paragraphs > 0xffffu)
        fail("Packed IO image is too large");
    write_bytes(file, zero, padding);
    header[8] = (unsigned char)paragraphs;
    header[9] = (unsigned char)(paragraphs >> 8);
    if (fseek(file, 0, SEEK_SET))
        fail("Cannot write packed IO header");
    write_bytes(file, header, sizeof(header));
}

int main(int argc, char **argv)
{
    unsigned char input[BLOCK_SIZE], zeros[18] = {0};
    STREAM stream;
    DICTIONARY *dictionary;
    FILE *source, *output;
    size_t length = 2, count, padding;
    int pack = argc == 6 && !strcmp(argv[1], "--pack");
    if (!pack && argc != 3 && argc != 4) {
        fprintf(stderr, "Usage: cmencode payload.bin stream.bin [verify-IO.SYS]\n"
                        "       cmencode --pack payload.bin msload.exe mscm.exe IO.SYS\n");
        return 2;
    }
    source = fopen(argv[pack ? 2 : 1], "rb");
    output = fopen(argv[pack ? 5 : 2], "wb");
    dictionary = malloc(sizeof(*dictionary));
    if (!source || !output || !dictionary)
        fail("Cannot open CM inputs or allocate dictionary");
    if (pack)
        append_component(output, argv[3], 1);
    write_bytes(output, "CM", 2);
    while ((count = fread(input, 1, sizeof(input), source)) != 0) {
        unsigned char header[5];
        size_t packed;
        encode_block(&stream, dictionary, input, count);
        packed = (stream.bits + 7) / 8;
        header[0] = 1;
        header[1] = (unsigned char)packed;
        header[2] = (unsigned char)(packed >> 8);
        header[3] = (unsigned char)count;
        header[4] = (unsigned char)(count >> 8);
        write_bytes(output, header, sizeof(header));
        write_bytes(output, stream.data, packed);
        length += sizeof(header) + packed;
    }
    if (ferror(source))
        fail("Cannot read IO payload");
    padding = (16 - (length + 3) % 16) % 16;
    write_bytes(output, zeros, 3 + padding);
    length += 3 + padding;
    if (pack) {
        size_t trailer = append_component(output, argv[4], 0);
        finish_image(output, CM_OFFSET + length + trailer);
    }
    fclose(source);
    if (fclose(output))
        fail("Cannot close CM output");
    free(dictionary);
    if (argc == 4)
        compare_stream(argv[2], argv[3], length);
    return 0;
}
