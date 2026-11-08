"""Verify restored local environment and AUTOEXEC/startup tail instruction layouts."""
from pathlib import Path
import argparse
import json
import re
import tempfile
from target_fat12 import inspect

root = Path(__file__).resolve().parent.parent.parent
ap = argparse.ArgumentParser()
ap.add_argument('--report', default='m2-t3-startup-tail-build.json')
ap.add_argument('--output', default='m2-t3-environment-verification.json')
args = ap.parse_args()
if any(Path(n).name != n for n in (args.report, args.output)):
    raise ValueError('report and output must be filenames')
stage = Path(json.loads((root/'extras/docs/etc/evidence'/args.report).read_text())['stage'])
symbols = {}
for line in (stage/'command.map').read_text(encoding='latin1').splitlines():
    m = re.match(r'\s*([0-9A-Fa-f]{4}):([0-9A-Fa-f]{4})\s+(\S+)\s*$', line)
    if m:
        symbols[m[3].lower()] = int(m[1], 16)*16+int(m[2], 16)-256

def listing(name):
    labels, mask = {}, set()
    for line in (stage/(name+'.lst')).read_text(encoding='latin1').splitlines():
        m = re.match(r' ([0-9A-F]{4})  (.*?)\\(.*)', line)
        if not m:
            continue
        pos = int(m[1], 16)
        label = re.match(r'\s*(\w+):', m[3])
        if label:
            labels[label[1].lower()] = pos
        previous = []
        for token in m[2].split():
            token = token.rstrip(':/')
            if token in ('E', 'R'):
                mask.update(previous)
            elif re.fullmatch('[0-9A-F]{2}|[0-9A-F]{4}', token):
                previous = list(range(pos, pos+len(token)//2))
                pos += len(token)//2
    return labels, mask

with tempfile.TemporaryDirectory(prefix='dos5-environment-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
checks = []
for module, first, last, public, target_start, extra in [
    ('rdata', 'adjust_env', 'nomem_err', 'endinit', 0x27c, 3),
    ('init', 'dodate', 'drv0', 'conproc', 0x197d, 0),
]:
    labels, mask = listing(module)
    bias = symbols[public]-labels[public]
    start, end = labels[first], labels[last]+extra
    differences = [i-start for i in range(start, end)
                   if i not in mask and candidate[bias+i] != target[target_start+i-start]]
    assert not differences, (module, differences)
    if module == 'init':
        # Drv0 lies at the end of this slice: both exits must now encode
        # identically, including the formerly differing branch operands.
        assert candidate[bias+start+86:bias+start+89] == target[target_start+86:target_start+89]
        assert candidate[bias+start+149:bias+start+151] == target[target_start+149:target_start+151]
    checks.append({'module': module, 'candidate_start': bias+start, 'target_start': target_start,
                   'length': end-start, 'unmasked_differences': differences,
                   'masked_offsets': sorted(i-start for i in mask if start <= i < end)})
assert 'SVC_GETINITENVIRONMENT' not in (root/'cmd/command/rdata.asm').read_text()
out = {'checks': checks, 'limitation': 'MASM-annotated address words masked; full layout and guest execution remain unverified.'}
(root/'extras/docs/etc/evidence'/args.output).write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps(out, indent=2))
