"""Inventory linked source/object identities against DOS and OpenNT references."""
from pathlib import Path
import argparse
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'
OPENNT = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
DOS6 = ROOT.parent / 'v6.0'
DOS4 = ROOT.parent / 'v4.0/src'
REFERENCE_DIRS = {
    'msload': (OPENNT/'doskrnl/bios', DOS6/'bios', DOS4/'BIOS'),
    'bios': (OPENNT/'doskrnl/bios', DOS6/'bios', DOS4/'BIOS'),
    'kernel': (OPENNT/'doskrnl/dos', DOS6/'dos', DOS4/'DOS'),
    'command': (OPENNT/'cmd/command', DOS6/'cmd/command', DOS4/'CMD/COMMAND'),
}

# DOS 4 used a different filename for the dispatch table and placed its
# linked data/message wrapper modules in INC rather than DOS. Other missing
# names are not inferred to be aliases without evidence.
REFERENCE_ALIASES = {
    ('kernel', 'mstable', 'dos4'): 'MS_TABLE.ASM',
    ('kernel', 'msdata', 'dos4'): '../INC/MSDATA.ASM',
    ('kernel', 'msdosme', 'dos4'): '../INC/MSDOSME.ASM',
}

# DOS 4 BIOS grouped these routines differently. These are partial lineage
# leads, not substitutes for a whole-module source comparison.
PARTIAL_DOS4 = {
    ('bios', 'mschar'): (
        ('MSCON.ASM', ('con_read', 'con_writ', 'con_rdnd')),
        ('MSAUX.ASM', ('aux_read', 'aux_writ', 'aux_rdnd')),
        ('MSLPT.ASM', ('prn_writ', 'prn_genioctl', 'prn_stat')),
        ('MSCLOCK.ASM', ('tim_read', 'tim_writ', 'time_to_ticks')),
    ),
    ('bios', 'msdioctl'): (
        ('MSIOCTL.INC', ('getdeviceparameters', 'setdeviceparameters', 'formattrack')),
    ),
    ('bios', 'msint13'): (
        ('MSDISK.ASM', ('doblock', 'doblockcontinue', 'doint')),
    ),
}


def defined_labels(data):
    names = set()
    for line in data.decode('latin1').splitlines():
        line = line.split(';', 1)[0]
        match = re.match(r'(?i)^\s*(?:procedure\s+([\w?$@]+)|([\w?$@]+)\s+(?:proc|label)\b|([\w?$@]+):)', line)
        if match:
            names.add(next(part for part in match.groups() if part).lower().replace('$', '_'))
    return names

def digest(data):
    return hashlib.sha256(data).hexdigest()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--stage', required=True)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    if Path(args.stage).name != args.stage or not args.stage.startswith('integrated-source-'):
        parser.error('invalid integrated stage name')
    if Path(args.report).name != args.report:
        parser.error('report must be a filename')
    out = EVIDENCE / args.report
    if out.exists():
        raise FileExistsError(out)
    build = json.loads((EVIDENCE / f'm6-integrated-{args.stage}.json').read_text())
    stage = (ROOT/'extras/build'/args.stage).resolve()
    if not stage.is_relative_to((ROOT/'extras/build').resolve()) or Path(build['stage']).resolve() != stage:
        raise ValueError('invalid integrated stage')
    reports = {n: json.loads((stage/f'{n}-report.json').read_text()) for n in REFERENCE_DIRS}
    rows = []
    for group in REFERENCE_DIRS:
        report = reports[group]
        component_stage = Path(report['stage']).resolve()
        if not component_stage.is_relative_to((ROOT/'extras/build').resolve()):
            raise ValueError('component stage outside build')
        if group == 'msload':
            units = [('msload', None)]
        elif group == 'bios':
            units = [(x['name'], x['object_sha256']) for x in report['units']]
        elif group == 'kernel':
            units = list(report['objects'].items())
        else:
            units = [(x['name'], x['sha256']) for x in report['objects']]
        for name, expected_obj in units:
            rel = Path('bios' if group in ('msload','bios') else 'dos' if group == 'kernel' else 'cmd/command') / f'{name}.asm'
            path = ROOT / rel
            data = path.read_bytes()
            staged = (component_stage / f'{name}.asm').read_bytes()
            if data != staged:
                raise ValueError(f'current source differs from compiled source: {rel}')
            obj = (component_stage / f'{name}.obj').read_bytes()
            objhash = digest(obj)
            if expected_obj is not None and objhash != expected_obj:
                raise ValueError(f'object hash differs from report: {name}')
            refs = {}
            for label, directory in zip(('opennt','dos6','dos4'), REFERENCE_DIRS[group]):
                alias = REFERENCE_ALIASES.get((group, name.lower(), label))
                reference = directory / (alias or f'{name}.asm')
                if not reference.is_file():
                    refs[label] = {'status': 'missing'}
                else:
                    refdata = reference.read_bytes()
                    refs[label] = {'status': 'identical' if data == refdata else 'different',
                                   'sha256': digest(refdata), 'path': str(reference)}
                    if alias:
                        refs[label]['mapping'] = 'historical path mapping'
            partial = []
            for filename, anchors in PARTIAL_DOS4.get((group, name.lower()), ()):
                reference = DOS4 / 'BIOS' / filename
                refdata = reference.read_bytes()
                if not set(anchors) <= (defined_labels(data) & defined_labels(refdata)):
                    raise ValueError(f'partial-reference anchors changed: {name} {filename}')
                partial.append({'path': str(reference), 'sha256': digest(refdata),
                                'matched_routine_names': list(anchors),
                                'scope': 'partial DOS 4 BIOS correspondence; $ and _ normalized'})
            rows.append({'group': group, 'module': name, 'source': rel.as_posix(),
                         'source_sha256': digest(data), 'object_sha256': objhash,
                         'references': refs, 'partial_dos4_references': partial})
    expected = 1 + len(reports['bios']['units']) + len(reports['kernel']['objects']) + len(reports['command']['objects'])
    if len(reports['bios']['units']) not in (14, 15) or expected not in (104, 105):
        raise ValueError('unexpected module counts')
    if len(rows) != expected or len({(x['group'], x['module'].lower()) for x in rows}) != expected:
        raise ValueError('unexpected module universe')
    summary = {}
    for label in ('opennt','dos6','dos4'):
        summary[label] = {state: sum(x['references'][label]['status'] == state for x in rows)
                          for state in ('identical','different','missing')}
    result = {'stage': str(stage), 'summary': summary, 'modules': rows,
              'scope': 'Linked modules; full references use exact source bytes. Missing means no whole-module mapping; partial DOS 4 references are listed separately. Differences are review leads, not style or authorship verdicts.'}
    out.write_text(json.dumps(result, indent=2)+'\n', encoding='utf-8')
    print(json.dumps({'modules': len(rows), 'summary': summary, 'report': str(out)}, indent=2))

if __name__ == '__main__':
    main()
