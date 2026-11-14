# M6 T21 completion audit

Status: verified and closed. Scope is the owner's 243-file DOS5 reference-
difference audit, not a claim of new historical-source provenance or closure
of unrelated M6 work. T20 S4 remains deferred.

## Requirement-to-evidence audit

Requirement | Observed evidence | Disposition
--- | --- | ---
Frozen dir /a /b /s file order; no skipping | T21-final-order-check.log checks all 243 entries against the admission queue and raw directory line positions | Passed; sole documented relocation is metadata entry 80
Audit every differing file against OpenNT/DOS6/DOS4 | T21-file-ledger.csv has 193 exact references and 50 differing entries, each disposed in sequential T21 evidence records | Passed; 20 modified, 30 necessary differences retained
Use reference structure/style where target permits | Per-file evidence identifies restored original statements, dependency blocks, comments and formatting and explains retained version/layout/native-path differences | Passed; 19 source/build modifications plus one metadata relocation
Do not restore NT/BOP code merely for textual identity | Per-file full-diff review; final word/symbol scans of source, headers, message inputs and recipes return no hits | Passed within the source audit; scanning alone is not historical-origin proof
Compile each changed file before advancing | T21-modified-builds.csv maps every modified entry to its accepted build; final checker matches current source hashes to those staged inputs, requires PASS and verifies all three outputs in each stage | Passed; metadata relocation has a full build verification but is not a compiler input
No change to compiled results | T21-final-object-compare.log compares all 104 objects (15 BIOS, 55 DOS, 34 COMMAND) to accepted pre-change object baselines | Passed byte-for-byte
Three artifacts strictly match target | Full clean build cmd-32179-8869; direct FC /B gate passed and final verifier independently hashes targets, fresh build and published assets | Passed for all three
Maintain frozen inputs and evidence | T21-final-source-proof.csv validates current files and earlier proof hashes; 1087 reference-candidate hashes revalidated | Passed; initial hashes/classifications unchanged
Keep metadata in extras and use authorized tools | Existing metadata file moved at entry 80; evidence retained under extras/docs; C/CMD tooling, isolated compiler desktop, no Computer Use or forbidden scratch directory | Passed

## Final build and counts

Command: `call O:\repos.hobby\ms-dos-rebuilt\v5.0\extras\build.cmd <nul`.
Stage: `extras/build/cmd-32179-8869`. Exit code 0. Original BUILDIDX/NMAKE/MASM/
LINK/RELOC/STRIPZ pipeline compiled the three components; production source
snapshots before/after matched. Publication to `extras/assets` succeeded only
after all three comparisons. Manual build output and final PAUSE remain intact.

Completed: **243/243**. **20 modified** (19 source/build, one metadata relocation),
**193 reference-identical**, **30 necessary differences retained**, **0 pending**.
These are audit dispositions, not a claim that each modified file becomes
whole-file identical to an original reference.

Artifact | Bytes | SHA256 (target = fresh build = published asset)
--- | ---: | ---
IO.SYS | 33430 | dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0
MSDOS.SYS | 37394 | 4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2
COMMAND.COM | 47845 | 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89

All 243 ledger inputs were checked against the final build stage. 242 match
directly; the unchanged original USA-MS.MSG source is checked against its
frozen hash because native BUILDIDX rewrites offsets in its staged copy. The
relocated metadata was copied into stage/extras/docs after compilation solely
for this audit check, not supplied to the compiler.

## Evidence and limits

Evidence under `../etc/evidence/`: T21-final-verification.log,
T21-final-source-proof.csv, T21-final-order-check.log,
T21-final-object-compare.log, T21-final-stagecheck.log,
T21-modified-builds.csv, T21-admission-queue.csv and the sequential T21 records.
The final source hash check also verifies all earlier per-file proof hashes;
entries 1-10 use frozen hashes or their accepted compiled-stage hashes.

The broad substring scan found ordinary words such as 'conventional',
'attention' and native FCBOp names; whole-word NT/BOP and host-prefix scans
returned no matches. This supplements explicit reference-diff review.

Existing TODOs about original media/rights and optional POWER message provenance
are not hidden or closed. POWER is disabled in the byte-exact target build;
its original enabled-runtime wording remains outside this task's acceptance.
No VM acceptance was run or required by the owner. Exact reconstruction is
not a license to retrofit later DOS6 fixes into the target's behavior.

The closure predicate is satisfied: every frozen file has a justified final
disposition, each edit has compilation evidence, all final object bytes are
unchanged and all three published binaries strictly match the original targets.
