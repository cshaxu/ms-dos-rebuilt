# M6 T20 completion audit — 2026-11-13

Result: verified and closed. Objective: restore the three v7.10.1111 core
components from v7.00.950 with full source, minimal unnecessary divergence,
and exact output identity. S1 baseline, S2 implementation and S3 acceptance
are complete. Earlier packet-local pending statuses are historical and are
superseded by this audit and `states/CURRENT.md`.

## Requirements and current evidence

| Requirement | Evidence and disposition |
| --- | --- |
| Fixed 1111 media | `etc/target-baseline.json` identifies the Dell OEM OSR2 disk in `O:/assets/w9xbd`. Final independent FAT12-chain traversal compared each published asset directly with this disk, not only with extracted targets: all three matched. |
| IO.SYS | Clean build `cmd-4039-24987`: 214836 bytes; FC /B passed; SHA256 in `outputs.sha256` equals the frozen target. |
| COMMAND.COM | Same clean build: 93812 bytes; FC /B and target hash passed. |
| MSDOS.SYS | Nine-byte configuration source `dos/msdos.cfg`; output and media match. It is not a second kernel executable. |
| Full source based on 950 | 291 current core files: 174 byte-identical to 950, 116 modified and one necessary new runtime startup source. Three superseded registry modules removed. See `tracking/source-inventory-current.csv`. This is a full tree, not an overlay. |
| No unintegrated modified drafts | All 117 modified/new core files classified: 94 assembled objects, 16 source includes, four executed build recipes, two compiled message inputs and one configuration source. 93 objects are named by link response files; MSLOAD is linked directly by its make rule. |
| Preserve the first implementation path | Registry entry points are implemented in the existing regstart/regopen/regfind/regread modules and their shared regroot data. rapiopen/regstr/rqvalue are removed from both source and build. The four unlinked registry files reginit/regpdiff/regvm/regvmcal are retained byte-identical to 950, not counted as 1111 implementations. |
| Necessary new source only | `bios/crtstart.asm` replaces the extracted CRT startup object in the link list. It expresses startup, stack, error callback and data relocation behavior in assembly. The original object is not also linked. This removed tool-side module-name special cases. |
| No target executable substitution | IO and COMMAND packagers consume linked images and generated message resources; their code-image payloads are copied unchanged. The original logo is an explicit graphic resource. Target executables are comparison inputs only. |
| No output/code patches | `crtlib` retains library code/data/fixups and only resolves library aliases. Startup-specific rewriting was removed. `omforder` preserves code/data and relocation operands, ordering OMF records from source procedure/public boundaries; the unused manual layout mode and six recipes were deleted. Original LINK generates EXEPACK. |
| Historical build form and allowed languages | Original MASM/ML, C, NMAKE, LINK, LIB and message tools; CMD/BAT entry and native C support. Dependency locations/hashes are in `build-dependencies.md` and tools.lst. Scan outside ignored build output found no prohibited script extensions or invocations among those checked, and no binary include directives. |
| Build entry and publication | `extras/build.cmd` prints stages, stops on errors, verifies unchanged source snapshots and all three target files, then publishes to `extras/assets`; final pause retained. Clean invocation returned zero. |
| Build outputs ignored | `.gitignore` excludes extras/build, assets and frozen targets. Git index inspection found no tracked build/assets files; `git check-ignore` confirmed the current result file is ignored. No commit or push was performed. |
| Format-only changes do not trigger rebuilds | Post-build comparison covers all 291 current core inputs: 223 unchanged bytes, 67 trailing whitespace/EOF-only, one indentation/EOF-only. No other difference from the verified build inputs. No additional build was run for these changes. |
| Reliable progress reporting | `tracking/FUNCTION-TRACKING.md` and symbol-inventory-current.csv derive public/procedure counts from this exact build. Generator rejects mismatching images. Source counts use byte comparison with 950. |
| No VM acceptance requirement | Per owner instruction, exact three-file identity is the acceptance gate. No SoftPC mount or boot validation was added. Historical compilers ran through the existing isolated-desktop runner; no Computer Use. |

## Finite convergence ledger

`tracking/source-closure-ledger.csv` covers the union of the 293-file baseline
and the one new source file: 294 dispositions, zero unclassified rows.

- 174 accepted baseline-identical files, as authorized by the owner's first pass.
- 94 assembled/linked changed or added modules (72 with LST; 22 recipes do not emit LST).
- 16 includes, four build recipes, two message inputs and one configuration source.
- Three removed modules superseded by the current implementation/build.

Current INCLUDE evidence includes tranmsg through tdata, dostab/ms_data/lmstub
through msdata, message includes through biosmsg/sysimes/iniclass, and shared
disk/FAT structures through the BIOS/kernel include graph. Resource production
uses BUILDIDX/BUILDMSG; MSDOS configuration is explicitly sourced by build.cmd.

The earlier root-table migration plan, partial-function probes, seed ledger and
S2 dependency frontier describe earlier states. Their unresolved integration
items are discharged by the current input/link classification and full exact
build; they are not independent open work queues. T13 media provenance and
other DOS-version tasks are outside T20 and are not closed by this audit.

## Limits of the completion claim

Recovered assembly is not asserted to be Microsoft's original source text.
The target does not contain a complete symbol table; the original total
function count and original private names remain unknown. Current counts are
1995 public names / 570 explicit public procedures across IO's three main
linked units and 1311 / 204 for COMMAND, not original-function denominators.
Private and label-only routines and precompiled CRT procedure declarations are
not all represented in the public-procedure count. No VM behavior claim is
made beyond the required byte identity.

The requested restoration has no remaining binary mismatch, unresolved build
dependency or unclassified core input. Optional future text polishing or
recovery of original private names is not a prerequisite to this completed task.
