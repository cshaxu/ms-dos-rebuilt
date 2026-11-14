# T25 sequential audit: files 111-112

111. init.asm -- accepted_modified. Read all 2526 lines of the effective
reference diff. Restore original PSP initialization and failed batch cleanup
paragraphs, complete inherited Carousel explanation/instruction comments,
/P and /D descriptions and /Y and /F comments. Replace seven DOS service
numbers with existing FILE_TIMES, GET_IN_VARS, OPEN, CLOSE and ALLOCOPER symbols.
Move GetResidentDataSize's misplaced header/public declaration beside its
actual procedure; no instruction ordering or routine boundaries changed.

Retain necessary indexed message resources, far single-command pointer,
extended CMDLINE extraction, configurable command/input buffers, Windows
startup flags, AUTOEXEC timestamp recording, resident checksum/reuse and
resident data relocation. Initialization and normal parsing share Init_Parse;
size switches share CheckSizeSwitch and environment consumers share FindComspec.
PrepareOriginalPSP and FinishResidentPSP operate before and after resident-data
relocation: similar stores address distinct live PSPs and cannot simply be
deleted as a second implementation. HMA reuse, allocation and low fallback
share relocation/patching tails. Existing ROMDOS branches remain intact.

Verification: file111-build.txt; extras/build/t25-init-9317-25395.
Original COMMAND build passes; messages and linked executables unchanged.
Fresh COMMAND.COM equals own 950 target; inherited IO.SYS/MSDOS.SYS also equal.
All 293 current sources match the verified stage.

112. iparse.asm -- accepted_exact. Direct FC/B against effective reference
passes; no edit or redundant build.

Prefix 112/293: modified 45, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 113 loadhi.asm.
Full automatic final build remains pending.
