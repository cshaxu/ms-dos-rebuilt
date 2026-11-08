"""Read-only FAT12 target inspection; optional extraction to a new directory."""
import argparse
import hashlib
import json
import struct
from pathlib import Path

TARGETS = ("IO.SYS", "MSDOS.SYS", "COMMAND.COM")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def inspect(path, output=None):
    b = path.read_bytes()
    if len(b) < 512 or b[510:512] != b'\x55\xaa':
        raise ValueError('missing boot sector/signature')
    u16 = lambda n: struct.unpack_from('<H', b, n)[0]
    u32 = lambda n: struct.unpack_from('<I', b, n)[0]
    bs, spc, reserved, fats, entries, sectors, spf = u16(11), b[13], u16(14), b[16], u16(17), u16(19) or u32(32), u16(22)
    if bs not in (512, 1024, 2048, 4096) or spc == 0 or spc & (spc-1) or not reserved or fats != 2 or not spf:
        raise ValueError('unsupported or invalid BPB')
    root = (reserved + fats * spf) * bs
    data = root + ((entries * 32 + bs - 1) // bs) * bs
    clusters = (sectors - data // bs) // spc
    if not 0 < clusters < 4085 or data > len(b):
        raise ValueError('not FAT12 or metadata incomplete')
    fat1 = b[reserved*bs:(reserved+spf)*bs]
    fat2 = b[(reserved+spf)*bs:(reserved+2*spf)*bs]
    if len(fat1) != spf*bs or fat1 != fat2:
        raise ValueError('FAT copies incomplete or differ')
    results, occupied = {}, set()
    for off in range(root, root + entries*32, 32):
        e = b[off:off+32]
        if len(e) != 32: raise ValueError('root directory incomplete')
        if e[0] == 0: break
        if e[0] == 0xe5 or e[11] == 0x0f: continue
        name = e[:8].decode('ascii', 'replace').strip() + '.' + e[8:11].decode('ascii', 'replace').strip()
        if name not in TARGETS: continue
        if name in results or e[11] & 0x18: raise ValueError('duplicate or non-file target: ' + name)
        c, size = struct.unpack_from('<H', e, 26)[0], struct.unpack_from('<I', e, 28)[0]
        chain, chunks = [], []
        while 2 <= c < 0xff8:
            if c >= clusters + 2 or c in chain or c in occupied: raise ValueError('invalid, cyclic or cross-linked target cluster')
            chain.append(c); occupied.add(c)
            begin = data + (c-2)*spc*bs
            if begin + spc*bs > len(b): raise ValueError('target cluster outside supplied image')
            chunks.append(b[begin:begin+spc*bs])
            pos = c + c//2
            if pos+1 >= len(fat1): raise ValueError('FAT entry outside table')
            word = int.from_bytes(fat1[pos:pos+2], 'little')
            c = (word >> 4) if c & 1 else (word & 0xfff)
            if c == 0xff7 or 0xff0 <= c <= 0xff6: raise ValueError('bad or reserved cluster')
        if c < 0xff8 or len(chain) != (size + spc*bs - 1)//(spc*bs): raise ValueError('invalid chain length or terminator')
        payload = b''.join(chunks)[:size]
        results[name] = {'size': size, 'sha256': digest(payload), 'first_cluster': chain[0], 'clusters': len(chain), 'last_cluster': chain[-1], 'attributes': e[11]}
        if output is not None:
            (output / name).write_bytes(payload)
    if set(results) != set(TARGETS): raise ValueError('missing target files')
    return {'image': {'size': len(b), 'sha256': digest(b), 'bpb_bytes': sectors*bs, 'bytes_per_sector': bs, 'sectors_per_cluster': spc, 'reserved_sectors': reserved, 'fat_count': fats, 'fat_sectors': spf, 'root_entries': entries, 'data_offset': data, 'fat_copies_equal': True}, 'files': results}


if __name__ == '__main__':
    ap = argparse.ArgumentParser()
    ap.add_argument('image', type=Path)
    ap.add_argument('--extract-new', type=Path, help='new directory only; never overwrite existing files')
    args = ap.parse_args()
    if args.extract_new is not None:
        args.extract_new.mkdir(parents=True, exist_ok=False)
    print(json.dumps(inspect(args.image, args.extract_new), indent=2))
