# M1 T2 S1 build investigation — in progress

The primary OpenNT COMMAND makefile includes v86/make.inc. Defaults select COUNTRY=usa-ms; include search is the component, v86/inc, base/mvdm/inc and v86/messages. `command.exc` uses `link16 @command.lnk`; the COM step copies the EXC to EXE, invokes `reloc`, then deletes the intermediate. MASM defaults are -Mx -t -W1 plus include switches. `binplace` is a packaging step, not needed to prove assembly output.

[Lexical include evidence](m1-t2-command-includes.json) from `python tools/command_dependencies.py` scans 80 files and 259 include edges. The only unresolved tokens are &ext and &utilname.CTL; both require macro expansion analysis. This scanner does not select conditional branches or prove complete buildability. Relevant outer shared includes live outside the T1 scoped manifest and must be pinned before compilation.

[Tool inventory](m1-t2-tools.json) records 12 historical tool candidates and SHA-256 identities. DOS 6 c6ers/tools6/bin includes MASM, BUILDMSG, NMAKE, LINK and RELOC. The LINK has an NE extended header; executable format inspection does not prove DOS stub functionality. The other inspected candidates have no identified extended header. Exact tool versions and runtime execution remain to be verified; no host execution or successful compilation is claimed. DOS 4 and DOS 6 tool alternatives are candidates, not interchangeable certified dependencies.

Next: inspect macro-generated includes and tool banners, pin the additional includes and chosen tools, then run a small MASM assembly in an appropriate 16-bit environment. Keep S1 active until the executable experiment or concrete missing-input disposition is established.

## First executable assembly result

On 2026-11-06 the existing Win32 MASM at ntvdm64/tools/opennt/tools16/masm.exe assembled unmodified OpenNT tfor.asm using the documented make.inc include order and flags. Listing identifies Microsoft Macro Assembler 5.NT.02, with 0 warning errors and 0 severe errors; native exit code 0. Generated OMF object is 1928 bytes; listing is 72708 bytes. [Input and output hashes](m1-t2-tfor-assembly.json) pin the experiment. `tools/assemble_command_slice.ps1` reproduces it. Disposable outputs are under build/t2-s1 and remain owned by active S1 while object analysis proceeds.

This establishes an executable source-to-object path only. The object has relocations and does not yet establish any byte-identical target routine. Next verify OMF record integrity and analyze target correspondence; the complete link/RELOC chain and full build remain unverified. The lexical includes beyond T1 scope still need a dependency manifest before this becomes a frozen reproducible toolchain.

## Full COMMAND object probe

`tools/assemble_command_reference.py` compiles all 34 objects listed by the OpenNT link response file, preserving source inputs. Initial probe: 32 succeeded; tprintf and tdata failed solely on missing COMMAND.CTL. Staged usa-ms.msg/idx and command.skl with tools/opennt/tools16/buildmsg.exe; DOSBox 0.74-3 executed `buildmsg usa-ms command.skl > msg.log`. The batch checked ERRORLEVEL and wrote PASS; DOSBox exited 0. It generated COMMAND.CTL and CL1/CL2/CL3/CL4/CLF. Hashes are in m1-t2-message-generation.json. The staging batch genmsg.bat remains in owned scratch. This is a build-tool run, not a boot test of DOS 5 under SoftPC.

Re-running the 34-object probe succeeded for every module; m1-t2-command-assembly.json records per-module results and hashes. Native link16.exe then failed at process startup with Illegal System DLL Relocation. The subsequently printed LINK_EXIT=0 was a stale PowerShell LASTEXITCODE from the preceding command, not a linker result; no successful link is claimed. Next action: select and validate a compatible historical linker or repair a disposable copy of the native linker with explicit provenance. Full source-to-binary reconstruction remains unachieved.

## Historical link and first binary comparison

`tools/link_command_reference.py` runs the unmodified DOS 6 c6ers/tools6/bin LINK and RELOC in DOSBox with the OpenNT response file. LINK identifies itself as 5.10, reports warning L4021 (no stack segment), and the batch's errorlevel checks pass for link, copy and RELOC. A second complete link/RELOC run reproduced SHA-256 908a77ac617c2d741f0aa1b73f73973dcf29adc91f092e5bcb02173c8c732c43. Output is 50384 bytes, not the target's 47845 bytes. This is an OpenNT reference build, not DOS 5 reconstruction. The native LINK16 remains unusable here and was not modified.

