# M4 T23 S1: DOS 6.21 audit

Local source order follows the frozen DIR output.

Ordinal | Path | Disposition
--- | --- | ---
1 | cmd/command/tcmd2a.asm | Retain necessary difference: explicit minor 21 after clearing AH replaces DOS6 byte exchange; all other source identical
2 | lang/usa/messages/comimsg.inc | Retain without same-name DOS6 source; existing resmsg.equ macro, CR/LF constants and RESGROUP help-pointer list match DOS6 interfaces; preserve target version/help text

No local source edit is justified. Local counts: modified 0, reference-identical
0, necessary difference 1, no same-name reference 1.

One tooling input repaired: extras/tools/dosbuild/baseline.lst. Exactly four
pins updated for T22 changes in bios/sysinit1.asm, bios/sysinit2.asm,
cmd/command/copy.asm and cmd/command/dir.asm. Old pins were checked against T22
entry hashes; all 225 current baseline hashes checked against the accepted T22
build input copy. Other pins and integrity guards remain unchanged.

The merged 225-input scope was verified against the fresh build input copy.
Two inputs are local; 223 inherit reviewed T22 source. Current source quality
classes: 194 exact DOS6, 27 necessary differences, 4 no same-name reference.
This includes inherited T22 changes, not 27 new modifications in this task.

Verification: extras/build/cmd-16751-1050. Original CMD/BAT compiler pipeline;
source snapshots before/after; direct FC/B of all three outputs to the version's
frozen targets; assets published only after all three pass. Retained evidence:
621-pins.txt, merged-inputs.csv, input-check.txt, build-result.txt.

S1 exit criteria: both local inputs audited, inherited coverage verified,
stale pins repaired without changing compiler logic, three outputs exact.
S2 owns the separate six-file DOS 6.22 overlay; no v6.22 source edited in S1.
