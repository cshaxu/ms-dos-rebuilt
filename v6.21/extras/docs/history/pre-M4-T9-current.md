# Current state

Direct read-only image extraction and the final build were compared byte for byte; map and listing locate the four VER instruction differences and the remaining banner byte. Isolated guard tests reject changed baseline, changed overlay, missing overlay, and unlisted overlay. See [image and diff evidence](../etc/image-and-diff-evidence.json) and [guard tests](../etc/overlay-guard-test.json).

M0–M3: selected image and frozen v6.20 baseline recorded; binary differences mapped; two source overlays restored and the clean merged build matches all three target files. See [target baseline](../etc/target-baseline.json), [binary comparison](../etc/binary-comparison-initial.json), [file ledger](../etc/file-ledger.json), [five-byte mapping](../etc/binary-difference-map.json), and [build verification](../etc/overlay-build-verification.json).

- 220 baseline inputs: 218 inherited unchanged, 2 modified and retained in the overlay.
- `cmd/command/tcmd2a.asm`: VER uses the target's constant minor version 21; an intermediate build reduced COMMAND differences from five bytes to the banner byte alone.
- `lang/usa/messages/comimsg.inc`: version banner is 6.21.
- IO.SYS and MSDOS.SYS target bytes equal the 6.20 image; their source is inherited without changes.

Build with `python extras/tools/build_three.py`. It verifies every inherited baseline hash and the exact overlay inventory, merges into ignored `extras/build`, and compares all outputs. Tools, DOSBox, GCC and the ignored target files remain local dependencies.
