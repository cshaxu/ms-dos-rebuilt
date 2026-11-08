"""Generate a deterministic per-file SHA-256 inventory of scoped source inputs."""
import argparse
import hashlib
from pathlib import Path

SCOPES = {
    'opennt-bios': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\bios'),
    'opennt-dos': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos'),
    'opennt-command': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\cmd\command'),
    'opennt-inc': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\inc'),
    'opennt-h': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\h'),
    'opennt-messages': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\messages'),
    'dos6-bios': Path(r'O:\repos.hobby\ms-dos-archaeology\v6.0\bios'),
    'dos6-dos': Path(r'O:\repos.hobby\ms-dos-archaeology\v6.0\dos'),
    'dos6-command': Path(r'O:\repos.hobby\ms-dos-archaeology\v6.0\cmd\command'),
    'dos6-inc': Path(r'O:\repos.hobby\ms-dos-archaeology\v6.0\inc'),
    'dos4-bios': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\BIOS'),
    'dos4-dos': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\DOS'),
    'dos4-command': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\CMD\COMMAND'),
    'dos4-inc': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\INC'),
    'dos4-h': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\H'),
    'dos4-messages': Path(r'O:\repos.hobby\ms-dos-archaeology\v4.0\src\MESSAGES'),
}

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    rows = ['scope\tpath\tbytes\tsha256']
    for name, base in SCOPES.items():
        if not base.is_dir(): raise SystemExit(f'missing scope: {name}: {base}')
        for file in sorted((p for p in base.rglob('*') if p.is_file()), key=lambda p: p.relative_to(base).as_posix().lower()):
            if file.is_symlink(): raise SystemExit(f'symlink requires review: {file}')
            data = file.read_bytes()
            rel = file.relative_to(base).as_posix()
            if any(c in rel for c in '\t\n\r'): raise SystemExit('invalid filename')
            rows.append(f'{name}\t{rel}\t{len(data)}\t{hashlib.sha256(data).hexdigest()}')
    args.output.write_text('\n'.join(rows)+'\n', encoding='utf-8', newline='\n')
    print(f'{len(rows)-1} files; sha256 {hashlib.sha256(args.output.read_bytes()).hexdigest()}')

if __name__ == '__main__': main()
