# M6 T27 - Rebuild the Win98 First Edition core

## M6 T27 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Owner admitted the Win98 FE core rebuild. |
| Objective | Build IO.SYS, MSDOS.SYS and COMMAND.COM byte for byte against the frozen floppy. |
| Non-goals | Other DOS source versions, alternate implementations, output patches and guest execution. |
| Reference Baseline | v7.10.1111 commit 038583503f4954d7f6254b7cd5f0c83d529fce02; [frozen FE target](../etc/target-baseline.json). |
| Candidate Proposal | Full source tree from 1111. Reuse verified code blocks and modify the original modules in dependency order. |
| Files And ABI Surface | Loader, BIOS, DOS kernel, configuration and registry, COMMAND and their resource tables. |
| Applicable Rules | [Execution](../rules/EXECUTION.md) and [coding](../rules/CODING.md). |
| Verification | Map binary differences to linked code and resource blocks. Build using inherited tools. Verify and publish with full FC /B and SHA-256. |
| Expected Markers | MATCH for each core file, unchanged inputs and publication PASS. |
| Asset Needs | Frozen targets in ignored extras/baselines/targets; validated outputs in ignored extras/assets. |
| Reporting Requirements | Report actual changed and byte-identical source counts, component evidence and pushed P identifiers. |
| Stop Conditions | Reject target-byte regressions in verified blocks, output substitution and duplicate implementations. |
| Exit Criteria | All three official outputs match the frozen target and the closure is pushed. |
| Original Owner Request | Use 1111 alone to reconstruct the three Win98 FE core components, decide source layout after block diff, and submit and push in MTSP parts. |
| Similar-Issue Sweep | Check each mapped component for shared field, call-site, layout and resource changes. |

P1 freezes the target, records the [binary comparison](../etc/block-baseline.md), and seeds the full source and production build entry.

P1 build stage `cmd-30323-14713` produced the three files. MSDOS.SYS and all COMMAND resource bytes matched the FE target. COMMAND linked code and IO.SYS require further reconstruction. The publication gate remains in force.

P2 restores the five extra SYSINIT slots and localized text in the existing resource source. All 4767 bytes of the linked resource match the frozen FE block. The FE message slots shift later indices; call sites and the remaining BIOS layout are still under reconstruction. The bytes outside the resource remain subject to the complete-image gate.

P3 restores the FE COMMAND version display, DIR /4, transient buffer rounding and DATE century handling in the inherited modules. It also retargets existing SYSINIT call sites after the five inserted message slots. Build stage `cmd-1846-15111` matches all 93880 bytes of COMMAND.COM and all four bytes of MSDOS.SYS. The IO.SYS loader and SYSINIT message block still match. IO.SYS remains open and publication is gated on the full image.

P4 restores RTC tick synchronization and the century rollover correction within the inherited BIOS clock modules. The existing refresh routine is linked with the RTC routines. Stage `cmd-3969-21991` matches the contiguous 1984-byte IO.SYS range at offsets 10535 through 12518, including the restored clock code. IO.SYS remains open.

P5 restores the FE startup date handling and saved boot time in the inherited BIOS and SYSINIT paths. Stage `cmd-6817-22953` matches the 22-byte INT 2Fh dispatch and return block. The 280-byte startup date and time block differs in 11 linked operand bytes, which refer to the relocated printer, file name and boot state. BIOS ends at the target message marker and the configuration payload starts at the target file offset 189440. COMMAND.COM and MSDOS.SYS retain their complete matches.

P6 restores the Windows-directory pointer in the existing configuration bootstrap argument reader and includes its relocation in the existing OMF ordering. Stage `cmd-8603-4092` emits the 267-byte reader at the target offset. The remaining 13 byte differences are in the relocated argument-table references and the three FAR registry calls. The default directory bytes and the initialized pointer offset also match. The remaining configuration code and the full IO.SYS gate stay open.

P7 restores the FE shared pathname limit and the extended mkdir and rename dispatch in the existing DOS kernel modules. It also restores the RegCreateKey front end over the existing RegFindOrCreate routine. Stage `cmd-12554-767` matches the 65-byte FCB rename block and the 294-byte directory dispatch block. RegCreateKey matches all 30 instruction bytes apart from its two DGROUP operand bytes. The packed logo starts at the target file offset 122928. Further kernel bytes and the ASD registry-write path remain open.

P8 restores decimal value-name conversion and removal of a value from a locked registry record in REGREAD. Stage `cmd-13554-12980` matches both conversion routines (164 bytes). The 78-byte removal routine differs in the two displacement bytes of the call to the inherited RegMoveMemory. These routines are dependencies of the FE registry write path.

P9 restores cached registry enumeration and connects chained value lookup to the existing RegQueryValueEx. It updates handle allocation, release, static roots and lookup together. Stage cmd-16349-5807 builds all three images. The 574-byte enumerator and the 226-byte lookup have only linked reference differences. COMMAND.COM and MSDOS.SYS still match in full.

