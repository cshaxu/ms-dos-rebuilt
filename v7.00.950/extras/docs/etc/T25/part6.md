# T25 S1: files 51 through 54

51. bios/msinit.asm: reviewed the complete diff against effective v6.22.
    Restore the original floppy probing, invalid-CMOS fallback, change-line
    detection and media form-factor paragraphs, retaining the 950 LES chain,
    ES-addressed EOT and consolidated bios_flags. Restore original numeric
    spelling (00111111b and 02) without changing values. Correct two stale
    comments that still named CS:motorstartup or DS-addressed BDS data.
    Preserve boot entry SS:BP/DI state, 386 check, moved clock routines,
    SYSINIT relocation/boot record handoff, extended INT 13h partition reads,
    far BDS pointers, Compaq disk counting and ECX preservation patch.
    The former standalone MSDOS.SYS loader is not restored: the 950 image
    loads through SYSINIT. Empty ROMDOS conditional is retained. Existing
    shared set2_chs/init_ext_read and call_bios_code paths are retained;
    no parallel implementation or file split was introduced.
52. bios/msint13.asm: restore existing Win386_Init/Exit/Devcall and
    multMULTGETHMAPTR/multMULTALLOCHMA symbols in place of literals, and
    original initialization-test comments and public declaration form.
    Explain the three existing direction-specific CMP encodings instead of
    changing their bytes. Retain 950 Windows instance/configuration services,
    keyboard/video interface, linked HMA block allocation/coalescing, caller
    DS storage, temporary sector pointer and extended-read ECC handling.
    The newer HMA block implementation replaces the old bump allocator;
    it does not coexist with HMAPtr as a duplicate second implementation.

Each edit is followed by its own original-toolchain BIOS/loader rebuild,
fresh IO.SYS packing and FC/B comparisons. Evidence: file51-build.txt and
file52-build.txt. BIOS binaries are unchanged; all three own targets match.
Unaffected kernel/configuration/command outputs are inherited from validated
stages, not claimed newly compiled. All 293 source inputs match each stage.
Final full automatic build remains required at whole-audit completion.

53. bios/msload.asm: necessary unchanged. The effective v6.22 loader is
    retained verbatim in the compile-time ELSE; production makefile selects
    DOS7_CONFIG, so two loaders are not emitted into one image. The selected
    loader preserves the BJ signature, boot parameter handoff, relocation,
    contiguous-cluster batching, FAT12 split-entry/FAT16 decoding, sector
    cache, CHS retries and transfer buffer. These are one loader call graph;
    FAT decoding, sector reads and run reads serve different operations.
    Replacing this with the reference entry protocol would change the 950
    target. No justified source reduction under the fixed-structure rule.
54. bios/pathsrc.asm: no same-name reference; no matching named routines in
    the effective reference BIOS. Reviewed all four routines and shared
    buffer: PATH concatenation, executable selection, extension ranking,
    environment lookup. Their separate entry/exit contracts are retained,
    including the existing find-buffer requirement and search_best result.
    No added alternate implementation. It is explicitly linked by msbio.lnk;
    the verified map retains Path_Crunch and Find_Path_In_Environment at
    0473:9F95 and 0473:A069. No source edit or redundant rebuild.

Counts through 54: modified 12, exact 8, necessary unchanged 5,
no-reference unchanged 29. Tool change remains separately counted as one.
Next: 55 bios/pnpcaps.asm. Latest verified stage:
extras/build/t25-msint13-27044-30683.
