# T25 S1: files 11 through 20

Reference remains effective v6.22 only. Changes are accepted in frozen order,
with each changed object compiled and checked before subsequent edits.

11. bios/cfgmatch.asm: replace duplicated recovery boilerplate with the actual
    FAR C interface, nine-ID bound, result count/flag and DX:AX return. No
    instruction changes. Fresh CFGMATCH.OBJ equals the accepted prior object.
12. bios/cfgmem.asm: retain distinct allocate/free/reallocate services. Resize
    first tries DOS 4Ah, then allocation and a segment-crossing copy; freeing
    the original is conditional on successful replacement allocation. The
    signed-immediate ADC encoding is explicitly documented, not hidden data.
13. bios/cfgmenu.asm: retain selection and UI coordination in one module.
    Selection handles zero, one and multiple matches, with a bounded new-name
    choice. UI calls the existing registry, matching and capability services;
    it does not supply second implementations of them. Preserve near calls
    paired with PUSH CS and the separate caller-owned output pointers.
14. bios/cfgmsg.asm: retain indexed strings and two resource segments; offsets
    are relative to ConfigMessageText. ConfigGetMessage returns DX:AX without
    copying the resource. Trailer and padding are target data, not redundant
    algorithms. No same-name effective reference supports replacing it.
15. bios/cfgpub.asm: replace repeated generated header prose with its actual
    no-argument FAR C interface and CONFIG$ buffer/header/record role. The
    signature, allocation request, record traversal and copy sizes remain.
    Fresh raw OBJ initially differed from an already ordered prior OBJ; applying
    the existing production omforder step (17 fixups, one record) makes the
    entire OBJ equal. No new production special case was introduced.
16. bios/cfgseg.asm: retain the segment-order declarations. They establish CRT
    BSS/exit-table/common storage and configuration/registry CODE order before
    later objects; they are not duplicate implementations. Link response file
    places this object first. Merging this into a later object risks layout.
17. bios/cfgzero.asm: remove false boilerplate about profile bounds and DS
    restoration. The actual FAR procedure takes no arguments and returns zero
    in AX. Preserve the public procedure and EVEN alignment. Fresh OBJ equals
    the prior object byte-for-byte.
18. bios/config.inc: the reference diff consists only of six conditional 950
    selector definitions (ACCDATE and HIGH variants). Existing reference text
    is intact, including relative ordering. The makefile enables DOS7_CONFIG;
    parsing/dispatch uses added selectors. Preserve the conditional form.
19. bios/config.lnk: conventional LINK response syntax, configuration objects
    followed by extracted CRT objects and explicit output/map. Object order
    defines target layout. Shared source builds HEAD/TAIL and PRINTF/SPRINTF
    objects; these are not duplicate maintained source implementations.
20. bios/config.mak: retain original-tool NMAKE suffix rule and explicit rules
    for shared-source variants. All inputs are maintained ASM; no alternate
    script language or binary patch command in this makefile. Target list is
    consumed by production cfgasm and links through config.lnk.

Files 12-14,16,19-20 have no same-name effective reference and are unchanged;
this is not a claim of source identity or original Microsoft symbol provenance.
No files added, moved, or merged. Counts through 20: modified 4, exact 2,
necessary unchanged 2, no-reference unchanged 12. Next is 21 configio.asm.

Incremental evidence: file11-build.txt, file15-build.txt, file17-build.txt.
Each verifies all 293 current source inputs against the stage. Changed objects
were freshly assembled; outputs inherited from the validated complete build
remain target-identical because replacement objects are byte-identical. These
checks are not fresh full links. The full automatic closure build remains due.
Latest verified incremental stage: extras/build/t25-cfgzero-23188-18031.
