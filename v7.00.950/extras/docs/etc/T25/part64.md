# M6 T25 S1 P64: files 162-163

162 dos/diskset.asm: accepted_modified. No same-name effective v6.22 file;
its HARDERRRW and SETUP procedures match the effective dos/disk2.asm bodies.
Restored that SETUP contract at its actual definition. Corrected the copied
module identity and contents list; removed 13 unused data declarations and
two unused external procedures. Kept the inherited RMFHFE comment and both
procedure instruction streams. Normalized wrapper formatting only.

Compiled affected DISKSET, linked the kernel and compared it byte-for-byte
to the preceding verified stage. Repacked IO.SYS from that new kernel and
compared against the frozen 950 target. Unaffected output MSDOS.SYS and
COMMAND.COM inherited from the verified stage also compare exactly.
All 293 source inputs match the build stage. Evidence: file162-build.txt,
file162-make.txt; stage extras/build/t25-diskset-9-15816.

163 dos/divmes.inc: accepted_exact. FC /B against effective v6.22 supplier
v6.2/dos/divmes.inc reports no differences; no rebuild needed.

Accepted prefix 163/293: modified 84, exact 23, necessary unchanged 20,
no same-name reference unchanged 36. Tool change remains 1, separately.
Next 164 dos/dosmes.inc. Full clean build and final scope audit pending.
