"""Require whole-file equality to the pinned target; retain source identities."""
from pathlib import Path
import argparse
import hashlib
import json
import tempfile
from target_fat12 import inspect
from command_build_provenance import retained_inputs

root = Path(__file__).resolve().parent.parent.parent
ap = argparse.ArgumentParser()
ap.add_argument('--report', default='m2-t3-command-identity-build.json')
ap.add_argument('--output', default='m2-t3-command-exact-verification.json')
args = ap.parse_args()
if any(Path(n).name != n for n in (args.report, args.output)):
    raise ValueError('report/output must be filenames')
report_path = root/'extras/docs/etc/evidence'/args.report
report = json.loads(report_path.read_text())
stage = Path(report['stage'])
with tempfile.TemporaryDirectory(prefix='dos5-command-exact-') as d:
    inspect(Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img'), Path(d))
    target = (Path(d)/'COMMAND.COM').read_bytes()
candidate = (stage/'command.com').read_bytes()
sha = lambda b: hashlib.sha256(b).hexdigest()
assert sha(target) == '74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89'
assert candidate == target, f'Full target mismatch: candidate={len(candidate)}, target={len(target)}'
assert report['output_sha256'] == sha(candidate)
inputs = retained_inputs(report)
out = {'build_report': args.report, 'build_report_sha256': sha(report_path.read_bytes()),
       'stage': str(stage), 'bytes': len(candidate), 'sha256': sha(candidate),
       'full_byte_comparison': True, 'different_bytes': 0,
       'retained_build_inputs': inputs,
       'limitation': 'COMMAND.COM equality only. IO.SYS/MSDOS.SYS reconstruction, source-package completion and VM deployment are not proved.'}
(root/'extras/docs/etc/evidence'/args.output).write_text(json.dumps(out, indent=2), encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k != 'retained_build_inputs'}, indent=2))
