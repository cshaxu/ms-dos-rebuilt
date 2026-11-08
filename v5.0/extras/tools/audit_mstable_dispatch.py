"""Compare the recovered DOSTable with source references and target bytes."""
from pathlib import Path
import argparse
import hashlib
import json
import re
import struct
from target_files import read_target

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'


def entries(path):
    text = path.read_text(encoding='latin1')
    region = re.split(r'(?i)DOSTable\s+LABEL\s+WORD', text, maxsplit=1)[1]
    region = re.split(r'(?i)DOSTableEnd\s+LABEL', region, maxsplit=1)[0]
    return re.findall(r'(?im)^\s*short_addr\s+([\w$?@]+)', region)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stage', required=True)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    if Path(args.stage).name != args.stage or not args.stage.startswith('integrated-source-'):
        parser.error('invalid stage')
    if Path(args.report).name != args.report:
        parser.error('invalid report name')
    out = EVIDENCE / args.report
    if out.exists():
        raise FileExistsError(out)
    stage = ROOT / 'extras/build' / args.stage
    report = json.loads((stage / 'kernel-report.json').read_text())
    work = Path(report['stage']).resolve()
    if not work.is_relative_to((ROOT / 'extras/build').resolve()):
        raise ValueError('invalid kernel stage')
    source = ROOT / 'dos/mstable.asm'
    if source.read_bytes() != (work / 'mstable.asm').read_bytes():
        raise ValueError('current source differs from build source')
    refs = {'current': source, 'dos4': ROOT.parent / 'v4.0/src/DOS/MS_TABLE.ASM',
            'dos6': ROOT.parent / 'v6.0/dos/mstable.asm',
            'opennt': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos\mstable.asm')}
    names = {name: entries(path) for name, path in refs.items()}
    if any(len(value) != 48 for value in names.values()):
        raise ValueError('unexpected DOSTable length')
    maptext = (work / 'MSDOS.MAP').read_text(errors='strict')
    symbols = {}
    for segment, offset, name in re.findall(r'(?im)^\s*([0-9a-f]{4}):([0-9a-f]{4})\s+(\S+)', maptext):
        if int(segment, 16) == 0:
            symbols.setdefault(name.lower(), set()).add(int(offset, 16))
    origin_text = (work / 'origin.lst').read_text(errors='replace')
    origin_matches = re.findall(r'(?im)^\s*=\s*([0-9a-f]+)\s+.*\bPARASTART\s+EQU\b', origin_text)
    if len(origin_matches) != 1 or len(symbols.get('dtab', set())) != 1:
        raise ValueError('missing or ambiguous origin/DTAB')
    origin = int(origin_matches[0], 16)
    target = read_target('MSDOS.SYS')
    dtab_offset = next(iter(symbols['dtab'])) - origin
    table_addr = struct.unpack_from('<H', target, dtab_offset)[0]
    table_offset = table_addr - origin
    if target[table_offset] != len(names['current']):
        raise ValueError('target table count mismatch')
    rows = []
    for index, name in enumerate(names['current']):
        address = struct.unpack_from('<H', target, table_offset + 1 + 2 * index)[0]
        if address not in symbols.get(name.lower(), set()):
            raise ValueError(f'target address mismatch: {index} {name}')
        rows.append({'index': index, 'current': name, 'target_address': address,
                     'dos4': names['dos4'][index], 'dos6': names['dos6'][index],
                     'opennt': names['opennt'][index]})
    sha = lambda data: hashlib.sha256(data).hexdigest()
    result = {'stage': str(stage), 'target_sha256': sha(target), 'origin': origin,
              'dtab_file_offset': dtab_offset, 'table_file_offset': table_offset,
              'references': {name: {'path': str(path), 'sha256': sha(path.read_bytes())}
                             for name, path in refs.items()}, 'entries': rows,
              'scope': '48 target table addresses checked against the linked map. '
                       'Source-table name comparison is not proof of original source text '
                       'or runtime behavior.'}
    out.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'entries': len(rows), 'table_file_offset': table_offset,
                      'dos4_differences': sum(x['current'].lower() != x['dos4'].lower() for x in rows),
                      'dos6_differences': sum(x['current'].lower() != x['dos6'].lower() for x in rows),
                      'opennt_differences': sum(x['current'].lower() != x['opennt'].lower() for x in rows),
                      'report': str(out)}, indent=2))


if __name__ == '__main__':
    main()
