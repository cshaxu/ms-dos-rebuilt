# M4 T5 S1 kernel baseline

`python tools/kernel_baseline.py` pins immediate kernel directories and original
link order: OpenNT 38 units, DOS 6 57, DOS 4 55. The JSON is the finite initial
link-unit inventory, not the final source-recovery universe or transitive closure.

DOS 6 links 19 additional units: crit, delete, rename, finfo, create, dinfo,
isearch, close, dircall, disk2, disk3, dir, mknode, rom, fat, buf, dosprint,
romfind, share. Their absence from the OpenNT link list does not prove that each
must be copied unchanged into DOS 5. Target analysis must establish disposition.
The lexical scan records 86 candidate host seams; conditional assembly and
semantics still need inspection before assigning replacement requirements.

`python tools/assemble_kernel_reference.py --all` assembled all 38 untouched
OpenNT linked units successfully using the native MASM 5.NT.02 executable.
Each call has a 20-second timeout, logs, source/tool/object hashes and the exact
argument list in m4-t5-reference-assembly.json. Stage:
build/kernel-reference-kzmxwku8. Only local copies of entry assembly files and
generated scratch were written. Reference include/message files were read-only.

This probe uses reference-provided MSDOS.CL* files. It does not yet establish
regeneration of messages, full dependency pinning, a linked NTDOS image, removal
of NT host dependencies, or any MSDOS.SYS target byte identity. No DOSBox or GUI
was launched. Exact COMMAND sources remain unchanged.

## Reference link continuation

The private-desktop runner creates a named desktop and starts DOSBox suspended,
assigns a kill-on-close Job Object, then resumes it with a 60-second budget.
It never switches desktops or sends desktop input. The Python wrapper has an
outer 75-second bound. Source: tools/isolated_tool_runner.c.

The initial BUILDMSG attempt failed before linking. Inspection of the original
make.inc showed that `.skl.cl1` uses NOSRVBLD. The rejected experiment is retained
in m4-t5-buildmsg-rejected.json; the recipe and inventory were corrected.

NOSRVBLD, LINK 5.10 /MAP, RELOC and STRIPZ completed in private desktop
DOS5Build_2128_737632171; DOSBox PID 10176 exited 0 without timeout. All four
generated MSDOS.CL1 through CL4 match the reference files byte-for-byte. This
validates the message contents consumed by the earlier assembly, but is not yet
a clean regeneration-before-assembly build. The reference makefile's link16
was substituted with the already available DOS 6 LINK 5.10; this remains an
explicit toolchain assumption, not a claim to reproduce Microsoft's NT build.

Output NTDOS.SYS: 27858 bytes, SHA-256
957662320654ad5251c3a8b228a5dadec28aa65dddbcba38c3658a6e7f93bc84.
The /MAP run and prior successful non-/MAP run produced the same output hash.
Warnings: no stack segment and no starting address. No unresolved externals
were reported. Those warnings are consistent with a raw kernel image; they do
not establish standalone boot behavior. The full symbol map is 43001 bytes.
Evidence: m4-t5-reference-link.json; owned stage build/kernel-link-nhjc170m.

Direct comparison in m4-t5-reference-comparison.json proves this output is
not the target: target is 37394 bytes, 9536 larger; first difference at byte 1.
STRIPZ removed 8784 bytes, and the remaining BIN suffix equals SYS exactly.
Reference map offsets must account for that prefix; target offsets remain
unmapped. No claim of recovered DOS filesystem paths or target identity is made.

Next work: close transitive include/resource inventory and construct a clean
local-source baseline, then use target disassembly to prioritize standalone
paths. T5 S1 remains active.

## Local source baseline

kernel_dependencies.py follows literal INCLUDE references recursively across
all conditional branches using the tested reference search order. It found 107
files and no unresolved literal includes or existing shared-header conflicts.
This is a conservative source closure, not an assembler active-branch trace.
The import tool preflights all hashes and refuses differing existing files.
It imported/reused the reviewed files in dos/, inc/ and inc/ntvdm, preserving
all 110 preexisting files in cmd/command, inc and messages byte-for-byte.
Source notices remain intact; nothing was published. Kernel message inputs
live in dos/messages to avoid overwriting COMMAND's modified message catalog.

All 38 local-source modules assembled successfully in
build/kernel-reference-hlhceo1c. Every object hash equals its external-reference
counterpart. A private-desktop link using local link/skeleton/message inputs
then completed in build/kernel-link-fz0vqobh, producing the same NTDOS.SYS hash
and symbol map as the external-reference run. See m4-t5-local-assembly.json,
m4-t5-local-link.json and m4-t5-kernel-import.json.

Messages are still checked-in reference-generated includes for assembly;
although regeneration was proved identical, a single clean pipeline that
generates before assembly remains to be implemented. No recovery edits have
yet been applied to the imported kernel source. T5 S1 remains active.

## Clean generation-before-assembly build

tools/build_kernel.py snapshots all planned local source inputs into a fresh
stage, explicitly excluding imported MSDOS.CL1 through CL4. It generates these
files with NOSRVBLD before invoking MASM, searches the generated directory first,
then links and applies RELOC/STRIPZ. Both DOS tool phases use the private-desktop
launcher; no UI input or Computer Use. Source hashes are checked again at end.

Verified run: build/kernel-clean-fh9v8adc. Both tool phases exited normally;
all 38 objects assembled. Output and map hashes equal the earlier baseline:
NTDOS.SYS 957662320654ad5251c3a8b228a5dadec28aa65dddbcba38c3658a6e7f93bc84,
map 9f2f1b9935dc621779c3803bec312ba1556e4274d2a9cd681091c56a943bd13c.
The generated CL hashes also equal all four reference files. Full source,
tool, message and object snapshots: m4-t5-clean-kernel-build.json.
This closes the previously recorded generation-order gap, not target recovery.
