# Windows 95 A / MS-DOS 7.0 baseline assessment

## Target

The target is the local `msdosw95a_boot.img`, recorded in [target-baseline.json](target-baseline.json). The read-only FAT12 extraction checked both FAT copies, target cluster chains and SHA-256 hashes. Its MSDOS.SYS is exactly `;SYS\r\n`, a six-byte file from this boot image, not a DOS 6.x executable kernel; it is not evidence of the default configuration of every Windows 95 A installation. IO.SYS and COMMAND.COM both begin with an MZ header. Their structures require investigation before treating any portion as directly comparable to the plain DOS 6.x output.

## Candidate comparison

Exact overlapping 16-byte windows from the entire 7.0a target were sought in each reference image. This is an exploratory, address-sensitive heuristic, not instruction-level similarity, source provenance, or an estimate of work; repeated sequences and file layout affect the figures. See [binary-similarity.json](binary-similarity.json) for counts and hashes.

| Reference | IO.SYS target windows | COMMAND.COM target windows |
| --- | ---: | ---: |
| 5.0 | 6.693% | 47.629% |
| 6.0 | 7.628% | 49.817% |
| 6.20 | 7.631% | 50.272% |
| 6.22 | 7.632% | 50.241% |

## Decision

Use the existing v6.22 layered source as the provisional starting point, with v6.20 directly available for targeted comparison. Both are substantially closer than 5.0 or 6.0 in this limited measurement; the 6.20 versus 6.22 difference is too small to establish ancestry, and for COMMAND.COM 6.20 scored marginally higher. The choice of v6.22 is a practical baseline choice: it already includes the later DriveSpace/DoubleSpace changes and has a verified byte-exact build. It is not a claim that every 7.0a module is closer to 6.22, nor that a small diff will suffice. Choose individual 6.20 implementations if binary-level evidence supports them.

Next, map the MZ headers and sections, identify any packing/compression and separate DOS kernel, BIOS/boot and command interpreter regions. Use map/listing data and target instruction/string anchors to locate the corresponding sources, then rebuild in file order. Windows 95-specific components that have no source counterpart require separate recovery; the six-byte MSDOS.SYS needs configuration reproduction, not kernel source reconstruction. Preserve the original Microsoft source style and record changed/inherited files in a ledger. Do not claim binary identity before building and comparing all targets.
