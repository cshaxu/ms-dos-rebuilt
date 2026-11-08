# M2 T3 S1 AUTOEXEC reconstruction

Restored the OpenNT-disabled local AUTOEXEC/KAUTOEXE initialization in
`cmd/command/init.asm` and filename declarations in `uinit.asm`. Removed the
host temporary-name request and its DS switch. DOS 6 corroborates the local
path; its additional BIOS boot-option logic was not imported. Target bytes
at COMMAND.COM 0x197D independently corroborate the restored instructions.
Re-enabled the two startup drive-letter stores. Restored the original
16-byte filename allowance in both allocation sites and the resident copy
in `rdata.asm`: four paragraphs allocated, 33+16 bytes copied.

Reproduce from the project root:

```powershell
python tools/build_command.py --report m2-t3-autoexec-build.json
python tools/verify_autoexec.py
```

Clean build: 48,304 bytes, SHA-256
`bb3f5f6ca4b4f2a320ba365f022c9c6ec8744d5d04b13e6462f8129d5e9cfa90`.
Tool/input identities are retained in `m2-t3-autoexec-build.json`.
Target remains 47,845 bytes and unequal; size difference is not coverage.

Verification checks both filename strings byte-for-byte, both allocation
operands, and the resident copy length. The 166-byte DoDate-to-OpenErr
region has four differences outside MASM-annotated address operands:
relative offsets 86–88 and 150. Candidate first exit is short JMP + NOP,
target first exit is near JMP; the second is a short JMP with a different
displacement. Both candidate exits resolve to its Drv0; both target exits
resolve to target 0x1A61. The candidate downstream path is shorter; these
differences are explicitly retained, not patched or silently masked.
The initial strict equality assertion caught them; the final check verifies
their branch semantics and records them as unresolved encoding/layout debt.

Similar-issue sweep covered both BatchSegment allocation sites, the resident
copy, declarations/publics, and drive-letter stores. NT environment handling
in resident initialization remains outstanding. Full layout, target identity,
and guest execution have not been verified. This is a partial S1 delivery,
not closure of T3 or the overall goal.
