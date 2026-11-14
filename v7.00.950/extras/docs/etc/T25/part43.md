# M6 T25 S1 P43: file 134

134. tmisc2.asm -- accepted_modified. Reviewed the complete effective-v6.22
diff, required helpers and their callers in DIR/COPY/FOR/PATH/batch commands.
Remove unused PathFindBuffer external; split added external/public lists to
match the inherited declaration style. Normalize PGETARG and added filesystem
helper instructions to surrounding tabbed layout; preserve unchanged original
blocks. Replace eight DOS service literals with existing syscall.inc symbols:
Get_Default_Drive, Set_DMA, Find_First, Find_Next, CHDir, Current_Dir, ExtOpen,
CHMod. Correct GETPATH's obsolete switch-scan comment without deleting its
target-required instruction sequence.

Retain parsed argument access, SI/DI preservation, CS data overrides, extended
redirection opens and DI-based error discrimination. Shared path-interface
selection handles local and network roots; short/long search result offsets,
handle lifetime and fallback names remain required. Entry/search appenders
already share their copy loop. Directory pattern normalization and shared
consumer helpers remain in the existing module; no duplicate path or new file
is introduced. Replacing these with the reference's fixed short-name-only
processing would lose required target behavior and change bytes.

Clarification to P42: PARSE2's cmd_copy reparses the remainder when a command
name shares its first argument; it updates parsed argument state and calls
ParseCommandLine. P42's description as an internal argument copy was imprecise.
It does not duplicate BuildExternalTail's PSP/environment construction.

Verification: file134-build.txt; extras/build/t25-tmisc2-19950-1260.
Original COMMAND build passed. Generated messages and linked executables are
unchanged. Fresh COMMAND.COM matches its frozen target; inherited IO.SYS and
MSDOS.SYS also match. All 293 current source inputs match the verified stage.

Prefix 134/293: modified 64, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Tool modification counted separately: one.
Next: 135 tparse.asm. Final full automatic build remains pending.
