# T25 S1: files 66 through 68

These registry modules have no same-name effective v6.22 reference. Review
preserves the 950 implementations and existing module/segment structure;
no independent source baseline or parallel implementation was introduced.

66. bios/rapiopen.asm: reviewed all API entries, local query/set cores,
    handle/file reference ownership, mount restrictions, save/export cleanup
    and VM dispatch. Replace five fixed root-table addresses with the existing
    DGROUP:RegRootTable symbol and record offsets: 0356h = base + 3*28h,
    032Eh = base + 2*28h, 03CEh = base + 6*28h and two 02DEh base additions.
    Both the accepted configuration map (base 02DEh, end 03F6h) and the seven
    28h root records in regroot.asm establish these relationships. Other
    operations already use that symbolic form. Correct the header's blanket
    forwarding claim: query/set cores perform local operations; entries with
    the RegVMEntry check dispatch to Windows when installed. Retain that real
    runtime distinction, special flush control, exact error paths and cleanup.
    Similar open/create and query/enumeration operations retain their different
    access checks, arguments and result contracts; no destructive merge.
67. bios/regfind.asm: reviewed handle lookup/creation/validation/destruction,
    root invalidation, file references/lists and RGHV operations. Remove the
    redundant rf_find near alias; the existing PUSH CS now calls NEAR PTR
    RegFindKey directly, matching the same-file RegKeyCreate call form.
    Replace sixteen address-derived validation labels with operation names.
    Preserve root-ID versus root-address versus dynamic-handle resolution,
    lazy-root behavior, deleted-key status, distinct owner/file invalidation
    fields and the shared InvalidateRoot macro. File and RGHV unlink routines
    differ in signature and list-head ownership; do not merge their bodies.
68. bios/reginit.asm: reviewed block initialization, mount lookup/link/unlink,
    export preparation and recursive value/subkey copying. Remove four unused
    external declarations: RegCheckPolicy, RegVMEntry, RegValidateKeyBlock
    and RegValidateDataBlock. Keep RegValidateHeader, which is actually called,
    and existing segment declarations. Block initializers use distinct
    CREG/RGKN/RGDB formats; export preparation reuses them. Mount lookup uses
    shared path/hash/compare services. Preserve buffer ownership, cleanup,
    original pointer arithmetic and existing error handling; no new checks
    that would change target instructions.

Evidence: file66-build.txt through file68-build.txt. Each changed file was
freshly assembled using production config.mak; its existing production OMF
layout was applied, then CONFIG.EXE was freshly linked using the unchanged
cfglink.bat. Every CONFIG.EXE is byte-identical to the preceding verified
stage. IO.SYS was freshly packed and compared to its own frozen target;
the two inherited unaffected images also compare exact. All 293 current
source files match each stage. Raw OBJ equality is not claimed for symbol
references that correctly add linker fixups. No production build script,
layout manifest or special-case patch was added or changed.

Counts through 68: modified 23, exact 11, necessary unchanged 5,
no-reference unchanged 29. One tool change remains separately counted.
Latest verified stage: extras/build/t25-reginit-29702-30830.
Next: 69 bios/regopen.asm. Whole-audit completion and final full build remain
pending; this part does not close T25.