P10 restores the FE registry write chain inside REGOPEN and REGREAD using the existing key handles, cache and extent allocator. In the isolated configuration link, the three new extent operations match 466 target bytes exactly. The 910-byte value writer matches except for 19 linked call displacement bytes. The whole-image build still verifies COMMAND.COM and MSDOS.SYS. IO.SYS remains open.

P11 connects the ASD.DAT import to the existing configuration main and registry APIs. Stage cmd-18119-31508 builds all three images. The six ASD procedures occupy the target offsets and match their 1052 target bytes apart from 12 FAR call operands. IO.SYS is 221990 bytes against 222390 and remains open. COMMAND.COM and MSDOS.SYS continue to match in full.

P12 restores DOS commit and the registry header update in the existing RegSaveFile path. The 21-byte DOS commit wrapper and 39-byte DOS allocation wrapper match their target blocks. Stage cmd-18850-14319 builds IO.SYS at 222102 bytes against 222390, with full matches for COMMAND.COM and MSDOS.SYS. IO.SYS remains open.

P13 restores FE root handle reset and teaches the inherited key record encoder and decoder to persist chained key types. Root reset matches the full 178-byte target block. Stage cmd-19644-4741 builds IO.SYS at 222374 bytes against 222390. COMMAND.COM and MSDOS.SYS remain exact. IO.SYS still has target code and layout differences.

P14 restores the FE startup modifier keys and the early menu scan in the existing SI2FRONT module. Stage cmd-20333-11663 builds all three images. The 364-byte keyboard block aligns to the target by one byte and has 36 operand differences. COMMAND.COM and MSDOS.SYS match in full. IO.SYS remains open.

P15 restores FE key allocation inside the inherited REGREAD allocator, retaining its shared cache services. Its complete 720-byte target block differs in six linked call bytes. Stage cmd-21456-6331 produces 222422 IO.SYS bytes and full matches for COMMAND.COM and MSDOS.SYS. IO.SYS still differs from the frozen image.

P16 integrates the FE signature and version checks into RegReadFile and updates the inherited save routine to mark the correct header state during in-place writes. Stage cmd-22217-20342 brings IO.SYS to the same 222390-byte length as the frozen target, with the first 2048 bytes matching exactly. The BIOS, embedded kernel and configuration still have unresolved instruction or layout differences. COMMAND.COM and MSDOS.SYS remain exact.

P17 removes the two obsolete BOOTDELAY writes from the initial menu scan in SI2FRONT. Stage cmd-22890-6289 aligns the 145-byte menu block with the target modulo a one-byte preceding displacement. Ten linked operand bytes remain in the block. COMMAND.COM and MSDOS.SYS continue to match. IO.SYS remains open.

P18 restores WINVER acceptance, leaves the obsolete BOOTDELAY option as a no-op, and aligns the existing startup stack entry. It initializes the optional registry query type output through the inherited RegQueryValueEx. The 14-byte startup block matches at its exact FE image address. The isolated configuration link matches the 250-byte query block apart from two address operand bytes. Stage cmd-23961-25591 builds all three images; IO.SYS remains open.

P19 removes unused BOOTDELAY storage and the default SETVER driver entry, and restores JO.SYS in the existing earlier-system filename table. The linked filename starts at target offset A752h. Stage cmd-25290-9280 builds all three files; COMMAND.COM and MSDOS.SYS match in full. IO.SYS remains open.

P20 restores FE restart menu selection and the extended DPB check on the boot volume. Stage cmd-26041-23814 matches the 37-byte FAT32 check exactly at BD4Ch, restores the BIOS message marker at 72799 and the boot logo at 122928, and verifies COMMAND.COM and MSDOS.SYS in full. IO.SYS remains open.

P21 restores the shared local rename error exit in FILE. Stage cmd-26799-27076 matches all 45488 bytes of the embedded DOS image and trailing alignment, as well as COMMAND.COM and MSDOS.SYS in full. Remaining IO.SYS differences are in the configuration and BIOS regions and the outer header.

P22 restores FE default disk buffering, JO.SYS execution, the Windows path flag, and the BIOS initialization values in the inherited modules. Formal stage cmd-28007-6290 matches all 187392 bytes from the BIOS start through the configuration boundary, including the embedded kernel and logo. COMMAND.COM and MSDOS.SYS match. The outer header and configuration still differ.

P23 restores FE configuration messages, the original registry path and key record logic, and the historical object relocation grouping. Stage `cmd-30048-6604` exits 0 with all three file comparisons, identical input snapshots, and publication to `extras/assets`. The complete configuration payload and the complete IO.SYS now match. The source ledger has 36 modified and 255 identical files across 291 frozen paths.

S1 and T27 are closed. The [closure audit](T27-closure.md) maps the owner request to the frozen media, source ledger, exact build evidence and pushed implementation.
