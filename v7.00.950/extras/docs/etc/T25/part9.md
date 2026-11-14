# T25 S1: files 69 through 82

69. bios/regopen.asm: reviewed all 21 procedures: path traversal and creation,
    key records, value lookup/removal/update/enumeration, recursive deletion,
    allocation/free lists, record growth/relocation and cached key loading.
    Remove the unused RegPathBufferEnd external; keep the used buffer and
    existing shared helpers. Growth/shrink copy directions handle overlap;
    adjacent growth, compaction and relocation have different ownership and
    failure paths. No same-name effective v6.22 source exists. Preserve these
    target operations and the existing file/segment organization.
70. bios/regpdiff.asm: replace the repeated generic header and incorrect
    FAR C description with the actual argument, signed DX:AX difference and
    callee cleanup contract. RET 8 removes the two far pointers. Preserve
    the segment-difference scaling and borrow propagation exactly.
71. bios/regread.asm: no edit. Reviewed all 28 procedures, including complete
    load/save paths, cache ownership, validation, allocation, block growth,
    compaction, index relocation, recovery and dirty-state propagation.
    In-place writes and replacement files serve different layout states and
    share RegWriteDataBlock. Key/data/header validators use distinct layouts;
    checksum logic is shared. Keep the signed count bound, reserve retry,
    cleanup order and existing binary behavior. No same-name reference.
72. bios/regroot.asm: no edit. Seven 28h records already use RootHandle to
    avoid repeated declarations. Preserve root policy values, initialized
    lists/reserve/path strings and trailing storage; no same-name reference.
73. bios/regstart.asm: no edit. Reviewed all nine procedures, provider/local
    initialization, system/user root relationships, buffer/mount/handle
    ownership, shared empty-file initialization and flush error retention.
    System and user paths have different recovery conditions; merging them
    would change target flow. Existing root accesses are symbolic. No
    same-name effective-reference file; retain the current structure.
74. bios/regstr.asm: no edit. Eight shared string/path primitives have
    distinct count, folding, terminator and return conventions. Copy/append
    share instruction shapes but are separately emitted target entry bodies;
    preserve layout and existing operation labels. No same-name reference.
75. bios/regvm.asm: correct the stale REGIO.ASM module title to REGVM.
    Preserve Windows-path detection (INT 2Fh 1613h/1600h), VMM entry discovery
    (1684h), registers and return values. This is Windows 950 behavior, not
    an NT/BOP path; no same-name effective-reference file exists.
76. bios/regvmcal.asm: replace sixteen repeated service wrapper bodies with
    a single RegVMCall MASM macro, parameterized by entry, service and argument
    byte count. Keep every public FAR entry, service immediate, RET immediate,
    declaration order and instruction body. Keep RegInvalidBlock and
    RegNotifyLoad separate. Correct module title. This reduces source
    duplication without merging runtime entries or adding a second path.
77-82. bios/rom8k.inc, romdinit.asm, romdrive.asm, romrd.asm, romrdhi.asm,
    romrdlo.asm: FC /B exact against frozen effective-v6.22 supplier files.
    No edits or unnecessary compilation.

Verification: file69-build.txt records fresh assembly, production regkeys
OMF layout, fresh CONFIG.EXE link equal to the previous verified link and
fresh IO.SYS packing equal to the frozen 950 target. Files 70, 75 and 76
were each freshly assembled before advancing; each OBJ is byte-identical
to its preceding stage. All 293 current sources match the latest stage;
all three images compare exact against their own targets. The latter
incremental stages inherit the linked images; no new full-build claim.

Counts through 82: modified 27, exact 17, necessary unchanged 5,
no-reference unchanged 33. Tooling changes remain 1, separately counted.
Latest stage: extras/build/t25-regvmcal-31253-24515.
Next: 83 bios/rqvalue.asm. T25 remains active; full-scope completion audit
and final automatic build remain pending.
