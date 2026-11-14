# T25 S1: files 21 through 37

21. configio.asm: retain FAR C DOS file wrappers and their distinct error/return
    conventions. ReadAll/WriteAll split large transfers into paragraph-aligned
    chunks; Read and Seek expose different interfaces. Preserve observed DOS
    modes and unusual register/error paths rather than silently fixing target
    behavior. No same-name effective v6.22 reference supplies these wrappers.
22. cpath.asm: one path-preparation routine, with existing Config* service calls
    for allocation and copying the alternate file. No duplicate DOS service
    implementation. Keep 64-byte path workspace and compiler immediate forms.
23. crtclose.asm: fclose flushes, releases the stream buffer, closes the DOS
    handle and unlinks temporary files through shared services. Stream state
    and temporary-name construction are necessary distinct responsibilities.
24. crtcmp.asm: one comparison loop exports both spelling aliases. Only two
    CMP instructions use documented raw alternate encodings; no second body.
25. crtcomit.asm: retain handle validation, pre-3.30 bypass, DOS commit call and
    errno mapping. The historical-version check is runtime behavior present
    in the target, not a second source build path to delete.
26. crtend.asm: __end is a zero-length BSS boundary, linked last. Moving it into
    an earlier module changes its value; do not merge boundary definitions.
27. crtflush.asm: fflush, internal flush and flush-all share the stream loop
    and low-level writer. Explicit near returns and cleanup differ from FAR
    public wrappers and are retained. PUSH imm8 encodings are documented.
28. crtpaths.asm: two equal strings occupy independently addressed target data
    positions. Aliasing them would change the data layout and relocations.
29. crtprint.asm: printf and sprintf share __output; one source is assembled
    with two switches to maintain link contributions. Keep their distinct
    stream setup and output handling; the BSS declarations establish order.
30. crtread.asm: binary/text paths implement stream flags, CR/LF and Ctrl-Z
    translation, terminal checks and seek-back. Shared __dosretax owns return
    conversion. This is distinct from the configuration file-transfer wrappers.
31. devmark.inc: exact effective v6.22 source.
32. drivechk.asm: compressed-host IOCTL and absolute-read mapping probes have
    different protocols/signatures. They share the IOCTL helper where possible;
    do not merge or discard one of the two target interfaces.
33. inc.asm: exact effective v6.22 source.
34. initclk.asm: compare actual clock procedures to effective v6.22 msinit.asm,
    not just its absent same-name file. Reference comments, BCD conversion,
    validators and calendar algorithm are retained. Required 950 changes are
    code/data segment access, saved DS/ES, daycnt result location and near tick
    call. Original duplicate outchr EXTRN also occurs in the reference and is
    left intact under the owner's reference-fidelity preference. Split module
    and its link position remain because structure must not change.
35. logocode.asm: VGA mode/palette/planar row copying, video trampoline and
    external-or-saved-logo reader serve separate operations. Four plane loops
    have different source offsets and masks and preserve emitted target code.
    Decoder is included once from mrcf.inc, not reimplemented in this file.
36. logpart.asm: loading/result wrappers share config_log_send and the same
    buffer. Result changes only the fixed prefix, preserving the recorded
    device-name suffix. One INT 2Fh log service path, no duplicate writer.
37. makefile: use the effective v6.22 link_opts = /MAP form in both link rules;
    arrange the message dependency list in the reference's three-line groups.
    Preserve explicit 950 module dependencies, assembler selection, switches
    and outputs. Do not reintroduce unsupported ROM/other distribution targets.
    Rebuild all BIOS/loader targets with NMAKE /a, compare generated loader and
    BIOS bytes, then repack IO.SYS and compare the own frozen 950 target.

All entries except 31,33,37 have no same-name reference and remain unchanged.
No source added, merged, moved, or behavior altered. Through 37: modified 5,
exact 4, necessary unchanged 2, no-reference unchanged 26. Next: 38 mblate.asm.
File 37 acceptance requires file37-build.txt to report PASS.
