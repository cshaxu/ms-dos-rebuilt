# M4 T23 completion audit

Requirement | Evidence
--- | ---
Audit both versions | S1-audit.md covers v6.21; S2-audit.md covers v6.22; all eight local files dispositioned
Fixed DIR order | Each version retains dir-raw.txt and local-inventory.csv with raw ordinals; native enumeration confirms 2 and 6 local source files, no extras counted as source
Only DOS6 quality reference | Local source diffs use v6.0 paths; merged inventories classify actual bytes against corresponding v6.0 files; absent language sources explicitly labeled
Do not restart inherited audit | All 225 baseline hashes checked against accepted T22 build inputs; T22 dispositions reused for inherited files; 223/219 inherited merged inputs verified
Reduce needless differences | CRATIO original comment restored; remaining local instruction/data differences justified in S audits; no duplicate path or invented helper introduced
Preserve overlays/structure | Local source inventories remain 2 and 6; both builds still merge v6.2 directly using original recipes; no full source copy added
Repair build inputs | v6.21 baseline.lst and v6.22 baseline.lst update precisely four proven T22 hashes each; v6.22 overlay.lst updates precisely one edited source hash; guards unchanged
Compile edited file before advancing | v6.22 CRATIO edit included in cmd-17372-11632 and target-verified before later files accepted
Exact version outputs | v6.21 cmd-16751-1050 completed automatically; v6.22 cmd-17372-11632 compiled with BUILD.OK=PASS but timed out at runner exit. Independent 241-record post-snapshot check and FC/B of all three generated files passed; all six existing assets compared directly to their own targets. Original timeout result retained, no automatic-build success claimed for v6.22
No source drift | merged-inputs.csv/input-check.txt validate all 225 current effective source inputs against each verified build copy
Record counts and limitations | Local 6.21: 0 modified/0 exact/1 necessary/1 absent reference. Local 6.22: 1 modified/0 exact/3 necessary/2 absent reference. Merged exact counts 194/193. Original wording of absent language references is not claimed
Execution constraints | CMD/BAT/C and isolated compiler runner only; no Computer Use, forbidden temp paths, other script languages, worktrees or subagents

T23 is complete with no outstanding transfer. Source changes: one local file.
Tooling changes: three manifest files total. All six outputs retain their
respective frozen target bytes. This proves the selected three-core builds,
not every optional configuration or unavailable original source wording.

Observed limitation: v6.22's isolated compiler runner hit its existing 60-second
exit deadline after compilation completed. The source audit and byte-identity
criteria are independently proven; no claim is made that this invocation of
build.cmd completed automatically. Compiler logic and runner timeout policy
were not altered to conceal the event.
