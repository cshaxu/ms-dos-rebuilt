"""Check recovered BIOS class-3 message source against NT and target bytes."""
from pathlib import Path
import hashlib
import json
import re

root = Path(__file__).resolve().parent.parent.parent
evidence = root / 'extras/docs/etc/evidence'
source = (root / 'bios/msbio.cl3').read_bytes()
reference = (root / 'extras/research/messages/bios/usa-ms.msg').read_bytes()
build = json.loads((evidence / 'm5-bios-singleconfig-probe.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
assert sha(reference) == build['inputs']['usa-ms.msg']
assert source == (stage / 'msbio.cl3').read_bytes()
text = reference.decode('latin1')
section = text.split('MSBIO    00008f0b 0023', 1)[1].split('\nMSDOS    ', 1)[0]
reference_rows = {}
for match in re.finditer(r'(?m)^(\d{4})\s+U\s+\d{4}\s+([^\r\n]*)', section):
    number = int(match.group(1))
    assert number not in reference_rows
    reference_rows[number] = match.group(2)

def parse_values(value):
    token = re.compile(r'''\s*(?:"([^"]*)"|'([^']*)'|(\d+))\s*(,|$)''')
    out = bytearray()
    pos = 0
    while pos < len(value):
        match = token.match(value, pos)
        assert match is not None, value[pos:]
        if match.group(1) is not None:
            out.extend(match.group(1).encode('ascii'))
        elif match.group(2) is not None:
            out.extend(match.group(2).encode('ascii'))
        else:
            number = int(match.group(3))
            assert 0 <= number <= 255
            out.append(number)
        pos = match.end()
        if match.group(4) == '':
            break
    assert value[pos:].strip() == ''
    return bytes(out)

ids = [('BADOPM', 3), ('CRLFM', 4), ('BadParm', 22), ('BADSIZ_PRE', 5),
       ('BADLD_PRE', 6), ('BADCOM', 7), ('BADCOUNTRY', 8), ('BADCOUNTRYCOM', 9),
       ('INSUFMEMORY', 10), ('BADMEM', 11), ('BADBLOCK', 12), ('BADSTACK', 13),
       ('BADORDER', 14), ('ERRORCMD', 15), ('toomanydrivesmsg', 24)]
lines = source.decode('ascii').splitlines()
assert len(lines) == len(ids)
parts = []
entries = []
for line, (label, number) in zip(lines, ids):
    match = re.fullmatch(r'\s*(\w+)\s+DB\s+(.*)', line, re.I)
    assert match and match.group(1).lower() == label.lower(), label
    data = parse_values(match.group(2))
    assert data == parse_values(reference_rows[number]), label
    parts.append(data)
    entries.append({'label': label, 'nt_message_id': number, 'length': len(data), 'sha256': sha(data)})
payload = b''.join(parts)
map_data = (stage / 'msbio.map').read_bytes()
rows = re.findall(r'(?im)^\s*([0-9A-F]{4}):([0-9A-F]{4})\s+badopm\s*$', map_data.decode(errors='replace'))
positions = {int(seg, 16) * 16 + int(offset, 16) for seg, offset in rows}
assert len(positions) == 1
start = positions.pop()
bios = (stage / 'msbio.bin').read_bytes()
target = (root / 'extras/build/target-io-inspect.bin').read_bytes()
assert sha(bios) == build['output']['sha256'] and sha(target) == 'dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0'
assert payload == bios[start:start + len(payload)] == target[0x5a6 + start:0x5a6 + start + len(payload)]
report = {'stage': str(stage), 'source_sha256': sha(source), 'reference_sha256': sha(reference),
          'bios_sha256': sha(bios), 'map_sha256': sha(map_data), 'target_offset': start,
          'length': len(payload), 'entries': entries, 'source_reference_and_target_equal': True,
          'scope': '15 source messages, their NT message entries, and the linked target byte interval. No fresh build, runtime or complete resource provenance claim.'}
(evidence / 'm5-bios-message-source-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'entries': len(entries), 'length': len(payload), 'target_offset': start,
                  'source_reference_and_target_equal': True}, indent=2))
