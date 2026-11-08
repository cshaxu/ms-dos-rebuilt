"""Lexical include inventory, deliberately not a MASM conditional evaluator."""
from pathlib import Path
import re
import json

base = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')
command = base / 'cmd/command'
search = [command, base / 'inc', base.parent.parent / 'inc', base / 'messages']
pending = sorted(command.glob('*.asm'))
seen, edges = set(), []
while pending:
    path = pending.pop()
    if path in seen:
        continue
    seen.add(path)
    for line, text in enumerate(path.read_text(encoding='latin1').splitlines(), 1):
        match = re.match(r'\s*include\s+([^;\s]+)', text, re.I)
        if not match:
            continue
        name = match[1].strip('"<>')
        resolved = next((p / name for p in search if (p / name).is_file()), None)
        edges.append({'source': str(path), 'line': line, 'include': name,
                      'resolved': str(resolved) if resolved else None})
        if resolved is not None:
            pending.append(resolved)
print(json.dumps({'scope': 'COMMAND lexical include graph; all branches; no macro expansion',
                  'files_scanned': len(seen), 'edges': edges}, indent=2))
