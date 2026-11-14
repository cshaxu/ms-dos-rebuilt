# M6 T25 S1 P72: file 178

178 dos/idle.asm: accepted_modified. Compared with Idle in effective v6.22
dos/misc2.asm. Inherited retry loop and contract retained; 950 uses JNZ to
its final return rather than reference RETNZ. No instruction changed.

Corrected copied MISC2 module title, description and contents list. Removed
11 unused data declarations (THISCDS, FastTable, FastFlg, User_SP_2F, User_SP,
User_SS, SysInitTable, EXTERR, fshare, Special_version, NlsBuffer), five unused
includes (sysvar, sf, curdir, fastxxxx, bugtyp) and unused allow_getdseg.
Retained original procedure comments and history.

Initial incremental harness stopped after LINK without captured diagnostic,
even for a comment-only change. Reverting declarations did not resolve it.
A DOS C probe duplicates stdout to stderr and executes original NMAKE via
system(), capturing child diagnostics. It completed MASM, LINK, RELOC and
STRIPZ with the final cleanup. Only normal no-stack/no-entry linker warnings.
No production build script was changed. Original direct-harness failure's
root cause remains unproven; final clean production build must still pass.
Probe source preserved as file178-linkdiag.c for reproducibility.

Fresh kernel equals prior verified kernel. IO.SYS freshly packed target-exact;
unaffected MSDOS.SYS/COMMAND.COM inherited and compared exact. All 293 inputs
match stage extras/build/t25-idle-4414-31960. Evidence file178-build.txt and
file178-make.txt. This proves source byte preservation, not final clean-build
acceptance.

Prefix 178/293: modified 92, exact 26, necessary unchanged 24, no same-name
reference unchanged 36; separate tool change 1. Next 179 dos/ioctl.asm.
