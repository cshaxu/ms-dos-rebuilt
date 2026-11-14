# M6 T25 S1 P88, files 218–224

218 dos/share.asm, accepted_modified. The full effective v6.22 diff adds
a character-device critical-error path before the existing disk path.
Documented the device test and error bit and aligned the jump spelling.
Kept both target paths. Stage t25-share-11083-25646.

219 dos/shrprint.asm, accepted_exact. FC /B with the effective supplier
in v6.2/dos reported no differences.

220 dos/srvcall.asm, accepted_necessary. The full diff extends the
no-DPL range from 7–9 to 6–9 and updates its comment. Preserved the
target dispatch threshold.

221 dos/time.asm, accepted_necessary. The full diff selects target
opcode 38 D0 for CMP AL,DL in DODATE. Preserved the encoding.

222 dos/util.asm, accepted_modified. Reviewed the full reference diff.
Removed unreferenced pjfn10, ReturnCarry and GetSF labels left by the
950 handle-lookup changes. Restored comments and indentation around
the existing bounds and unused-handle checks. Kept the target error
branches and instruction sequence. Stage t25-util-11223-29076.

223 inc/arena.inc and 224 inc/bdsize.inc, accepted_exact. FC /B against
the effective suppliers in v6.2/inc reported no differences.

Original NMAKE through the P72 probe rebuilt each modified module and
relinked the kernel separately. Each freshly packed IO.SYS and inherited
MSDOS.SYS and COMMAND.COM matched its frozen target. Each stage verified
all 293 inputs. See file218-build.txt and file222-build.txt and their make
logs.

Prefix 224/293. Modified 114, exact 43, necessary unchanged 30, no same-name
reference unchanged 37. Next 225 inc/bootform.inc.
