"""Audit retained integrated-build tools and recorded generated messages."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
audit = json.loads((ROOT / 'extras/docs/etc/evidence/m6-fresh-integrated-source-audit.json').read_text())
integrated = Path(audit['stage']).resolve()
if not integrated.is_relative_to((ROOT / 'extras/build').resolve()):
    raise ValueError('Integrated build is outside the project build directory')
digest = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
components = {}
for name in ('msload', 'bios', 'kernel', 'command'):
    report = json.loads((integrated / (name + '-report.json')).read_text(encoding='utf-8-sig'))
    stage = Path(report['stage']).resolve()
    if not stage.is_relative_to((ROOT / 'extras/build').resolve()):
        raise ValueError(f'{name}: stage outside project build directory')
    recorded = report.get('tools', report.get('tool_hashes', report.get('inputs', {})))
    tools = {key: value for key, value in recorded.items() if key.lower().endswith('.exe')}
    if not tools:
        raise ValueError(f'{name}: no recorded tool hashes')
    for filename, expected in tools.items():
        if digest(stage / filename) != expected:
            raise ValueError(f'{name}: tool mismatch: {filename}')
    messages = report.get('messages', {})
    for filename, expected in messages.items():
        if digest(stage / filename) != expected:
            raise ValueError(f'{name}: message mismatch: {filename}')
    # COMMAND's build report did not record generated message hashes. Record
    # the retained files as observations, not as independently verified inputs.
    observed = {}
    if name == 'command':
        observed = {p.name: digest(p) for p in sorted(stage.glob('COMMAND.CL?'))}
    components[name] = {'recorded_tools_verified': tools,
                        'recorded_messages_verified': messages,
                        'unattested_retained_messages': observed}
print(json.dumps({'components': components,
                  'scope': 'Retained files versus build reports; does not establish all transitive dependencies or historical COMMAND message bytes.'}, indent=2))
