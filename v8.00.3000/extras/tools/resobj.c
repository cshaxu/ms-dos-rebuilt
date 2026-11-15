/* Convert a byte resource to a 16-bit Microsoft LINK object. */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

enum { segment_bytes = 65520, record_data = 1008, max_segments = 120 };

static void fail(const char *message)
{
    fprintf(stderr, "resobj: %s\n", message);
    exit(EXIT_FAILURE);
}

static void write_bytes(FILE *output, const void *bytes, size_t count)
{
    if (fwrite(bytes, 1, count, output) != count)
        fail("cannot write object file");
}

static void emit(FILE *output, unsigned type, const unsigned char *data, size_t size)
{
    const unsigned length = (unsigned)size + 1;
    const unsigned char header[] = {
        (unsigned char)type, (unsigned char)length, (unsigned char)(length >> 8)
    };
    unsigned sum = header[0] + header[1] + header[2];
    unsigned char checksum;
    size_t i;

    for (i = 0; i < size; i++)
        sum += data[i];
    checksum = (unsigned char)(0u - sum);
    write_bytes(output, header, sizeof(header));
    write_bytes(output, data, size);
    write_bytes(output, &checksum, 1);
}

static size_t name(unsigned char *at, const char *value)
{
    const size_t length = strlen(value);

    if (length > 255)
        fail("OMF name is too long");
    at[0] = (unsigned char)length;
    memcpy(at + 1, value, length);
    return length + 1;
}

static void emit_names(FILE *output, unsigned count)
{
    unsigned char names[max_segments * 12 + 16];
    size_t size = name(names, "");
    unsigned index;

    size += name(names + size, "IMAGE");
    for (index = 1; index <= count; index++) {
        char segment[12];
        snprintf(segment, sizeof(segment), "IMAGE%03u", index);
        size += name(names + size, segment);
    }
    emit(output, 0x96, names, size);
}

static void emit_segments(FILE *output, unsigned count, unsigned long bytes)
{
    unsigned index;
    for (index = 1; index <= count; index++) {
        const unsigned size = bytes < segment_bytes ? (unsigned)bytes : segment_bytes;
        const unsigned char segment[] = {
            (unsigned char)(index == 1 ? 0x68 : 0x28),
            (unsigned char)size, (unsigned char)(size >> 8),
            (unsigned char)(index + 2), 2, 1
        };
        emit(output, 0x98, segment, sizeof(segment));
        bytes -= size;
    }
}

static void emit_public(FILE *output)
{
    unsigned char record[24] = {0, 1};
    const size_t end = 2 + name(record + 2, "BootLogo");

    record[end] = record[end + 1] = record[end + 2] = 0;
    emit(output, 0x90, record, end + 3);
}

static void emit_contents(FILE *input, FILE *output, unsigned long bytes)
{
    unsigned index = 1;
    unsigned offset = 0;
    unsigned char record[record_data + 3];

    while (bytes) {
        size_t count = segment_bytes - offset;
        if (count > record_data)
            count = record_data;
        if (count > bytes)
            count = (size_t)bytes;
        record[0] = (unsigned char)index;
        record[1] = (unsigned char)offset;
        record[2] = (unsigned char)(offset >> 8);
        if (fread(record + 3, 1, count, input) != count)
            fail("cannot read resource bytes");
        emit(output, 0xA0, record, count + 3);
        bytes -= (unsigned long)count;
        offset += (unsigned)count;
        if (offset == segment_bytes) {
            offset = 0;
            index++;
        }
    }
}

int main(int argc, char **argv)
{
    FILE *input;
    FILE *output;
    long size;
    unsigned count;
    unsigned char module[16];
    const unsigned char module_end = 0;

    if (argc != 3)
        fail("usage: resobj input output.obj");
    input = fopen(argv[1], "rb");
    if (!input || fseek(input, 0, SEEK_END) != 0)
        fail("cannot open resource");
    size = ftell(input);
    if (size <= 0 || size > (long)segment_bytes * max_segments ||
        fseek(input, 0, SEEK_SET) != 0)
        fail("unsupported resource length");
    count = ((unsigned long)size + segment_bytes - 1) / segment_bytes;
    output = fopen(argv[2], "wb");
    if (!output)
        fail("cannot create object file");

    emit(output, 0x80, module, name(module, "BOOTLOGO"));
    emit_names(output, count);
    emit_segments(output, count, (unsigned long)size);
    emit_public(output);
    emit_contents(input, output, (unsigned long)size);
    emit(output, 0x8A, &module_end, 1);

    fclose(input);
    if (fclose(output) != 0)
        fail("cannot finish object file");
    printf("Resource: %ld bytes in %u segments\n", size, count);
    return EXIT_SUCCESS;
}
