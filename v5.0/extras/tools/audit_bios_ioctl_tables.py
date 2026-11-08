"""Check BIOS disk IOCTL dispatch and supported-function tables."""
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
    source = ROOT / 'bios/msdioctl.asm'
    if source.read_bytes() != (work / 'src/msdioctl.asm').read_bytes():
        raise ValueError('current source differs from built source')
    target = read_target('IO.SYS')
    if (stage / 'IO.SYS').read_bytes() != target:
        raise ValueError('fresh build differs from retained target')
    loader_size = loader['output']['length']
    if target[loader_size:] != (work / 'msbio.bin').read_bytes():
        raise ValueError('BIOS payload differs from target')
    mapping = (work / 'msbio.map').read_text(errors='strict')
    symbols = set(re.findall(r'(?im)^\s*([0-9a-f]{4}):([0-9a-f]{4})\s+do_generic_ioctl\s*$', mapping))
    if len(symbols) != 1:
        raise ValueError('missing or ambiguous IOCTL entry')
    segment, entry = (int(value, 16) for value in next(iter(symbols)))
    base = entry - 0x2f
    listing = (work / 'msdioctl.lst').read_text(errors='replace')
    if not re.search(r'(?im)^\s*002F\s+\\\s*Do_Generic_IOCtl\s+PROC', listing):
        raise ValueError('unexpected IOCTL module layout')
    pattern = r'(?im)^\s*([0-9a-f]{4})\s+([0-9a-f]{4})\s+R\s+\\\s*dw\s+([\w?$@]+)'
    records = {int(offset, 16): (int(value, 16), name)
               for offset, value, name in re.findall(pattern, listing)}
    rows = []
    for name, offset, maximum in (('read', 0x00, 8), ('write', 0x13, 7)):
        pos = loader_size + segment * 16 + base + offset
        if target[pos] != maximum:
            raise ValueError(f'{name}: target maximum mismatch')
        for index in range(maximum + 1):
            value, symbol = records[offset + 1 + 2 * index]
            file_offset = pos + 1 + 2 * index
            actual = struct.unpack_from('<H', target, file_offset)[0]
            if actual != base + value:
                raise ValueError(f'{name}[{index}]: address mismatch')
            rows.append({'table': name, 'index': index, 'symbol': symbol,
                         'address': actual, 'target_file_offset': file_offset})
    supported_offset = loader_size + segment * 16 + base + 0x24
    supported = bytes.fromhex('60 40 61 41 62 42 66 46 67 47 68')
    byte_pattern = r'(?im)^\s*([0-9a-f]{4})\s+([0-9a-f]{2})\s+\\\s*db\s+([\w?$@]+)'
    byte_records = {int(offset, 16): (int(value, 16), name)
                    for offset, value, name in re.findall(byte_pattern, listing)}
    if any(byte_records.get(0x24 + index, (-1,))[0] != value
           for index, value in enumerate(supported)):
        raise ValueError('supported IOCTL listing mismatch')
    if target[supported_offset:supported_offset+len(supported)] != supported:
        raise ValueError('supported IOCTL function table mismatch')
    result = {'stage': str(stage), 'target_sha256': hashlib.sha256(target).hexdigest(),
              'source_sha256': hashlib.sha256(source.read_bytes()).hexdigest(),
              'segment': segment, 'module_base': base, 'dispatch_entries': rows,
              'supported_function_table': {'target_file_offset': supported_offset,
                                           'bytes_hex': supported.hex()},
              'scope': '17 dispatch offsets checked against MASM, link map and target bytes; '
                       '11 supported codes checked against target bytes. No runtime or original-source claim.'}
    output.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'dispatch_entries': len(rows), 'supported_codes': len(supported),
                      'report': str(output)}, indent=2))


if __name__ == '__main__':
    main()
