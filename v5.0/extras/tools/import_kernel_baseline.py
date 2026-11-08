"""Import only the reviewed kernel dependency plan; never overwrite local edits."""
from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parent.parent.parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
plan=json.loads((root/'extras/docs/etc/evidence/m4-t5-kernel-dependencies.json').read_text())
assert not plan['unresolved']
before={str(p):sha(p) for folder in ['cmd/command','inc','messages']
        for p in (root/folder).rglob('*') if p.is_file()}
for row in plan['files']:
    source=Path(row['source']);dest=root/row['destination']
    assert dest.resolve().is_relative_to(root.resolve())
    assert sha(source)==row['sha256']
    assert not dest.exists() or sha(dest)==row['sha256'],f'Would overwrite {dest}'
for row in plan['files']:
    dest=root/row['destination'];dest.parent.mkdir(parents=True,exist_ok=True)
    if not dest.exists():shutil.copyfile(row['source'],dest)
    assert sha(dest)==row['sha256']
assert all(sha(Path(path))==digest for path,digest in before.items())
out={'files':plan['files'],'preexisting_command_input_files_preserved':len(before),
     'status':'Untouched OpenNT kernel baseline imported, not DOS 5 reconstruction.',
     'rights':'Existing source notices retained; local technical import only, no publication or redistribution determination.'}
(root/'extras/docs/etc/evidence/m4-t5-kernel-import.json').write_text(json.dumps(out,indent=2),encoding='utf-8')
print(f"Imported/reused {len(plan['files'])} pinned files; preserved {len(before)} preexisting files")
