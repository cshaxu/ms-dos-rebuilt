# T25 S1: files 45 through 50

45. bios/msdioctl.asm: restore the effective v6.22 COMMENT/ENDCOMMENT form
    around the already disabled INT 13h retry block, retaining its contents.
    Restore sector-count and multi-track flag comments. Preserve 950 CS data
    placement, shared Bios_Flags, dynamic sector-buffer access, caller DS/DX
    preservation, format attributes and the actual added 48h/49h IOCTL entries.
    Those entries share the capability check and MapError; no second protocol
    implementation was introduced. Original ML accepts the restored comment
    form. Full BIOS/loader rebuild and fresh IO.SYS packing are byte-identical.
46. bios/msdisk.asm: remove the redundant early numerr=9 assignment; keep the
    single symbolic errout-errin definition. Restore the complete error-code
    mapping table with per-entry comments from effective v6.22 msbio1.asm,
    where these data originally reside. Preserve their 950 location and byte
    order. Restore romread instead of the literal 2 and describe the existing
    explicit CMP encoding. Retain dynamic buffer access, changed boot-sector
    return register, DMF flag handling, extended INT 13h packet path, CHS
    bounds/retry changes and shared failure paths. These are emitted target
    differences, not arbitrary style variations. Full BIOS/loader rebuild and
    fresh IO.SYS packing are unchanged; all three own target checks pass.
47. bios/msdskpr.inc: exact effective v6.22 source.
48. bios/msend.asm: necessary difference only. BCode_end now belongs to the
    biosmsg resource boundary (previously audited file 2); restoring its old
    declaration here would duplicate the public symbol and misplace the code
    end. Remaining data/initialization end declarations match the reference.
    The narrowed header comment accurately describes the remaining segments.
49. bios/msequ.inc: exact effective v6.22 source.
50. bios/msgroup.inc: exact effective v6.22 source.

Counts through 50: modified 10, exact 8, necessary unchanged 4, no-reference
unchanged 28. Tooling remains separately counted: one ioimage.c change.
Evidence: file45-build.txt and file46-build.txt. Each verifies all 293 source
inputs; BIOS/loader are freshly compiled and linked, IO.SYS freshly packed.
Unaffected kernel/configuration/command build outputs are inherited from the
validated stages, not claimed as newly compiled here. Final full build remains
required at completion of the entire audit. Next: 51 bios/msinit.asm.
Latest verified stage: extras/build/t25-msdisk-25709-25497.
