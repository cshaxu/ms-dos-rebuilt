"""Report ordered source-review progress and verify completed file evidence."""
import hashlib
import json
from pathlib import Path
from nt_residue import scan_bytes

ROOT = Path(__file__).resolve().parent.parent.parent
LEDGER = ROOT / 'extras/docs/etc/file-review-ledger.json'
ROOTS = ('bios', 'dos', 'cmd/command', 'inc', 'messages')


def recorded_path(name):
    path = Path(name)
    if not path.is_absolute() and path.parts and path.parts[0] in ('docs', 'research', 'tools', 'tests', 'build'):
        return ROOT / 'extras' / path
    return ROOT / path


def main():
    ledger = json.loads(LEDGER.read_text(encoding='utf-8'))
    files = ledger['files']
    extensions = set(ledger['extensions'])
    actual = []
    for root in ROOTS:
        actual.extend(sorted((p.relative_to(ROOT).as_posix() for p in (ROOT / root).rglob('*')
                              if p.is_file() and p.suffix.lower() in extensions), key=str.casefold))
    if actual != [item['path'] for item in files if item['status'] != 'retired'] or ledger['total'] != len(files):
        raise ValueError('file universe or order changed; reconcile explicitly before continuing')
    cache = {}
    counts = {'reviewed': 0, 'auto_round1': 0, 'auto_round2': 0, 'retired': 0, 'pending': 0}
    next_item = None
    for index, item in enumerate(files, 1):
        if item['index'] != index:
            raise ValueError('invalid file sequence')
        status = item['status']
        if status == 'pending':
            counts['pending'] += 1
            if next_item is None:
                next_item = item
            continue
        if status == 'retired':
            if next_item is not None:
                raise ValueError('retirement skipped an earlier pending file')
            if (ROOT / item['path']).exists():
                raise ValueError(f'retired source unexpectedly present: {item["path"]}')
            data = recorded_path(item['archive']).read_bytes()
            evidence = json.loads(recorded_path(item['evidence']).read_text(encoding='utf-8'))
            digest = hashlib.sha256(data).hexdigest()
            if (digest != item['reviewed_sha256'] or evidence['reviewed_sha256'] != digest or
                evidence['index'] != index or evidence['file'] != item['path'] or
                evidence['archive'] != item['archive'] or evidence['status'] != 'retired'):
                raise ValueError(f'retirement evidence mismatch: {item["path"]}')
            counts['retired'] += 1
            continue
        if status not in ('reviewed', 'auto_qualified'):
            raise ValueError(f'unknown status: {status}')
        if status == 'reviewed' and next_item is not None:
            raise ValueError('manual review skipped an earlier pending file')
        content = (ROOT / item['path']).read_bytes()
        hits = scan_bytes(content)
        if hits:
            raise ValueError(f'completed file has NT/BOP or later-version review leads: {item["path"]}: {hits[0]}')
        digest = hashlib.sha256(content).hexdigest()
        if digest != item['reviewed_sha256']:
            raise ValueError(f'completed file changed: {item["path"]}')
        name = item['evidence']
        if name not in cache:
            cache[name] = json.loads(recorded_path(name).read_text(encoding='utf-8'))
        evidence = cache[name]
        if status == 'reviewed':
            if evidence['index'] != index or evidence['file'] != item['path'] or evidence['reviewed_sha256'] != digest:
                raise ValueError(f'review evidence mismatch: {item["path"]}')
            counts['reviewed'] += 1
        else:
            matches = [x for x in evidence['results'] if x['index'] == index]
            if len(matches) != 1 or matches[0]['file'] != item['path'] or matches[0]['sha256'] != digest or matches[0]['round'] != item['automatic_round']:
                raise ValueError(f'automatic evidence mismatch: {item["path"]}')
            counts['auto_round' + str(item['automatic_round'])] += 1
    print(json.dumps({'total': len(files), **counts, 'qualified': counts['reviewed'] + counts['auto_round1'] + counts['auto_round2'],
                      'next': {'index': next_item['index'], 'path': next_item['path']} if next_item else None},
                     ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
