# COMMAND reconstruction status

The complete 34-module COMMAND build produces the 47,845-byte DOS 5.00
COMMAND.COM exactly. It builds resources and objects from maintained sources
without reusing experimental probe objects. Run `v5.0/extras/build.cmd`;
verified outputs go to `v5.0/extras/assets`.

Build evidence: `etc/evidence/quality-cmd-build.json`. Earlier fixed-address
ForOff probes and intermediate recovery variants were retired; see
`etc/evidence/quality-research-retirement.json`.

Byte equality does not prove exact historical Microsoft source provenance.

This project-authored note was moved from `cmd/command/RECONSTRUCTION.md`
during T21 file 80 audit. The original queue ordinal and initial hash are
preserved; the relocation is recorded in `etc/T21-relocations.csv`.
