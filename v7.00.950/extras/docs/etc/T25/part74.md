# M6 T25 S1 P74, files 182–183

182 dos/lfn.asm, accepted_modified. No same-name file in effective v6.22.
Reviewed all five procedures. Used inherited `DIRFREE`, `dir_attr`,
`SIZE dir_entry`, `buf_flags`, `buf_dirty` and `buf_isDIR` for equivalent
constants and offsets. Preserved the scan, save, delete and flush logic.
Traced function 71h and 72h through mstable.asm and From_GetSet in mscode.asm.
The saved carry is set and the saved AX is 7100h or 7200h respectively.
XP NTDOS hands LFN service dispatch to DEM. This comparison concerns the
native fallback entry and does not constitute validation of all LFN calls.
Fresh assembly, kernel link and IO.SYS packing passed the byte checks at
extras/build/t25-lfn-5355-14541.

183 dos/lock.asm, accepted_modified. The full effective v6.22 diff removes
LOCK_CHECK and LOCK_VIOLATION, both supplied by dos/lockio.asm in 950.
Removed the two stale contents entries and three unused data declarations
(THISDPB, ALLOWED, RetryCount). Kept LockOper and its conditional assembly.
Fresh assembly, kernel link and IO.SYS packing passed the byte checks at
extras/build/t25-lock-5521-5654.

Each stage checked all 293 source inputs and compared all three outputs with
the frozen targets. MSDOS.SYS and COMMAND.COM came from the prior stage.
The P72 diagnostic probe invoked original NMAKE.

Prefix 183/293. Modified 95, exact 27, necessary unchanged 25, no same-name
reference unchanged 36. Next 184 dos/lockio.asm.