m1-t2-command-link.json records tool/output hashes and logs. m1-t2-command-include-hashes.json pins the observed lexical include graph, including shared files outside the earlier scopes; it is not a conditional macro-expansion proof. m1-t2-command-target-anchors.json records 972 sampled 32-byte reference windows found uniquely in the target (stride 16). These overlap and are not a coverage percentage or semantic equivalence result. They provide location hypotheses for symbol-aware reconstruction. Reference MAP is in owned scratch and contains segment layout and public symbols. Full DOS 5 identity and SoftPC boot are unverified.

## Symbol-to-target mapping

`tools/map_command_symbols.py` checks that the linked EXE has zero MZ relocation entries and that every byte after its 512-byte header plus 256-byte PSP placeholder equals reference COMMAND.COM. Thus a MAP address maps to COM offset segment*16+offset-256 for this build, verified against the actual conversion rather than assumed. It scans 818 public symbols whose 32-byte prefixes lie inside the file, including data symbols. 212 have unique exact 32-byte matches in target COMMAND.COM; forward exact lengths are recorded in m1-t2-command-symbol-map.json. Symbols can alias and ranges overlap; counts are not restored-routine counts or coverage percentages. $for and ForOff prefixes do not match directly, so address operands and actual code changes must be separated before drawing conclusions.

## First reconstructed encoding slice: ForOff

Derived from OpenNT tfor.asm ForOff, reference file offset 15208, length 39. Masking only four known external word operands (relative offsets 5,9,26,33) yields a unique target match at COMMAND.COM file offset 0x3286. ResSeg changes from 0x95F2 to 0x8D77; ForPtr from 0x02B8 to 0x02B3 (two references); ForFlag from 0x02B7 to 0x02B2. Unmasked opcodes, branch displacement and constants match. The repeated ForPtr reference agrees. These symbol assignments remain inferred until broader references and layout are reconciled.

cmd/command/tfor.asm now contains the readable ForOff reconstruction only, not a full TFOR module. tests/foroff_slice.asm supplies the provisional address equates. Compile with MASM 5.NT.02 -Mx -t -W1 tests/foroff_slice.asm,build/t2-s1/foroff.obj,build/t2-s1/foroff.lst;. An initial missing CS assumption produced errors and was corrected with ASSUME CS:TRANCODE. Final assembly succeeds. All OMF record checksums pass; there are no FIXUPP records, and the sole segment LEDATA is exactly 39 target bytes. SHA-256 and limitation are in m1-t2-foroff-slice.json. This proves source encoding for this bounded routine, not runtime behavior, full TFOR or complete COMMAND identity.

## Full TFOR module boundary

`tools/compare_tfor_module.py` compares reference offset 0x38c1 and target offset 0x2fdf for 0x2ce (718) bytes, using the assembled module length and the unique ForOff endpoint. All 72 differing bytes fall within MASM E-annotated operands: 52 changed external-reference words. Every R-annotated word and all unmasked bytes match. The ledger records each annotated operand and source expression. This does not yet bind all external symbols or prove their runtime meaning.

The full unchanged OpenNT TFOR source now occupies cmd/command/tfor.asm as the reconstruction baseline. The earlier ForOff-only source moved to tests/fixtures/foroff.asm, and its harness include was updated. No target bytes were embedded or patched into production output. Full source closure and target linker layout remain outstanding. This extends the source baseline, not a claim that the whole module is independently buildable from this project yet.

## Local COMMAND source closure

Imported 109 original files into cmd/command, inc, inc/ntvdm and messages; each origin and destination hash is recorded in m1-t2-command-import.json. Existing nonidentical files are rejected by the import operation. Includes specific to NTVDM remain explicitly segregated. `python tools/assemble_command_reference.py --local-source` compiles the local files into build/t2-local. It reuses the verified generated COMMAND.CL*/CTL files from the prior stage, and still uses the external MASM binary. All 34 local object hashes equal the reference object hashes. This establishes source import fidelity, not target DOS 5 binary equivalence or a clean build package.

The first local attempt failed with command-line parsing errors and missing comsw.asm using long absolute include arguments. Relative include paths from the working stage resolve those failures; all modules then pass. The precise assembler length limit has not been measured. No reference sources or assembler binaries were modified.

Clean local pipeline: tools/build_command.py independently generated all messages and objects in a fresh stage, linked and converted successfully; final hash matches the reference. m1-t2-clean-build.json pins tools and result. T2 closes via its completion audit; target recovery continues in T3.
