# T21 file 78: cmd/command/rdata.asm

Complete OpenNT/DOS6 diffs reviewed. Restored the two-line DOS6 pathname
buffer comment (including its historical Bugbug note); the declaration remains
64+3+13 zero bytes. No instructions, data, labels or directives changed.

Necessary differences retained:

- No OpenNT cmdsvc include, SCS/redirector host state, Io_Stderr storage or
  host initial-environment service. DOS6 corroborates native allocation/copy
  and direct nomem_err handling. No second environment implementation remains.
- Batch filename allocation/copy uses 15+1/16 bytes, matching DOS6, rather
  than OpenNT's expanded temporary-name buffers.
- Chuckenv ownership test and LoadHiFlg match the older OpenNT implementation
  and the already accepted INIT/COMMAND2/LOADHI callers. DOS6's AllocedEnv
  polarity and highvar declarations belong to its later implementation.
- No DOS6 /K SemiPermCom word or ROM extended-address GDT. Adding either
  would change the selected target data layout and introduce unused features.
- EnvirSeg formatting matches DOS6; surrounding original comments and
  historical notes match the applicable DOS6/OpenNT paragraphs.

Whole-word NT host/BOP scan found no hits. Validation is required before
advancing to file 79; the new affected-COMMAND stage verifies all maintained
source inputs, all 34 COMMAND objects and all three targets. IO/DOS are inherited
from the verified full parent build, not newly compiled in this step.

Validation passed in t21-command-24906-25576 (parent cmd-24194-8951), exit 0.
All 34 object files and COMMAND.COM are byte-identical to the accepted build;
IO.SYS, MSDOS.SYS and COMMAND.COM match frozen targets. Fresh evidence is in
audit-inputs-before/after.log, audit-object-compare.log, audit-*-compare.log,
cmd/command/AUDIT.LOG and result.txt. Copied full-build snapshots are inherited,
not fresh evidence. No publication was needed because output bytes are unchanged.

Prefix 78/243: 7 modified and verified, 59 exact, 12 necessary differences.
Next: 79 cmd/command/readme.txt.
