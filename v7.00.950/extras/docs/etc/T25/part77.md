# M6 T25 S1 P77, file 187

187 dos/makefile, accepted_modified. The effective v6.22 delta consists of
the 950 object prerequisite list and the extra rules for split modules.
Retained that list and original LINK, RELOC and STRIPZ recipes. Removed
five stale direct include prerequisites from IDLE (bugtyp, curdir, fastxxxx,
sf and sysvar) and two from DIRCMP (dpb and fastopen). The current sources
both include version.inc, dosseg.inc and dossym.inc. The rules retain their
transitive includes declared by dossym.inc.

In extras/build/t25-make187-6690-19728, removed IDLE and DIRCMP objects and
kernel outputs before running original NMAKE via the P72 diagnostic probe.
Both modules reassembled. The fresh kernel matched the preceding verified
stage. Fresh IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched the frozen
950 targets with FC /B. All 293 source inputs matched the verification stage.
See file187-build.txt and file187-make.txt.

Prefix 187/293. Modified 98, exact 27, necessary unchanged 26, no same-name
reference unchanged 36. Next 188 dos/misc.asm.
