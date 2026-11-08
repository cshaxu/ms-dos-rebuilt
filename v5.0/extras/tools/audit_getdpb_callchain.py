"""Check selected Get-DPB/FAT near-call sites in the retained target."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
from target_files import read_target

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--stage', required=True)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    if Path(args.stage).name != args.stage or not args.stage.startswith('integrated-source-'):
        parser.error('invalid stage')
    if Path(args.report).name != args.report:
        parser.error('invalid report name')
    output = EVIDENCE / args.report
    if output.exists():
        raise FileExistsError(output)
    stage = ROOT / 'extras/build' / args.stage
    report = json.loads((stage / 'kernel-report.json').read_text())
    work = Path(report['stage']).resolve()
    if not work.is_relative_to((ROOT / 'extras/build').resolve()):
        raise ValueError('kernel stage outside build')
    for name in ('misc', 'fat', 'buf'):
        if (ROOT / 'dos' / f'{name}.asm').read_bytes() != (work / f'{name}.asm').read_bytes():
            raise ValueError(f'{name} differs from built source')
    mapping = (work / 'MSDOS.MAP').read_text(errors='strict')
    symbols = {}
    for segment, offset, name in re.findall(r'(?im)^\s*([0-9a-f]{4}):([0-9a-f]{4})\s+(\S+)', mapping):
        if int(segment, 16) == 0:
            symbols.setdefault(name.lower(), set()).add(int(offset, 16))
    def address(name):
        values = symbols.get(name.lower(), set())
        if len(values) != 1:
            raise ValueError(f'missing or ambiguous symbol: {name}')
        return next(iter(values))
    listing = {name: (work / f'{name}.lst').read_text(errors='replace') for name in ('misc', 'fat')}
    origin_text = (work / 'origin.lst').read_text(errors='replace')
    origins = re.findall(r'(?im)^\s*=\s*([0-9a-f]+)\s+.*\bPARASTART\s+EQU\b', origin_text)
    if len(origins) != 1:
        raise ValueError('missing or ambiguous code origin')
    origin = int(origins[0], 16)
    bases = {'misc': address('$GET_DPB') - 0x46, 'fat': address('FATREAD_CDS') - 0x1cb}
    # Offsets are asserted against MASM listings, including macro-expanded CALLs.
    edges = [
        ('misc', 0x4a, '$GET_DPB', 'GETTHISDRV', 'normal drive lookup'),
        ('misc', 0x5a, '$GET_DPB', 'EcritDisk', 'enter disk critical section'),
        ('misc', 0x5d, '$GET_DPB', 'FATREAD_CDS', 'valid local drive'),
        ('misc', 0x60, '$GET_DPB', 'LcritDisk', 'leave disk critical section'),
        ('misc', 0x65, '$GET_DPB', 'get_user_stack', 'successful media check'),
        ('fat', 0x1d8, 'FATREAD_CDS', 'GOTDPB', 'CDS DPB pointer'),
        ('fat', 0x1db, 'FATREAD_CDS', 'FAT_GOT_DPB', 'media check'),
        ('fat', 0x236, 'FATERR', 'FATAL1', 'device media-check error'),
        ('fat', 0x26a, 'FAT_GOT_DPB', 'DEVIOCALL2', 'issue media-check request'),
        ('fat', 0x2c9, 'DISK_CHNG_ERR', 'HARDERR', 'wrong disk and volume ID supported'),
        ('fat', 0x2dd, 'CHKBUFFDIRT', 'GetCurHead', 'media state unknown and dirty buffers exist'),
        ('fat', 0x302, 'NEWDSK', 'GetCurHead', 'media change requires invalidation'),
        ('fat', 0x315, 'NEWDSK', 'ScanPlace', 'invalidate a matching clean buffer'),
        ('fat', 0x347, 'FAT_GOT_DPB', 'UNPACK', 'changed media, non-device FAT'),
        ('fat', 0x28, 'UNPACK', 'MAPCLUSTER', 'nonzero cluster'),
        ('fat', 0x155, 'MAPCLUSTER', 'GETBUFFRB', 'FAT-sector buffer'),
    ]
    target = read_target('MSDOS.SYS')
    if (stage / 'MSDOS.SYS').read_bytes() != target:
        raise ValueError('fresh build differs from retained target')
    rows = []
    for module, offset, caller, callee, condition in edges:
        pattern = rf'(?im)^\s*{offset:04X}\s+E8\s+[^\r\n]*\bCALL\s+{re.escape(callee)}\b'
        if not re.search(pattern, listing[module]):
            raise ValueError(f'listing does not identify {caller} -> {callee}')
        site = bases[module] + offset
        pos = site - origin
        code = target[pos:pos+3]
        if len(code) != 3 or code[0] != 0xe8:
            raise ValueError(f'not a near call at {site:04x}')
        destination = (site + 3 + struct.unpack('<h', code[1:])[0]) & 0xffff
        if destination != address(callee):
            raise ValueError(f'call target mismatch: {caller} -> {callee}')
        rows.append({'caller': caller, 'callee': callee, 'condition': condition,
                     'site': site, 'target_file_offset': pos,
                     'instruction_hex': code.hex(), 'destination': destination})
    branches = [
        ('misc', 0x4d, 0x72, 'JC', 'ISNODRV', 0x71, 'invalid drive'),
        ('misc', 0x58, 0x75, 'JNZ', 'ISNODRV', 0x71, 'network CDS'),
        ('misc', 0x63, 0x72, 'JC', 'ISNODRV', 0x71, 'media-check error'),
        ('fat', 0x1e2, 0x75, 'JNZ', 'NO_CHANGE', 0x21c, 'media not changed'),
    ]
    branch_rows = []
    for module, offset, opcode, mnemonic, label, destination_offset, condition in branches:
        if not re.search(rf'(?im)^\s*{offset:04X}\s+{opcode:02X}\s+[0-9a-f]{{2}}\s+[^\r\n]*\b{mnemonic}\s+{label}\b', listing[module]):
            raise ValueError(f'listing does not identify {mnemonic} {label}')
        if not re.search(rf'(?im)^\s*{destination_offset:04X}\s+[^\r\n]*\b{label}:', listing[module]):
            raise ValueError(f'listing does not identify destination {label}')
        site = bases[module] + offset
        pos = site - origin
        code = target[pos:pos+2]
        if len(code) != 2 or code[0] != opcode:
            raise ValueError(f'wrong branch opcode at {site:04x}')
        destination = (site + 2 + struct.unpack('<b', code[1:])[0]) & 0xffff
        if destination != bases[module] + destination_offset:
            raise ValueError(f'branch target mismatch: {label}')
        branch_rows.append({'module': module, 'condition': condition, 'mnemonic': mnemonic,
                            'label': label, 'site': site, 'target_file_offset': pos,
                            'instruction_hex': code.hex(), 'destination': destination})
    result = {'stage': str(stage), 'audit_tool_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
              'target_sha256': hashlib.sha256(target).hexdigest(),
              'origin': origin, 'edges': rows, 'branches': branch_rows,
              'scope': 'Selected static near-call and conditional-branch instructions only. Conditions come from source; '
                       'this does not establish reachability, complete register behavior or runtime correctness.'}
    output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'edges': len(rows), 'branches': len(branch_rows), 'report': str(output)}, indent=2))


if __name__ == '__main__':
    main()
