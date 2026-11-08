"""Check BIOS character-device dispatch tables against linked target bytes."""
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
    bios = json.loads((stage / 'bios-report.json').read_text())
    loader = json.loads((stage / 'msload-report.json').read_text())
    work = Path(bios['stage']).resolve()
    if not work.is_relative_to((ROOT / 'extras/build').resolve()):
        raise ValueError('BIOS stage outside build')
    source = ROOT / 'bios/mschar.asm'
    if source.read_bytes() != (work / 'src/mschar.asm').read_bytes():
        raise ValueError('current source differs from built source')
    target = read_target('IO.SYS')
    if (stage / 'IO.SYS').read_bytes() != target:
        raise ValueError('fresh build differs from retained target')
    loader_size = loader['output']['length']
    if target[loader_size:] != (work / 'msbio.bin').read_bytes():
        raise ValueError('BIOS payload differs from target')
    mapping = (work / 'msbio.map').read_text(errors='strict')
    symbols = {}
    for segment, offset, name in re.findall(r'(?im)^\s*([0-9a-f]{4}):([0-9a-f]{4})\s+(\S+)', mapping):
        symbols.setdefault(name.lower(), set()).add((int(segment, 16), int(offset, 16)))
    def address(name):
        values = symbols.get(name.lower(), set())
        if len(values) != 1:
            raise ValueError(f'missing or ambiguous symbol: {name}')
        return next(iter(values))
    listing = (work / 'mschar.lst').read_text(errors='replace')
    records = {}
    pattern = r'(?im)^\s*([0-9a-f]{4})\s+([0-9a-f]{4})\s+([re])\s+\\\s*dw\s+([\w?$@]+)'
    for offset, value, kind, name in re.findall(pattern, listing):
        offset = int(offset, 16)
        if offset in records:
            raise ValueError('duplicate listing offset')
        records[offset] = (int(value, 16), kind.upper(), name)
    tables = []
    for name, module_offset, count in (('con_table', 0x00, 11), ('prn_table', 0x17, 26),
                                        ('aux_table', 0x4c, 11), ('tim_table', 0x63, 10)):
        segment, start = address(name)
        base = start - module_offset
        pos = loader_size + segment * 16 + start
        if target[pos] != count:
            raise ValueError(f'{name}: target entry count mismatch')
        rows = []
        for index in range(count):
            record_offset = module_offset + 1 + index * 2
            value, kind, symbol = records[record_offset]
            if kind == 'R':
                expected = base + value
            else:
                external_segment, expected = address(symbol)
                if external_segment != segment:
                    raise ValueError(f'{name}: unexpected external segment')
            actual = struct.unpack_from('<H', target, pos + 1 + index * 2)[0]
            if actual != expected:
                raise ValueError(f'{name}[{index}]: target address mismatch')
            rows.append({'index': index, 'symbol': symbol, 'address': actual,
                         'target_file_offset': pos + 1 + index * 2})
        tables.append({'name': name, 'segment': segment, 'offset': start,
                       'target_file_offset': pos, 'entries': rows})
    result = {'stage': str(stage), 'target_sha256': hashlib.sha256(target).hexdigest(),
              'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'loader_bytes': loader_size, 'tables': tables,
              'scope': '58 dispatch offsets checked against MASM records, link map and retained IO.SYS; '
                       'this does not prove runtime behavior or exact original source text.'}
    output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'tables': len(tables), 'entries': sum(len(x['entries']) for x in tables),
                      'report': str(output)}, indent=2))


if __name__ == '__main__':
    main()
