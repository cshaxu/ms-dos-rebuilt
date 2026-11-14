# T25 S1: files 87 through 89

87. bios/ststate.asm: no same-name effective reference. Reviewed all data
    declarations against the corresponding sysinit1.asm data. Restore the
    original h_buffers declaration and its initialization comment. Most
    inherited data declarations already match. Retain necessary 950 byte
    layout, boot-image storage, -1 buffer default, runhigh/UMB defaults,
    byte install_flag, new pass descriptions, boot_mode and aliases. Aliases
    do not allocate duplicate state. Keep the existing split and conditional
    forms. Evidence: file87-build.txt; BIOS/loader rebuilt unchanged, fresh
    IO.SYS exact, two inherited images exact, 293 current inputs verified.
    Stage: extras/build/t25-ststate-909-4441.

88. bios/sysconf.asm: reviewed all differences from the frozen effective
    reference. Restore five inherited SWITCHES control/string declarations,
    three original arithmetic/comparison lines and the result_val separator.
    Replace numeric parser fields with $p_item_tag/$p_picked_val; use existing
    device-header fields, devtyp, CDS fields/flag/size, GET_IN_VARS, open,
    close and LF symbols. The 25 replacements preserve operand values.
    Include the existing curdir.inc rather than locally duplicate its
    declarations; the first compile exposed this missing include, corrected
    before acceptance. Retain the failed build at
    extras/build/t25-sysconf-1369-12638 (bios/audit.log and BUILD.OK).
    Retain 950 configuration passes, AUTO/NOAUTO/SINGLE, access dates, high
    memory options, startup query/workspace, runtime message indices, driver
    hooks, compatibility handling and device/vector/CDS recording. High and
    normal options share parsers; SWITCHES parsing and applying are separate
    phases, not duplicate parsers. FindDeviceName generalizes the former
    PROTMAN-only test. alloc_marked_block and alloc_system_data manage distinct
    arena directions and share marker writing. Device-record item emission,
    basename copying and interrupt comparisons already share helper bodies.
    Explicit 32-bit prefix forms are retained to preserve target encoding.
    Evidence: file88-build.txt. BIOS/loader rebuilt unchanged; fresh IO.SYS
    exact; two inherited images exact; 293 current inputs verified at
    extras/build/t25-sysconf-1552-24725.
89. bios/sysimes.asm: necessary difference, no edit. Compared the complete
    file with the reference. The old direct-message export/include is replaced
    by the target's indexed resource header and source text table. Header
    counts/offsets/size are symbolic differences of labels, not fixed copied
    output bytes. The included table exports the message symbols consumed by
    the audited SYSINIT callers. Preserve this format and existing module
    organization; reverting to the reference resource would break callers
    and target bytes. No redundant rebuild for an unchanged file.

Counts through 89: modified 32, exact 17, necessary unchanged 6,
no-reference unchanged 34. Tooling modified 1 separately.
Next: 90 bios/sysinit1.asm. Final full build and completion audit pending.
