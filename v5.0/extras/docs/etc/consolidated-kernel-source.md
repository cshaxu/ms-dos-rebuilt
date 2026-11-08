# Consolidated kernel source candidate

`kernel-source/dos` and `kernel-source/inc` contain the 126 input files used
by the consolidated kernel build. This is a working reconstruction assembled
from the previously verified staged sources, not a claim that the files are an
original Microsoft source release. The DOS 6-like directory layout is
provisional. Existing root-level recovery files remain the provenance and
investigation record; this candidate has not yet been promoted over them.

Run `python tools/build_reconstructed_kernel.py` in the project root. The
script copies the candidate into a fresh `build/reconstructed-kernel-*`
directory, regenerates the four message includes, assembles 55 modules and
links, relocates and strips the result. It depends on the tool paths and the
verified isolated-desktop launcher named in the script; it is not yet a
self-contained distribution. The script compares the result directly with the
original image when available, otherwise with the SHA-256-pinned extracted
kernel. It records the exact input and object hashes in the evidence report.

Two separate builds used identical 126 source inputs and produced identical
55 object hashes, generated message hashes and 37394-byte MSDOS.SYS files.
Both outputs match the pinned extracted target byte for byte, SHA-256
`4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2`.
See [first build](evidence/m4-t5-consolidated-kernel-build-1.json) and
[second build](evidence/m4-t5-consolidated-kernel-build-2.json). The original
image was unavailable during these builds; comparison against it remains
required when accessible.

After these builds, recovery-specific commentary was moved out of seven
candidate source files. BUF and CURDIR use the DOS 6 comparative sources;
DISKREAD contains bounded disk routines with a shared return point; DIR2
contains the recovered search initializer, CDS validation and device syntax;
MSINIT contains the physical block-driver and DPB initialization path;
MSCONST omits the NTVDM-only DosWowDataStart pointer; and ORIGIN uses the
provisional target-derived DOS code origin. These are reconstruction facts,
not claims of historical authorship. The [post-edit build](evidence/m4-t5-consolidated-kernel-build.json)
matches all 55 pre-edit object hashes, all generated-message hashes, and the
extracted target byte for byte. EXEPATCH retains compatibility patch and scan
data; the candidate file is byte-identical to the OpenNT reference. DOSTAB also
contains character conversion tables, not just compatibility data. Its two
non-DBCS uppercase tables match the pinned target and DOS 6 comparative
tables; see the [bounded table audit](evidence/m6-kernel-compatibility-table-audit.json).

The origin constant remains provisional pending IO.SYS reconstruction.
Binary identity alone does not establish source originality, standalone boot,
runtime behavior, or completion of IO.SYS and three-file integration. Source
style and provenance still need review as the experimental pieces are promoted
into the final DOS 6-like tree.
