# M6 T25 S1 P61: file 159

159. dos/disk2.asm -- accepted_modified. Full effective-reference diff reviewed,
including the lock checks moved from effective-reference disk.asm.
Remove unused ThisDrv, SecPos, EXTERRPT and CALLVIDRW declarations. Correct the
module contents list for the moved-in lock checks and moved-out HARDERRRW/SETUP.
Move the unchanged DSKREAD contract from above CHECK_WRITE_LOCK to immediately
before DskRead. Remove the orphan SETUP contract and normalize the added cache
address external declaration. Keep inherited lock-check text and conditionals.

Retain the CS-relative FIRST_BUFF_ADDR, target read-path branch arrangement,
BYTCNT1 comparison against CX, and ADC CX,CX after REP MOVSW. In the latter
case CX is exhausted by REP and the carry transfers the odd-byte remainder;
the reference ADC CX,0 does not justify changing the target's instruction.
No executable instruction, operand or data changed by this part.

Original NMAKE/MASM/LINK freshly rebuilds the kernel byte-identical. Fresh IO.SYS
repack equals the frozen target; unaffected inherited MSDOS.SYS and COMMAND.COM
are exact. All 293 inputs match the stage. Evidence: file159-build.txt and
file159-make.txt; stage named in build evidence.

Prefix 159/293: modified 81, exact 22, necessary unchanged 20, no same-name
reference unchanged 36. Separate modified tool one. Next: 160 dos/disk3.asm.
Final full build and completion audit remain pending.
