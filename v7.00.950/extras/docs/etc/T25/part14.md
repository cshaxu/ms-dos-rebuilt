# T25 sequential audit: files 92-93

92. bios/syspre.asm -- accepted_modified.

Reference: the frozen v6.22/bios/syspre.asm overlay, not its inherited supplier.
Reviewed the complete 748-line source and differences. Restored eight numeric
DOS-service/error expressions to existing OPEN/LSEEK/CHMOD/CLOSE and
SYSPRE_BADFILE_ERROR symbols. Restored matching declarations and instruction
formatting, including DrvIniName and MagicDDName. No runtime logic changed.

Retain necessary 950 DRVSPACE/DBLSPACE/STACKER handling, revision negotiation,
compatibility patching, backdoor restoration, relocation and sector validation.
Reserved-image placement and allocator fallback are distinct storage cases with
a common tail, not duplicate implementations. Keep explicit encoding macros,
near-jump bridges, segment overrides and existing file organization.

Verification: file92-build.txt. Stage extras/build/t25-syspre-3449-10861.
Original NMAKE rebuilt BIOS and loader. MSBIO.BIN and MSLOAD.EXE compare byte
identical to the previous verified stage. Freshly packed IO.SYS compares exact
to its own frozen 950 target. Unaffected inherited MSDOS.SYS and COMMAND.COM
also compare exact. All 293 current source inputs match the stage.

Prefix 92/293: modified 35; exact 17; necessary unchanged 6; no same-name
reference unchanged 34. Tool modification remains separately counted as one.
93. cmd/command/buildmsg.c -- accepted_necessary, unchanged.

Complete reference diff contains only two hunks: removal of assembler semicolon
prefixes from the C copyright comment, and the generated message-class header.
Keep the compilable C comment. The 950 generator emits the two-field class
header and class 3 rather than the reference version field and class 255.
Confirmed the actual DOS7_TRANSIENT_MSG structure in inc/msgserv.asm:121-129,
selected by command/tdata.asm and tprintf.asm; the verified stage command.clf
contains $M_CLASS_ID <003H,Class_F_MessageCount>. Restoring the reference form
would conflict with the target message layout. Remaining code is inherited
unchanged, with no alternate generator implementation introduced here.
No source edit, hence no redundant rebuild.

Prefix 93/293: modified 35; exact 17; necessary unchanged 7; no same-name
reference unchanged 34. Next is 94 cmd/command/comequ.asm.
Final full automatic build remains pending.
