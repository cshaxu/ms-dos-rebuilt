"""Check static target Get-DPB edges and all currently recovered BUF slices.

Direct calls are decoded at audited instruction boundaries, not scanned as data.
This does not execute the target or establish compatibility of the full FAT ABI.
"""
from pathlib import Path
import hashlib
import json
import re
from fat12_guest_file import read_root_file

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
report_name = 'm4-t5-cache-parms-build.json'
build = json.loads((evidence / report_name).read_text())
stage = Path(build['stage'])
candidate = (stage / 'ntdos.sys').read_bytes()
assert hashlib.sha256(candidate).hexdigest() == build['output_sha256']
mapping_path = stage / 'ntdos.map'
assert hashlib.sha256(mapping_path.read_bytes()).hexdigest() == build['map_sha256']
mapping = mapping_path.read_text()
target = read_root_file(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), 'MSDOS.SYS')
target_hash = hashlib.sha256(target).hexdigest()
assert target_hash == '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
origin = int.from_bytes(candidate[3:5], 'little')
listing = (stage / 'buf.lst').read_text(errors='replace')
rows = []
for name, offset in [('GetCurHead', 0x5aa6), ('ScanPlace', 0x5ab8),
                     ('PLACEBUF', 0x5abf), ('PointComp', 0x5afc),
                     ('SET_RQ_SC_PARMS', 0x5d03),
                     ('INC_DIRTY_COUNT', 0x5d16), ('DEC_DIRTY_COUNT', 0x5d1c),
                     ('GOTDPB', 0x60b)]:
    match = re.search(r'0000:([0-9A-F]+)\s+' + name + r'\b', mapping, re.I)
    assert match, name
    start = int(match[1], 16) - origin
    unit_listing = listing if name != 'GOTDPB' else (stage / 'mscode.lst').read_text(errors='replace')
    bounds = [re.search(r'^\s*([0-9A-F]{4})\s+.*\b' + name + r'\s+' + kind + r'\b', unit_listing, re.M | re.I) for kind in ('PROC', 'ENDP')]
    assert all(bounds), name
    size = int(bounds[1][1], 16) - int(bounds[0][1], 16)
    actual, expected = candidate[start:start+size], target[offset:offset+size]
    rows.append(dict(name=name, candidate_offset=start, target_offset=offset,
                     size=size, candidate_hex=actual.hex(), target_hex=expected.hex(), exact=actual == expected))

edges = []
for site, destination, label in [(0xf9a, 0x6c8c, 'GetThisDrv candidate'),
                               (0xfaa, 0x1356, 'EnterCritDisk candidate'),
                               (0xfad, 0x5899, 'FATREAD_CDS candidate'),
                               (0xfb0, 0x1376, 'LeaveCritDisk candidate'),
                               (0xfb5, 0x4a5, 'get_user_stack candidate'),
                               (0x58a6, 0x60b, 'GOTDPB')]:
    assert target[site] == 0xe8, hex(site)
    decoded = (site + 3 + int.from_bytes(target[site+1:site+3], 'little', signed=True)) & 0xffff
    edges.append(dict(site=site, bytes=target[site:site+3].hex(), destination=decoded,
                      expected_destination=destination, label=label, exact=decoded == destination))
assert target[0x5899:0x58a2] == bytes.fromhex('065726c46d45268a46')
out = dict(build_report=report_name, candidate_sha256=build['output_sha256'], target_sha256=target_hash,
           routines=rows, target_static_call_edges=edges,
           all_exact=all(r['exact'] for r in rows + edges),
           scope='Eight complete source routines and six target static call edges only; FATREAD_CDS label remains comparative attribution, no runtime or whole-kernel equivalence.')
(evidence / 'm4-t5-fat-chain-verification.json').write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
assert out['all_exact']
