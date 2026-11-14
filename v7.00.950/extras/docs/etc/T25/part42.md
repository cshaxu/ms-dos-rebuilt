# M6 T25 S1 P42: file 133

133. tmisc1.asm -- accepted_modified. Reviewed the complete effective-v6.22
diff. Restore inherited command-name lookup and redirection comments/format,
move the inherited segment change marker back onto its declaration, and align
added command-tail/path helper instruction formatting with surrounding code.
Replace CopyPathBuffer's literal 104h with the existing LenMsgOrPathBuf external;
RDATA defines it as the 260-byte resident message/path buffer length.

Retain separated name/handler tables, switch-bit indexing, parsed switch state,
dynamic command buffers and WORD lengths, quoted long redirection paths,
allocated far pipe state, EXEC notifications and stack protection. Their layouts
and interfaces are required by the accepted target. CopyCanonicalPath is shared
by EXEC and batch loading. BuildExternalTail supplies external EXEC's long-command
environment and bounded PSP tail; cmd_copy in PARSE2 remains the internal-command
argument copy, with different input and termination contracts. These are not
interchangeable duplicate implementations. No new module or second path added.

Verification: file133-build.txt; extras/build/t25-tmisc1-19369-21356.
Original COMMAND compiler/linker build passed. Generated messages and all three
linked executables remain byte-identical to the previous verified stage.
Freshly repacked COMMAND.COM matches its frozen target; inherited IO.SYS and
MSDOS.SYS also match their targets. All 293 current inputs match the build stage.

Prefix 133/293: modified 63, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: file 134.
Final full automatic build remains pending. P42 is delivered separately.
