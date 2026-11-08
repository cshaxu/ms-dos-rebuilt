"""Audit root-file allocation in the retained disposable FAT12 probe image."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
prior = json.loads((EVIDENCE / 'm6-dpbfat-headless-runtime.json').read_text())
image_path = Path(prior['stage']) / 'boot.img'
image = image_path.read_bytes()
digest = lambda data: hashlib.sha256(data).hexdigest()
assert digest(image) == prior['image_after_sha256']
word = lambda off: struct.unpack_from('<H', image, off)[0]
bs, spc, reserved, fats, entries, spf = word(11), image[13], word(14), image[16], word(17), word(22)
total = word(19) or struct.unpack_from('<I', image, 32)[0]
assert bs == 512 and spc == 1 and reserved == 1 and fats == 2 and spf == 9
assert len(image) == total * bs
root_start = (reserved + fats * spf) * bs
data_sector = reserved + fats * spf + (entries * 32 + bs - 1) // bs
cluster_count = (total - data_sector) // spc
assert cluster_count < 4085
fat = image[reserved * bs:(reserved + spf) * bs]
assert fat == image[(reserved + spf) * bs:(reserved + 2 * spf) * bs]

def next_cluster(cluster):
    offset = cluster + cluster // 2
    value = int.from_bytes(fat[offset:offset + 2], 'little')
    return (value >> 4 if cluster & 1 else value) & 0xfff

owners = {}
files = []
for offset in range(root_start, root_start + entries * 32, 32):
    entry = image[offset:offset + 32]
    if not entry[0]:
        break
    if entry[0] == 0xe5 or entry[11] == 0x0f or entry[11] & 0x08:
        continue
    assert not entry[11] & 0x10, 'subdirectories are outside this audit'
    name = entry[:8].decode('ascii').rstrip() + '.' + entry[8:11].decode('ascii').rstrip()
    size = struct.unpack_from('<I', entry, 28)[0]
    cluster = struct.unpack_from('<H', entry, 26)[0]
    chain = []
    while cluster < 0xff8:
        assert 2 <= cluster < cluster_count + 2, (name, cluster)
        assert cluster not in owners, (name, cluster, owners.get(cluster))
        owners[cluster] = name
        chain.append(cluster)
        cluster = next_cluster(cluster)
    assert len(chain) == (size + bs * spc - 1) // (bs * spc), name
    files.append({'name': name, 'bytes': size, 'clusters': chain})

allocated = {c for c in range(2, cluster_count + 2) if next_cluster(c) != 0}
assert allocated == set(owners), {'orphan_clusters': sorted(allocated - set(owners)),
                                  'unallocated_in_chains': sorted(set(owners) - allocated)}
fatdata = next(item for item in files if item['name'] == 'FATDATA.BIN')
assert fatdata['clusters'] == prior['fat_chain'] and fatdata['bytes'] == prior['fat_file_bytes']
report = {'image': str(image_path), 'image_sha256': digest(image), 'sector_bytes': bs,
          'sectors_per_cluster': spc, 'data_clusters': cluster_count, 'fat_copies_equal': True,
          'allocated_clusters': len(allocated), 'cross_linked_clusters': [], 'orphan_clusters': [],
          'root_files': files,
          'scope': 'Read-only audit of allocated root files on one retained disposable probe image; no subdirectories, fragmented-chain runtime, other geometries, or complete FAT behavior are verified.'}
(EVIDENCE / 'm6-dpbfat-allocation-audit.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({key: value for key, value in report.items() if key != 'root_files'}, indent=2))
