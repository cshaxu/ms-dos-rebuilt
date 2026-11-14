# T25 S1: files 85 through 86

85. bios/si2front.asm: no same-name effective reference; compared its inherited
    code with frozen effective-v6.22 bios/sysinit2.asm. Preserve the existing
    split, byte alignment, configuration menu and environment organization.
    Restore 69 conditional-jump lines verbatim where removing SHORT and
    formatting differences yields the reference instruction and comment.
    No unconditional jump encoding was changed. Replace three expressions
    [drivenumber+1] with already declared [boot_mode]; ststate.asm places that
    byte directly after drivenumber. Remove the obsolete adjacency comments.
    Retain required 950 startup keys/modes, previous menu selection, signed
    timeout handling, environment lookup/deletion, indexed messages, driver
    compatibility handling and high-memory configuration options. Keep the
    shared display_menu and copy_envvar paths rather than duplicate bodies.
    Explicit CMP byte forms preserve the assembler direction encoding.

Evidence: file85-build.txt. Original NMAKE rebuilt BIOS and loader. MSLOAD.EXE
and MSBIO.BIN compare byte-identical to the preceding verified stage. Freshly
packed IO.SYS equals the frozen 950 target. MSDOS.SYS and COMMAND.COM are
inherited unaffected images and also compare exact. All 293 current source
inputs match the stage. No new build exception or second implementation.

86. bios/stkinit.asm: no same-name reference. Reviewed the complete file and
    the interrupt-stack implementation in effective-v6.22 sysinit1.asm.
    Restore 20 uses of existing allocbyte, savedsp, savedss, newsp, allocated,
    free, clobbered and entrysize symbols instead of numeric displacements
    and constants. Preserve 950 EAX saving and its corresponding eight-byte
    frame offset, explicit CS references, inlined free-entry search, VM focus
    setup and NUL-terminated fatal message handling. Shared IRQ entries use
    the existing IRP; no duplicate handler body introduced. Preserve inherited
    empty conditionals and the current module/segment organization.
    Evidence: file86-build.txt. Original NMAKE rebuilt BIOS and loader;
    MSLOAD.EXE and MSBIO.BIN remain byte-identical. Freshly packed IO.SYS
    matches the frozen target; both unaffected inherited images also match.
    All 293 current inputs match extras/build/t25-stkinit-540-2287.

Counts through 86: modified 30, exact 17, necessary unchanged 5,
no-reference unchanged 34; tooling modified 1 separately.
Stage: extras/build/t25-si2front-125-13495.
Next: 87 bios/ststate.asm. Full automatic build and completion audit pending.
