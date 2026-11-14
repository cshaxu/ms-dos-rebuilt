# M6 T25 S1 P48: focused LFN contract correction

Owner explicitly requested XP NTDOS as authoritative for LFN interfaces and
semantics and asked whether existing 950 should be corrected. This authorizes
the focused follow-up to file 134 without restarting sequential review.

Correct TMISC2 PathFindNext's return comment: find-next carry is preserved,
but ClosePathFind on failure may change AX. Previously the header incorrectly
promised both carry and AX from the search. Keep the target instruction stream;
do not add an AX save/restore that would change the required binary.

lfn-xp-contracts.md records specific checked Microsoft XP guest/DEM interfaces
and remaining semantic work, not an assertion of total LFN compliance.

Verification: lfn-contract-build.txt; extras/build/t25-lfn-contract-23137-5945.
Original COMMAND build passes; generated messages and linked executables are
unchanged. Fresh COMMAND.COM matches frozen target; inherited IO.SYS/MSDOS.SYS
also match. All 293 source inputs match the stage.

No new file acceptance is counted. Prefix remains 139/293: modified 68, exact
21, necessary unchanged 14, no same-name reference unchanged 36; tool one.
Next: file 140 tucode.asm. Full final build and completion audit pending.
