"""Inventory current PE imports without running the historical build tools."""
from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import sys

from preflight_source_build import checks


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    objdump = shutil.which('objdump')
    if not objdump:
        raise SystemExit('objdump is required for this read-only inventory')
    selected = {'masm', 'dosbox', 'runner'}
    roots = [(name, path) for name, path, _ in checks if name in selected]
    roots.append(('python', Path(sys.executable)))
    result = []
    for label, root in roots:
        queue = [root]
        seen = set()
        files = []
        while queue:
            path = queue.pop(0)
            key = str(path.resolve()).casefold()
            if key in seen:
                continue
            seen.add(key)
            run = subprocess.run([objdump, '-p', str(path)], capture_output=True,
                                 text=True, errors='replace', check=True)
            imports = sorted(set(re.findall(r'^\s*DLL Name:\s*(\S+)', run.stdout,
                                            flags=re.MULTILINE)), key=str.casefold)
            local = {p.name.casefold(): p for p in path.parent.iterdir() if p.is_file()}
            resolved = []
            for name in imports:
                candidate = local.get(name.casefold())
                if candidate:
                    queue.append(candidate)
                resolved.append({'name': name, 'adjacent': str(candidate) if candidate else None})
            files.append({'path': str(path), 'sha256': digest(path), 'imports': resolved})
        result.append({'root': label, 'files': files})
    report = {'tool': objdump, 'roots': result,
              'scope': 'Static PE import tables and recursive adjacent DLLs observed now. '
                       'No DLL was loaded, and imports resolved elsewhere, delay/dynamic loads, '
                       'Python modules, OS dependencies and historical DLL hashes are not established.'}
    print(json.dumps(report, indent=2))


if __name__ == '__main__':
    main()
