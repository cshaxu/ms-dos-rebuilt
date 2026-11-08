"""Classify local BIOS/include variants without changing build inputs."""
from pathlib import Path
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
BIOS = ROOT / 'bios/inc'
COMMON = ROOT / 'inc'
EVIDENCE = ROOT / 'extras/docs/etc/evidence/m6-bios-include-variants.json'
NOTICE = re.compile(r"(?m)^;\s*\r?\n;\s*Microsoft Confidential\s*\r?\n;\s*Copyright \(C\) Microsoft Corporation 1991\s*\r?\n;\s*All Rights Reserved\.\s*\r?\n;\s*\r?\n")
DETAILS = {
    'dosmac.inc': 'BIOS retains ROMDOS-specific getdseg branch.',
    'ioctl.inc': 'BIOS defines A_DEVICEPARAMETERS and A_TRACKREADWRITEPACKET; common versions are commented out.',
    'msbdata.inc': 'BIOS retains OEM configuration, ROMEXEC and ROMDOS data branches.',
    'mult.inc': 'BIOS includes additional multiplex definitions and documentation.',
    'syscall.inc': 'BIOS retains ROMEXEC function definitions.',
    'version.inc': 'BIOS and kernel select different build configuration switches.',
}

def digest(data):
    return hashlib.sha256(data).hexdigest()

def comparison_lines(data):
    text = data.decode('latin1').replace('\x1a', '')
    text = NOTICE.sub('', text)
    return [line for line in text.splitlines() if line.strip()]

def main():
    records = []
    for bios in sorted(BIOS.iterdir(), key=lambda p: p.name.lower()):
        if not bios.is_file():
            continue
        common = COMMON / bios.name
        if not common.is_file():
            continue
        left, right = bios.read_bytes(), common.read_bytes()
        if left == right:
            raise ValueError(f'Duplicate files are now identical: {bios.name}')
        name = bios.name.lower()
        simple = comparison_lines(left) == comparison_lines(right)
        if simple == (name in DETAILS):
            raise ValueError(f'Classification changed: {bios.name}')
        records.append({'name': name, 'bios_sha256': digest(left),
                        'common_sha256': digest(right),
                        'classification': 'notice-whitespace-eof' if simple else 'other-differences',
                        'detail': DETAILS.get(name, 'Comparison ignores only the specified notice, blank lines and DOS EOF characters.')})
    if {item['name'] for item in records if item['classification'] == 'other-differences'} != set(DETAILS):
        raise ValueError('Variant universe changed')
    result = {'records': records, 'count': len(records),
              'scope': 'Byte and narrowly normalized text comparison only; not proof of runtime equivalence or source authorship.'}
    EVIDENCE.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'count': len(records),
                      'notice_whitespace_eof': sum(x['classification'] == 'notice-whitespace-eof' for x in records),
                      'other_differences': sorted(DETAILS)}, indent=2))

if __name__ == '__main__':
    main()
