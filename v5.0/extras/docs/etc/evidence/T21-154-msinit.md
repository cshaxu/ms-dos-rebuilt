# T21 file 154: dos/msinit.asm

Reviewed the complete DOS6 diff and the complete whitespace-insensitive OpenNT
diff, using raw reference text to check the changed/commented regions.

Changes: restored DOS6 comments for DPBHead, the BIOS parameter pushes and
BiosDataPtr stores; corrected the country-information comment from '.dosinit.'
to the reference 'dosinit.'; restored 18 unambiguous reference whitespace lines.
The latter match identical non-whitespace text while preserving quoted strings.
DOS EOF bytes remain intact. No instruction, external declaration order,
include order, conditional or data definition changed in this edit.

Remaining differences have these dispositions:

- OpenNT's dossvc/cmdsvc/dbgsvc/doswow includes, SCS/VDM symbols, debugger and
  host initialization calls, host DPB retrieval and WOW pointer fixups remain
  removed. Native CLI, SFT cluster/name initialization, physical device/DPB
  traversal and buffer-head setup match DOS6's native counterparts. The
  restored native DPB loop is not a host wrapper or parallel implementation.
- DOS6's ROMDOS initialization-segment/far-wrapper machinery, Rational386Patch
  setup and two-call WhatCPUType wrapper are absent. The disk DOS5 path uses
  the original OpenNT-lineage direct get_cpu_type macro and DOSCODE init.
  Introducing those later/configuration-specific paths changes layout or adds
  unused code. Existing ROMDOS conditions within the imported DPB loop are
  retained exactly; no original empty branch is removed by this audit.
- The native DOS6 JNE patch_vec_seg replaces OpenNT's two-branch sequence;
  no_patch is still an original OpenNT label, not a second implementation.
  WORD PTR operands for the IBM interrupt-vector stores follow OpenNT and
  resolve to the same native stores. Declaration/include placement and short
  header follow OpenNT; there is no reason to fabricate DOS6 header provenance
  or reorder extern records purely for display.
- The removed DOS6 M060 commented-out version-table copy and dangling DPUBLIC
  names have no active counterpart in this build. Actual version-table comments
  already present are preserved. Buffer-head initialization stays live; do not
  restore DOS6's misleading 'unused, remove this' comment onto that path.
  Remaining blank-line/comment-marker differences do not create a new code path.

Whole-word BOP/NTVDM/VDM/NTIO/DOSSVC/CMDSVC/DBGSVC/SVC/DOSWOW scan of current
msinit.asm returns no hits. The full OpenNT diff identifies the removed host
call sites, rather than treating keyword absence alone as proof.

Verification: extras/build/t21-dos-29948-7739; parent t21-dos-29103-9182.
Recompiled all 55 DOS objects using original NMAKE/MASM on an isolated compiler
desktop. All raw objects, including MSINIT.OBJ, and linked MSDOS.SYS are
byte-identical to parent. MSDOS.SYS and inherited IO.SYS/COMMAND.COM match the
frozen targets; the latter two were not recompiled. All 243 source/stage checks
pass before/after. Stage audit-object-compare.log, audit-*-compare.log,
audit-inputs-*.log, dos/AUDIT.LOG and result.txt retain the evidence.

Prefix 154/243: 15 modified (14 source/build plus one metadata relocation),
117 reference-identical, 22 necessary differences retained. Remaining 89.
Next: 155 dos/msproc.asm.
