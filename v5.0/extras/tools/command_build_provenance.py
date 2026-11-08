"""Read only retained COMMAND build inputs, without inferring past sources."""
from pathlib import Path
import hashlib
from command_source_snapshot import inventory

def retained_inputs(report):
    stage = Path(report['stage'])
    digest = lambda data: hashlib.sha256(data).hexdigest()
    source_snapshot = report.get('source_snapshot')
    if source_snapshot is not None:
        actual = inventory(stage / 'src')
        if actual != source_snapshot:
            raise ValueError('retained COMMAND source snapshot does not match build report')
        return {'mode': 'build-stage-source-snapshot', 'files': actual,
                'scope': 'Full recorded source snapshot verified against retained build-stage files; assembler selection is not independently proven.'}
    files = {}
    for item in report['objects']:
        name = item['name']
        obj = stage / (name + '.obj')
        if digest(obj.read_bytes()) != item['sha256']:
            raise ValueError(f'retained COMMAND object mismatch: {name}')
        source = stage / (name + '.asm')
        files[source.name] = digest(source.read_bytes())
    for name in ('command.lnk', 'command.skl', 'usa-ms.msg', 'usa-ms.idx'):
        files[name] = digest((stage / name).read_bytes())
    return {'mode': 'legacy-stage-inputs-only', 'files': files,
            'scope': 'Retained linked module copies and four staged inputs only; shared includes were read in place and their historical bytes are not established.'}
