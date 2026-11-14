# Current state: DOS 5 reference-difference audit complete

M6 T21 S1 is **verified and closed**. No active S remains in v5.0.

- Completed fixed queue: **243/243**, remaining **0**.
- Modified: **20** — 19 source/build files and one metadata relocation.
- Reference-identical: **193**. Necessary differences retained: **30**.
- Final clean build: `extras/build/cmd-32179-8869`, exit 0.
- All **104 objects** byte-identical to accepted baselines.
- IO.SYS, MSDOS.SYS and COMMAND.COM match frozen targets exactly and are
  published in `extras/assets`.

Authorities: [completion audit](../history/M6-T21-completion-audit.md),
[file ledger](../etc/T21-file-ledger.csv),
[final source hashes](../etc/evidence/T21-final-source-proof.csv),
[final verification](../etc/evidence/T21-final-verification.log),
[reference candidates](../etc/T21-reference-candidates.csv).
The final S1 packet is retained in history/M6-T21-S1-final-packet.md.

Original constraints remain: CMD/BAT/C tools, no Computer Use, no D:/temp or
D:/tempu; preserve byte-exact artifacts and original Microsoft structure/style.
Existing provenance/optional-POWER limitations remain in TODO.md.
T20 S4 for v7.10.1111 remains deferred; this closure does not resume other work.
