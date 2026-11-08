"""Copy and verify COMMAND build sources without invoking build tools."""
from pathlib import Path
import hashlib
import shutil

COMMAND_SUFFIXES = {'.asm', '.inc', '.equ', '.h', '.c', '.skl', '.lnk', '.md', '.txt'}
MESSAGE_NAMES = ('usa-ms.msg', 'usa-ibm.msg', 'comimsg.inc', 'comrmsg.inc')

def inventory(root, include_research=True):
    root = Path(root)
    files = []
    for directory in ('cmd/command', 'inc'):
        for path in (root / directory).rglob('*'):
            if (directory == 'inc' and not include_research and
                    path.relative_to(root / directory).parts[0].lower() in {'kernel', 'ntvdm'}):
                continue
            if path.is_symlink():
                raise ValueError(f'symlink in source tree: {path}')
            if path.is_file() and (directory != 'cmd/command' or path.suffix.lower() in COMMAND_SUFFIXES or path.name.lower() in {'makefile', 'makefil0'}):
                files.append(path)
    files.extend(root / 'messages' / name for name in MESSAGE_NAMES)
    result = {}
    for path in sorted(files):
        relative = path.relative_to(root).as_posix()
        if relative.lower() in {item.lower() for item in result}:
            raise ValueError(f'case-insensitive filename collision: {relative}')
        result[relative] = hashlib.sha256(path.read_bytes()).hexdigest()
    return result

def snapshot(root, destination, include_research=True):
    root, destination = Path(root), Path(destination)
    before = inventory(root, include_research=include_research)
    destination.mkdir(parents=True, exist_ok=False)
    for relative in before:
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(root / relative, target)
    if (inventory(destination, include_research=include_research) != before or
            inventory(root, include_research=include_research) != before):
        raise ValueError('COMMAND source changed while snapshotting')
    return before
