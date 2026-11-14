# M6 T25 S1 P70: files 175-176

175 dos/finfo.asm: accepted_necessary. Complete reference diff is one call:
FlushBuf becomes DeferredFlush. Shared msctrlc.asm implementation tests
DeferredFlushFlags and either returns or transfers to FlushBuf. Preserve
950 deferred-write behavior; no duplicate implementation. No rebuild.

176 dos/getset.asm: accepted_modified. Complete effective v6.22 diff reviewed.
Retain internal table function 70h, locale and country table transfer paths,
DOSDATA NLS response bytes, return/error sharing and exact arithmetic encoding,
plus paired drive-state changes around the existing DISK_INFO invocation.
Normalize indentation of InternalTable, gec_store and free-space wrapper.
Replace both network-bit literals 8000h with existing curdir_isnet, whose
definition in curdir.inc is 1000000000000000B. No data or control-flow changes.

GETSET compiled and kernel freshly linked unchanged against preceding stage.
Fresh IO.SYS target-exact; unaffected MSDOS.SYS and COMMAND.COM inherited and
also compared target-exact. All 293 inputs match stage. Evidence:
file176-build.txt and file176-make.txt.

Prefix 176/293: modified 90, exact 26, necessary unchanged 24, no same-name
reference unchanged 36; separate tool change 1. Next 177 dos/handle.asm.
Final full clean build and completion audit pending.
