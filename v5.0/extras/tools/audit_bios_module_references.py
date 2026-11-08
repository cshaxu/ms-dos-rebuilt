"""Compare IO.SYS candidate modules with same-named source references."""
from pathlib import Path
import collections
import difflib
import hashlib
import json
import re
from sysimes_source import active_lines

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
NT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios')
DOS6 = ROOT.parent / 'v6.0/bios'
package = Path(json.loads((EVIDENCE / 'm6-source-package-candidate.json').read_text())['stage'])
bios = json.loads((EVIDENCE / 'm5-bios-singleconfig-probe.json').read_text())
loader = json.loads((EVIDENCE / 'm5-msload-candidate-build.json').read_text())
stage, loader_stage = Path(bios['stage']), Path(loader['stage'])
digest = lambda data: hashlib.sha256(data).hexdigest()
names = re.findall(r'[A-Za-z_][A-Za-z_0-9]*', (ROOT / 'bios/msbio.lnk').read_text().split(',')[0])
assert len(names) == 15 and names == [unit['name'] for unit in bios['units']]
assert bios['output']['equal'] and digest((stage/'msbio.bin').read_bytes()) == bios['output']['sha256']
assert loader['output']['target_prefix_equal'] and digest((loader_stage/'msload.com').read_bytes()) == loader['output']['sha256']

def compare(data, path):
    if not path.is_file(): return {'status': 'missing'}
    ref = path.read_bytes()
    matcher = difflib.SequenceMatcher(None, ref.decode('latin1').splitlines(), data.decode('latin1').splitlines(), autojunk=False)
    blocks = [x for x in matcher.get_opcodes() if x[0] != 'equal']
    return {'status': 'identical' if data == ref else 'different', 'sha256': digest(ref),
            'changed_blocks': len(blocks), 'reference_lines_in_changes': sum(j-i for _,i,j,_,_ in blocks),
            'candidate_lines_in_changes': sum(l-k for _,_,_,k,l in blocks)}

records = []
for unit in bios['units']:
    name = unit['name']; data = (ROOT/'bios'/f'{name}.asm').read_bytes()
    assert data == (package/'bios'/f'{name}.asm').read_bytes()
    configured = data
    if name in {'sysinit1', 'sysinit2', 'sysconf'}:
        assert configured.count(b'MULTI_CONFIG equ 1') == 1
        configured = configured.replace(b'MULTI_CONFIG equ 1', b';MULTI_CONFIG equ 1')
    retained = (stage/'src'/f'{name}.asm').read_bytes()
    if name in {'sysimes', 'msend'}:
        assert active_lines(configured) == active_lines(retained)
    else:
        assert configured == retained
    assert digest(retained) == bios['inputs']['src\\' + name + '.asm']
    assert digest((stage/f'{name}.obj').read_bytes()) == unit['object_sha256']
    refs = {'opennt': compare(data, NT/f'{name}.asm'), 'dos6': compare(data, DOS6/f'{name}.asm')}
    records.append({'module': name, 'source_sha256': digest(data), 'configured_sha256': digest(configured), 'retained_sha256': digest(retained),
                    'object_sha256': unit['object_sha256'], 'references': refs})
data = (ROOT/'bios/msload.asm').read_bytes()
assert data == (package/'bios/msload.asm').read_bytes() == (loader_stage/'msload.asm').read_bytes()
assert digest(data) == loader['inputs']['msload.asm']
records.append({'module': 'msload', 'source_sha256': digest(data), 'object_sha256': digest((loader_stage/'msload.obj').read_bytes()),
                'references': {'opennt': compare(data, NT/'msload.asm'), 'dos6': compare(data, DOS6/'msload.asm')}})
summary = {ref: dict(collections.Counter(row['references'][ref]['status'] for row in records)) for ref in ('opennt', 'dos6')}
report = {'bios_stage': str(stage), 'loader_stage': str(loader_stage), 'package': str(package),
          'summary': summary, 'modules': records,
          'scope': 'Same-named current references for 15 BIOS modules and MSLOAD; SYSIMES and MSEND are compared to retained source by literal active statements, other BIOS modules by bytes. Retained object hashes checked; not proof of ancestry, fresh assembly, or runtime behavior.'}
(EVIDENCE/'m6-io-module-reference-inventory.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps({'modules': len(records), 'summary': summary, 'scope': report['scope']}, indent=2))
