"""Reconstruct CPMIO2 from pinned NTIO source and physical-DOS changes."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
nt_path = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos\cpmio2.asm')
dos6_path = ROOT.parent/'v6.0/dos/cpmio2.asm'
candidate_path = ROOT/'kernel-source/dos/cpmio2.asm'
package = Path(json.loads((EVIDENCE/'m6-source-package-candidate.json').read_text())['stage'])
build = json.loads((EVIDENCE/'m4-t5-consolidated-kernel-build.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
nt, dos6, candidate = nt_path.read_bytes(), dos6_path.read_bytes(), candidate_path.read_bytes()
assert sha(nt) == 'be1c1ac94665ee5a222ec215a8cb7bfa2cf9c5383168128b0ddb90eac072a1a0'
assert candidate == dos6 == (package/'kernel-source/dos/cpmio2.asm').read_bytes()
anchor = b'\tNAME\tCPMIO2\r\n'
description = b';**\tOld style CP/M 1-12 system calls to talk to reserved devices'
assert nt.count(anchor) == dos6.count(anchor) == 1
assert nt.count(description) == dos6.count(description) == 1
nt_start = nt.index(anchor) + len(anchor); nt_end = nt.index(description)
dos_start = dos6.index(anchor) + len(anchor); dos_end = dos6.index(description)
assert nt[nt_start:nt_end] == b'\r\n'
header = dos6[dos_start:dos_end]
assert b'Microsoft Confidential' in header and b'Copyright (C) Microsoft Corporation 1991' in header
derived = nt[:nt_start] + header + nt[nt_end:]
assert derived.count(b'        invoke      DOCLI') == 1
derived = derived.replace(b'        invoke      DOCLI', b'\tCLI', 1) + b'\x1a'
assert derived == candidate
assert sha(candidate) == build['source_snapshot']['dos\\cpmio2.asm']
assert candidate == (stage/'src/dos/cpmio2.asm').read_bytes()
object_data = (stage/'cpmio2.obj').read_bytes()
assert sha(object_data) == build['objects']['cpmio2']
assert sha((stage/'msdos.sys').read_bytes()) == build['output_sha256'] and build['exact']
report = {'nt_sha256': sha(nt), 'dos6_sha256': sha(dos6), 'candidate_sha256': sha(candidate),
          'object_sha256': sha(object_data), 'kernel_sha256': build['output_sha256'],
          'transformations': ['Preserve DOS 6 reference copyright header.',
                              'Replace NT DOCLI call with physical CLI.',
                              'Preserve DOS 6 reference trailing DOS EOF byte.'],
          'byte_exact_source_reconstruction': True,
          'scope': 'One linked module and retained exact kernel build; source transformation is not a claim of original DOS 5 authorship or complete runtime behavior.'}
(EVIDENCE/'m6-cpmio2-nt-recovery.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
