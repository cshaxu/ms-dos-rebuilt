"""Classify source differences in a fresh linked-module inventory.

This is a triage aid, not a semantic or provenance equivalence test.
"""
from pathlib import Path
import argparse
import difflib
import hashlib
import json
import re

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT / 'extras/docs/etc/evidence'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def normalized_lines(data):
    # DOS sources may contain multiple trailing CP/M EOF markers.
    data = re.sub(rb'(?:\x1a(?:\r\n|\r|\n)*)+$', b'', data)
    return data.decode('latin1').splitlines()


def compare(source, reference):
    if source == reference:
        return {'class': 'byte_identical', 'changed_hunks': 0,
                'source_lines': 0, 'reference_lines': 0}
    src = normalized_lines(source)
    ref = normalized_lines(reference)
    if src == ref:
        return {'class': 'line_endings_or_eof_only', 'changed_hunks': 0,
                'source_lines': 0, 'reference_lines': 0}
    changes = [op for op in difflib.SequenceMatcher(None, ref, src, autojunk=False).get_opcodes()
               if op[0] != 'equal']
    return {'class': 'content_review_required', 'changed_hunks': len(changes),
            'source_lines': sum(j2-j1 for _, _, _, j1, j2 in changes),
            'reference_lines': sum(i2-i1 for _, i1, i2, _, _ in changes)}


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--inventory', required=True)
    parser.add_argument('--report', required=True)
    args = parser.parse_args()
    for name in (args.inventory, args.report):
        if Path(name).name != name:
            parser.error('inventory and report must be filenames')
    output = EVIDENCE / args.report
    if output.exists():
        raise FileExistsError(output)
    inventory = json.loads((EVIDENCE / args.inventory).read_text(encoding='utf-8'))
    rows = []
    for item in inventory['modules']:
        source = (ROOT / item['source']).read_bytes()
        if digest(source) != item['source_sha256']:
            raise ValueError(f"source changed since inventory: {item['source']}")
        references = {}
        for name, info in item['references'].items():
            if info['status'] == 'missing':
                references[name] = {'class': 'missing'}
                continue
            reference = Path(info['path']).read_bytes()
            if digest(reference) != info['sha256']:
                raise ValueError(f"reference changed since inventory: {info['path']}")
            references[name] = compare(source, reference)
        rows.append({'group': item['group'], 'module': item['module'],
                     'source': item['source'], 'source_sha256': item['source_sha256'],
                     'object_sha256': item['object_sha256'], 'references': references})
    summary = {}
    for name in ('opennt', 'dos6', 'dos4'):
        summary[name] = {kind: sum(row['references'][name]['class'] == kind for row in rows)
                         for kind in ('byte_identical', 'line_endings_or_eof_only',
                                      'content_review_required', 'missing')}
    result = {'inventory': args.inventory, 'stage': inventory['stage'], 'summary': summary,
              'modules': rows,
              'scope': 'Line-oriented triage only. Content differences include comments, '
                       'formatting and executable changes. Equality or similarity does not '
                       'establish original DOS 5 authorship, semantics or style completion.'}
    output.write_text(json.dumps(result, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'modules': len(rows), 'summary': summary, 'report': str(output)}, indent=2))


if __name__ == '__main__':
    main()
