"""Qualify frozen source files against local historical reference trees."""
from pathlib import Path
import collections
import difflib
import hashlib
import json
import subprocess
from nt_residue import scan_bytes

ROOT = Path(__file__).resolve().parent.parent.parent
LEDGER = ROOT / 'extras/docs/etc/file-review-ledger.json'
EVIDENCE = ROOT / 'extras/docs/etc/evidence/file-review-automatic-rounds.json'
REFERENCES = {'dos6': ROOT.parent / 'v6.0', 'dos4': ROOT.parent / 'v4.0',
              'opennt': Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86')}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def code_lines(data, suffix):
    """Keep exact code spelling and literals; drop only comments and edge whitespace."""
    lines = []
    for number, raw in enumerate(data.decode('cp437').replace('\x1a', '').splitlines(), 1):
        if suffix.lower() in ('.c', '.h'):
            # C punctuation differs from assembly; retain comments conservatively.
            line = raw.strip()
        else:
            quote = None
            cut = len(raw)
            i = 0
            while i < len(raw):
                c = raw[i]
                if quote:
                    if c == quote:
                        if i + 1 < len(raw) and raw[i+1] == quote:
                            i += 2
                            continue
                        quote = None
                elif c in ('"', "'"):
                    quote = c
                elif c == ';':
                    cut = i
                    break
                i += 1
            line = raw[:cut].strip()
        if line:
            lines.append((number, line))
    return lines


def main():
    if EVIDENCE.exists():
        raise FileExistsError(EVIDENCE)
    ledger = json.loads(LEDGER.read_text(encoding='utf-8'))
    pending = [x for x in ledger['files'] if x['status'] == 'pending']
    wanted = {Path(x['path']).name.casefold() for x in pending}
    refs = collections.defaultdict(list)
    for label, tree in REFERENCES.items():
        tree = tree.resolve()
        paths = subprocess.run(['rg', '--files', '--hidden', str(tree)], capture_output=True,
                               text=True, encoding='utf-8', check=True).stdout.splitlines()
        for path in sorted(paths, key=str.casefold):
            p = Path(path)
            if p.name.casefold() in wanted:
                data = p.read_bytes()
                refs[p.name.casefold()].append({'reference': label, 'path': str(p),
                                                 'sha256': digest(data), 'bytes': data})
    rows = []
    for item in pending:
        path = ROOT / item['path']
        data = path.read_bytes()
        sha = digest(data)
        # Identical reference content is not sufficient if it contains NT/BOP leads.
        if scan_bytes(data):
            continue
        candidates = refs[path.name.casefold()]
        exact = [r for r in candidates if r['bytes'] == data]
        if exact:
            chosen = [{'reference': r['reference'], 'path': r['path'], 'sha256': r['sha256']} for r in exact]
            rows.append({'index': item['index'], 'file': item['path'], 'sha256': sha,
                         'round': 1, 'references': chosen})
            continue
        source = code_lines(data, path.suffix)
        if not source:
            continue
        coverage = [None] * len(source)
        for ref in candidates:
            other = code_lines(ref['bytes'], path.suffix)
            matcher = difflib.SequenceMatcher(None, [v for _, v in source],
                                               [v for _, v in other], autojunk=False)
            for a, b, size in matcher.get_matching_blocks():
                # Isolated common statements do not establish a matching passage.
                if size < 2:
                    continue
                for k in range(size):
                    if coverage[a+k] is None:
                        coverage[a+k] = (ref['reference'], ref['path'], ref['sha256'], other[b+k][0])
            if all(coverage):
                break
        if not all(coverage):
            # A complete in-order match in one file may include isolated lines
            # separated by reference-only additions.
            coverage = []
            if len(source) >= 2:
                for ref in candidates:
                    other = code_lines(ref['bytes'], path.suffix)
                    cursor = 0
                    candidate = []
                    for _, line in source:
                        while cursor < len(other) and other[cursor][1] != line:
                            cursor += 1
                        if cursor == len(other):
                            break
                        candidate.append((ref['reference'], ref['path'], ref['sha256'], other[cursor][0]))
                        cursor += 1
                    if len(candidate) == len(source):
                        coverage = candidate
                        break
            if not coverage:
                continue
        passages = []
        for (line_no, _), (label, refpath, refsha, refline) in zip(source, coverage):
            if (passages and passages[-1]['reference_path'] == refpath and
                passages[-1]['source_line_end'] + 1 == line_no and
                passages[-1]['reference_line_end'] + 1 == refline):
                passages[-1]['source_line_end'] = line_no
                passages[-1]['reference_line_end'] = refline
            else:
                passages.append({'source_line_start': line_no, 'source_line_end': line_no,
                                 'reference': label, 'reference_path': refpath,
                                 'reference_sha256': refsha,
                                 'reference_line_start': refline, 'reference_line_end': refline})
        rows.append({'index': item['index'], 'file': item['path'], 'sha256': sha,
                     'round': 2, 'code_lines': len(source), 'passages': passages})
    # Confirm every candidate remains unchanged before writing any qualification.
    for row in rows:
        if digest((ROOT / row['file']).read_bytes()) != row['sha256']:
            raise ValueError('source changed during scan: ' + row['file'])
    report = {'method': 'Round 1 compares complete bytes of same-name files. Round 2 removes assembly comments and blank lines, strips edge whitespace, retains code spelling and string contents, then covers every code line with exact contiguous matching blocks of at least two lines from same-name references. C/H comments are retained conservatively. Matching blocks may come from different reference versions.',
              'limitations': 'This is textual qualification, not proof of historical DOS 5 origin, macro expansion, cross-file behavior, or target binary identity. Conservative matching can leave eligible files pending.',
              'results': rows}
    EVIDENCE.write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
    by_index = {r['index']: r for r in rows}
    for item in ledger['files']:
        row = by_index.get(item['index'])
        if row:
            item.update(status='auto_qualified', reviewed_sha256=row['sha256'],
                        evidence=EVIDENCE.relative_to(ROOT).as_posix(), automatic_round=row['round'])
    LEDGER.write_text(json.dumps(ledger, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'round1': sum(r['round']==1 for r in rows),
                      'round2': sum(r['round']==2 for r in rows),
                      'remaining': sum(x['status']=='pending' for x in ledger['files'])}, indent=2))


if __name__ == '__main__':
    main()
