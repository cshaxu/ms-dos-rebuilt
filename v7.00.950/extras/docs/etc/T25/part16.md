# T25 sequential audit: files 98-100

98. cmd/command/command2.asm -- accepted_modified.
Reviewed the complete effective-reference diff and relevant data/service
contracts. Restored eleven numeric DOS service expressions to existing syscall
symbols and the original ifndef ROMDOS formatting. A separate 4200h resource
capacity check is not a DOS call: retain that numeric constant. The initial
symbolic spelling was byte-identical but semantically misleading; corrected
it before acceptance and rebuilt the final source.

Retain primary indexed-message loading and country state, indirect resident
messages, checksum header, interrupt restoration, variable command buffers,
allocation reserve, stack guard, resource checksum and initialization release.
The COMSPEC/original/boot/prompt sequence shares TryLoadCom. Code and message
checksums share ChkMessageBlock. Resource format variants share payload loading.
No duplicate fallback implementation needs removal. Preserve ROMDOS branch,
explicit ABI offsets, resource signatures and required instruction ordering.

Verification: file98-build.txt. Final stage:
extras/build/t25-command2-final-5297-32379. Original command build passed;
generated messages and linked command/message executables compare unchanged.
Fresh COMMAND.COM matches its own 950 target. IO.SYS/MSDOS.SYS inherited exact.
All 293 current source inputs match stage. Initial iteration is retained at
extras/build/t25-command2-5147-29472; it is not the final accepted source.

99. cmd/command/comseg.asm -- accepted_exact. Direct FC/B confirms exact
effective-reference content, so no edit or redundant build.

100. cmd/command/comsw.asm -- accepted_necessary, unchanged. The sole semantic
change disables IBM_ROM_FIND for 950; the replacement comment describes that
actual build selection. Reference enabled it for non-ROM builds. TCODE's gated
MSHALO inclusion and TMISC/TSPC references demonstrate this controls emitted
code/data, not an unused compatibility switch. Keep the 950 value; restoring
reference selection would change the target. Consumer conditional branches
remain intact. No edit or redundant build.

Prefix 100/293: modified 38, exact 18, necessary unchanged 10, no same-name
reference unchanged 34. Tooling modified separately: one. Next: 101 copy.asm.
