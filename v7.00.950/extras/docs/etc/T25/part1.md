# T25 S1: files 4 through 10

Reference: effective v6.22 only. These dispositions are accepted after file 4's
build passes; later unchanged files do not introduce unverified edits.

4. bios/biostail.asm: retains boot-log open/write/close/notification, rotation,
   hex conversion and CONFIG$ read/init dispatch in one linked module. No
   corresponding v6.22 module implements these interfaces. Correct the open
   procedure comment: AX is zero with a ready handle, FFFFh when disabled,
   and a DOS open failure returns its actual AX error code with carry set.
   The seek result is not propagated: the following XOR clears AX/flags, so
   do not claim seek failures are returned. No instruction or data changed.
   Raw timer bytes document a 32-bit absolute-address MOV with target prefix
   order; do not replace it with a superficially equivalent 16-bit addressing
   form or change encoding without assembler evidence. Keep existing module
   placement and link order. BIOSTAIL.OBJ directly compares identical to
   accepted cmd-5418-14694; full run cmd-21179-26898 supplies final verification.
5. bios/biostruc.inc: exact effective v6.22 source.
6. bios/cfgdata.asm: no same-name reference. Shared BSS is separately owned
   and grouped for CRT clearing and referenced by configuration/registry code.
   Unresolved ranges remain explicitly unidentified. Merging initialized and
   common storage or dropping apparent unused spans would change layout.
7. bios/cfginit.asm: no same-name reference. Segment declarations establish
   code/data order; CFGINIT_HEAD and CFGINIT_TAIL select two objects from one
   maintained source via config.mak. Tables use actual FAR symbols. Repeated
   strings belong to separate target data references; no second algorithm.
8. bios/cfgioctl.asm: no same-name reference. Read and write are distinct FAR C
   interfaces with different IOCTL subfunctions; small repeated prologue and
   epilogue reflect target code. One routine with a new dispatcher would alter
   both ABI/encoding, so retain the two original-form PROC blocks.
9. bios/cfgline.asm: no same-name reference. Profile-name lookup, comparison,
   bounded line reading and unused-name selection each have separate callers
   and behavior. Registry and CRT services are called rather than duplicated.
   Preserve near calls paired with pushed CS and target epilogues/alignment.
10. bios/cfgmain.asm: no same-name reference. One entry initializes registry,
    reads seven bootstrap values, selects hardware profile, terminates registry
    and publishes CONFIG$ data. Empty __setargv/__setenvp implement intentional
    CRT hooks because PSP command-tail handling is local. Do not replace them
    with a second command-line parser or remove the hook symbols.

No source file added, moved or merged. All newly inspected modules without a
same-name reference remain honest no-reference dispositions, not text-identity
claims or recovered Microsoft symbol-name claims.

Build outcome: all compiler/link phases completed, but the original ioimage
tool failed because the new link map spells the public symbol SI_END whereas
its lookup expected case-sensitive SI_end. This is not a DOS-code mismatch.
One production tool line was corrected to _stricmp. Both observed map spellings
resolve to the same address; an absent symbol still fails. Repackaging the
fresh linked images with the corrected tool produces all three exact targets.
The original build FAIL record is preserved; this is verified completion by
resuming packaging, not an assertion that the original build.cmd run passed.
All 293 current source inputs match this build's input copies. Assets already
equal targets and need no replacement. Full automatic build with this tool
repair remains a final T25 closure check.
