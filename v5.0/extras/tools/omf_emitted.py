"""Read emitted byte ranges from 16-bit OMF LEDATA and LIDATA records."""
def omf_index(data, pos):
    if data[pos] & 0x80:
        return ((data[pos] & 0x7f) << 8) | data[pos + 1], pos + 2
    return data[pos], pos + 1


def iterated(data, pos, depth=0):
    assert depth < 32 and pos + 4 <= len(data)
    repeat = int.from_bytes(data[pos:pos + 2], 'little')
    count = int.from_bytes(data[pos + 2:pos + 4], 'little')
    pos += 4
    if count == 0:
        assert pos < len(data)
        size = data[pos]
        pos += 1
        assert pos + size <= len(data)
        unit = data[pos:pos + size]
        pos += size
    else:
        parts = []
        for _ in range(count):
            part, pos = iterated(data, pos, depth + 1)
            parts.append(part)
        unit = b''.join(parts)
    assert len(unit) * repeat <= 65536
    return unit * repeat, pos


def emitted_segments(data, allow_overlaps=False):
    pos = 0
    segments = {}
    counts = {'ledata': 0, 'lidata': 0, 'conflicting_overwrites': 0}
    while pos < len(data):
        assert pos + 3 <= len(data)
        kind = data[pos]
        # These exact-build objects use only these 16-bit OMF record kinds.
        # Reject unknown kinds rather than silently overlooking data records.
        assert kind in {0x80, 0x88, 0x8a, 0x8c, 0x90, 0x96, 0x98, 0x9a, 0x9c, 0xa0, 0xa2}, hex(kind)
        length = int.from_bytes(data[pos + 1:pos + 3], 'little')
        record = data[pos:pos + 3 + length]
        assert length > 0 and len(record) == 3 + length and sum(record) % 256 == 0
        pos += len(record)
        if kind not in (0xa0, 0xa2):
            continue
        body = record[3:-1]
        seg, at = omf_index(body, 0)
        assert at + 2 <= len(body)
        offset = int.from_bytes(body[at:at + 2], 'little')
        at += 2
        if kind == 0xa0:
            payload = body[at:]
            counts['ledata'] += 1
        else:
            parts = []
            while at < len(body):
                part, at = iterated(body, at)
                parts.append(part)
            payload = b''.join(parts)
            counts['lidata'] += 1
        assert offset + len(payload) <= 65536
        dst = segments.setdefault(seg, {})
        for index, byte in enumerate(payload):
            position = offset + index
            if position in dst and dst[position] != byte:
                counts['conflicting_overwrites'] += 1
                assert allow_overlaps, (seg, position, dst[position], byte)
            dst[position] = byte
    assert pos == len(data)
    return segments, counts
