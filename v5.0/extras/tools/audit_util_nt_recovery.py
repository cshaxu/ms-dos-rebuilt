"""Reconstruct UTIL from NT source plus bounded physical-DOS changes."""
from pathlib import Path
import hashlib
import json

ROOT = Path(__file__).resolve().parent.parent.parent
EVIDENCE = ROOT/'extras/docs/etc/evidence'
nt_path = Path(r'O:\repos.external\OpenNT\base\mvdm\dos\v86\doskrnl\dos\util.asm')
dos6_path = ROOT.parent/'v6.0/dos/util.asm'
package = Path(json.loads((EVIDENCE/'m6-source-package-candidate.json').read_text())['stage'])
build = json.loads((EVIDENCE/'m4-t5-consolidated-kernel-build.json').read_text())
stage = Path(build['stage'])
sha = lambda data: hashlib.sha256(data).hexdigest()
nt, dos6 = nt_path.read_bytes(), dos6_path.read_bytes()
candidate = (ROOT/'kernel-source/dos/util.asm').read_bytes()
assert sha(nt) == '8e9636bad8d717e7e9daa6ec3a9e36eb6563969dfae2bf9bab47d232bdfe4889'
assert candidate == dos6 == (package/'kernel-source/dos/util.asm').read_bytes()

anchor = b'\tNAME\tUTIL\r\n'
description = b';**\tHandle related utilities for MSDOS 2.X.'
assert nt.count(anchor) == dos6.count(anchor) == nt.count(description) == dos6.count(description) == 1
start = nt.index(anchor) + len(anchor); end = nt.index(description)
ref_start = dos6.index(anchor) + len(anchor); ref_end = dos6.index(description)
header = dos6[ref_start:ref_end]
assert nt[start:end] == b'\r\n' and b'Copyright (C) Microsoft Corporation 1991' in header
derived = nt[:start] + header + nt[end:]

def once(old, new):
    global derived
    if derived.count(old) != 1: raise ValueError(f'expected one match: {old!r}')
    derived = derived.replace(old, new, 1)

once(b'RESTORE <BX>\t\t\t; restore', b'RESTORE <BX>\t\t    ; restore')
once(b'sfnf10:\r\n\tmov\tax,Proc_ID',
     b'sfnf10:\tfmt\tTypAccess,LevSFN,<"$p: SFT $x:$x($x)is busy, owner $x:$x\\n">,<ES,DI,BX,es:[DI].sf_UID,es:[DI].sf_pid>\r\n'
     b'\tmov\tax,User_ID\r\n\tcmp\tes:[DI].SF_UID,ax\r\n\tjnz\tsfnf7\t\t\t; not ours\r\n\tmov\tax,Proc_ID')
once(b'sfnf20:\r\n\tmov\tes:[DI.sf_ref_count],sf_busy\t; make sure that this is allocated\r\n\tmov\tax,Proc_ID',
     b'sfnf20: fmt\tTypAccess,LevSFN,<"$p: SFT $x:$x($x) marked busy\\n">,<ES,DI,bx>\r\n'
     b'\tmov\tes:[DI.sf_ref_count],sf_busy\t; make sure that this is allocated\r\n'
     b'\tmov\tax,User_ID\r\n\tmov\tes:[DI].SF_UID,ax\r\n\tmov\tax,Proc_ID')
derived += b'\x1a'
assert derived == candidate
assert sha(candidate) == build['source_snapshot']['dos\\util.asm']
assert candidate == (stage/'src/dos/util.asm').read_bytes()
object_data = (stage/'util.obj').read_bytes()
assert sha(object_data) == build['objects']['util']
assert sha((stage/'msdos.sys').read_bytes()) == build['output_sha256'] and build['exact']
report = {'nt_sha256': sha(nt), 'dos6_sha256': sha(dos6), 'candidate_sha256': sha(candidate),
          'object_sha256': sha(object_data), 'kernel_sha256': build['output_sha256'],
          'transformations': ['Preserve the DOS 6 reference copyright header and EOF byte.',
                              'Restore the DOS 6 User_ID/SF_UID ownership comparison and assignment, and associated fmt lines.',
                              'Preserve DOS 6 reference whitespace in one comment.'],
          'byte_exact_source_reconstruction': True,
          'scope': 'One linked UTIL module and retained exact kernel build; not proof of original DOS 5 authorship or comprehensive file-sharing behavior.'}
(EVIDENCE/'m6-util-nt-recovery.json').write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
print(json.dumps(report, indent=2))
