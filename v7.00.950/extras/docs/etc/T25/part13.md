# T25 S1: files 90 through 91

90. bios/sysinit1.asm: reviewed the initialization code, declarations and
    helpers against effective-v6.22 sysinit1.asm and its inherited structures.
    Existing split modules retain the stack handler, state and tail routines;
    do not duplicate those implementations in this file. Preserve required
    byte alignment, BDS compaction, resource relocation, boot-image reservation,
    DOS initialization workspace, localized replies, temporary buffers/CDSs,
    PSP relocation, startup choices and configuration phases.
    HMA/low-memory paths share MovBIOS/MovDOS and reinitialization. Preserve
    their distinct allocation contracts, configuration-copy calls and callback
    lifecycle. The changed MovDOS output contract and AllocHMA comments match
    the current code. Retain shared root-directory lookup/sector reading used
    for DBLSPACE/DRVSPACE reservation rather than introduce a second reader.
    RPL, VDISK, DRIVPARM, ROMDOS/TAIWAN/POWER and empty inherited conditional
    forms remain in the existing organization. Explicit SUB encoding remains
    necessary to retain its word-immediate target form.

    Replace saved boot-sector numeric offsets with EXT_BOOT_BPB/EBPB fields
    and EXT_PHYDRV from existing bootform.inc, included after bpb.inc as its
    contract requires. The included file is byte-identical to the frozen
    effective-reference supplier. Replace numeric EBDA arena size/signature
    references with arena_size/arena_signature/arena_signature_end, and new
    DOS calls with existing GET_IN_VARS/set_dma symbols. Restore the reference
    have_install_cmd/has_installed declarations and comments. No new structure,
    duplicate implementation, changed allocation or build exception.

Evidence: file90-build.txt. Original NMAKE rebuilt BIOS and loader, both
MSLOAD.EXE and MSBIO.BIN byte-identical to the preceding verified stage.
Freshly packed IO.SYS equals the frozen 950 target. The two inherited
unaffected images also compare exact. All 293 current inputs match stage
extras/build/t25-sysinit1-2091-28740.

91. bios/sysinit2.asm: reviewed startup data, shell selection/size/EXEC,
    drive mapping, UMB/provider compatibility, previous-DOS load/rename/start,
    automatic driver records, environment, menu and options reader/dispatcher.
    Retain necessary 950 behavior and existing module structure. The former
    reference menu/CONFIG functionality resides in the audited SI2FRONT;
    do not add a duplicate here. Shared boot_check_device, boot_find_old_file,
    boot_insert_path, copy_envvar, display_menu and the single option parser
    already avoid parallel implementations. Automatic drivers reuse the
    existing configuration executor. Shell fallback records represent distinct
    startup choices; option-copy handlers intentionally share fall-throughs.
    Preserve exact branch forms, shared string tails and arithmetic semantics.
    Restore 60 DOS call-number expressions using the existing syscall.inc
    definitions (verified byte-identical to the effective-reference supplier).
    Replace 'U'/'D' driver command literals with CONFIG_DEVICEHIGH/CONFIG_DEVICE.
    No new local constants, second implementation or build exception.
    Evidence: file91-build.txt. BIOS and loader freshly rebuilt unchanged;
    fresh IO.SYS exact; two inherited images exact; 293 current inputs match
    extras/build/t25-sysinit2-2620-510.

Counts through 91: modified 34, exact 17, necessary unchanged 6,
no-reference unchanged 34. Tooling modified 1 separately.
Next: 92 bios/syspre.asm. Final full build and completion audit pending.
