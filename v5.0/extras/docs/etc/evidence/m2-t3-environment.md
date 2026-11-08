# M2 T3 S1 local environment and startup completion slice

Removed the NT host-environment branch in `rdata.asm`; allocation failure
now reaches `nomem_err` directly and successful allocation copies the old
environment. Target COMMAND.COM 0x27C independently confirms this path.
The 113-byte adjust_env-through-nomem_err slice matches with MASM-annotated
address words excluded. Retained DOS 5 Chuckenv semantics: DOS 6 uses a
different flag and branch, which were not imported.

Restored the suppressed `InitAdd` date/time call and conditional copyright
printing in `init.asm`. The target 0x197D-to-0x1A61 region is 228 bytes.
These 17 source bytes explain and eliminate the prior AUTOEXEC exit-branch
differences. The first jump now naturally assembles near; no encoding patch
was introduced. Both exit jump encodings, including displacement, match.
Other annotated address operands remain layout constraints, not exact matches.

Restored permanent COMMAND `$EXIT` recycling to TCOMMAND in `tcmd2b.asm`,
replacing the NT host-exit service and INT 3. Target 0x4439 has the expected
22-byte decision prefix. Verification checks opcode layout, all three data
operand identities, and the jump destination (target TCOMMAND 0x2324).
DOS 6 independently corroborates this source path.

Final clean build report: `m2-t3-exit-build.json`; 48,318 bytes, SHA-256
`6680cbb7cc92f6a4b07cad5eb7245ec8556c26fe86f270ef9bbddfbb5a976d85`.
The intermediate environment-only build has unchanged file size because
EndInit overlays reserved pipe-buffer storage; removing instructions there
does not necessarily shrink the image. The final file remains unequal to
the 47,845-byte target. No guest boot is claimed.

Reproduce from project root:

```powershell
python tools/build_command.py --report m2-t3-exit-build.json
python tools/verify_exit.py
python tools/verify_init_environment.py --report m2-t3-exit-build.json --output m2-t3-exit-environment-verification.json
python tools/verify_command_entry.py docs/etc/evidence/m2-t3-exit-build.json --length 0x2f7 --output m2-t3-exit-entry-verification.json
```

Similar-issue scan found no remaining `CMDSVC`, `SVC_`, `FCLI`, or `FSTI`
uses in local COMMAND `.asm` files after these edits. This is a textual
inventory only, not proof of removal of every NT adaptation or host dependency.
Remaining work includes whole-module layout, data/message restoration, binary
identity and runtime verification. The 759-byte entry regression check remains
passing modulo address operands. S1 and the overall goal remain active.
