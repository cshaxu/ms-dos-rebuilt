# T25 sequential audit: file 113

113. cmd/command/loadhi.asm -- accepted_modified.
Complete effective-reference diff is limited to external declarations,
the execution entry and scanning the dynamic command buffer. Restore CRLF
consistency and one-per-line external declarations. Correct LoadHigh's entry
comment to ComBufPtr; the old PSP:iCmdLine statement no longer describes input.

Keep original ParseVar/InitVar, filename validation, UMB handling and error
flow. SetupCmdLine still writes the child tail to iCmdLine, so its constant
and comments remain correct. TMISC1's Lh_Entry jumps to the shared Lh_Execute
body, bypassing EXECUTE's IOSET/ExecState setup; it is an entry stub rather
than a second execution implementation. Changing the jump destination would
alter target bytes, so retain the proven 950 entry.

Verification: file113-build.txt; extras/build/t25-loadhi-9709-4484.
Original COMMAND build/messages/linked executables unchanged; fresh COMMAND.COM
equals the target, inherited IO.SYS/MSDOS.SYS also equal. All 293 inputs match.

Prefix 113/293: modified 46, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 114 makefile.
Full automatic final build remains pending.
