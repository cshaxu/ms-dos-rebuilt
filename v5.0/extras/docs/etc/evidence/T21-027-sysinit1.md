# T21 file 27: bios/sysinit1.asm

Accepted unchanged after reviewing the complete DOS6 diff and the corresponding
older OpenNT implementations. No binary-affecting "upgrade" is authorized merely
to remove a source difference.

| Difference group | Disposition and evidence |
| --- | --- |
| MULTI_CONFIG declarations, default/alternate shell names, query/autoexec, environment workspace, interpreter-header validation and retries | Later DOS6 configuration/shell behavior. Retain omission; files 4, 9, 25 and 26 already establish the selected DOS5 feature surface. |
| MagicBackdoor/NullBackdoor, preload/postload/reserved CDS calls and arena surgery | DoubleSpace-specific integration, absent from this target. Do not restore unused later feature branches or their symbols. |
| found02 stack switching | OpenNT sysinit1.asm lines 499-509 corroborate PUSH BP / MOV AX,8[BP] / PUSH ES / POP SS / MOV SP,BP. Preserve DOS5 machine sequence instead of DOS6 register rearrangement. |
| command_line PUBLIC/data placement and null-terminated transfer | OpenNT lines 234, 706 and 1488-1514 corroborate the older ownership/data and transfer logic. DOS6 moves this data and stores command lengths differently. |
| devdrivenum/drivenumber alias | One physical packet byte with two existing names; it is not a second implementation. DOS6 separates the values for DoubleSpace initialization. Preserve shared storage and current target offsets. |
| Temporary buffer and CDS storage | DOS5 uses confbot and adjusts alloclim when constructing CDSs. DOS6 preallocates 26 CDSs for compressed-volume setup and introduces top_of_cdss/COPYCDS. Preserve the older allocation order and accurate concise comments instead of importing the later dated rationale. |
| ES-save comments | Keep direct save/restore descriptions; DOS6's 1992 BUGBUG discussion is unnecessary and does not describe a required code change. |
| Shell failure, mem_err, EXEC register setup and cmdhalt | Preserve actual target branches, stack order and XOR AX / MOV AH,exec sequence. cmdhalt is used by bios/sysinit2.asm lines 85 and 1094, not an unused extra public alias; removing it would break that caller. It labels one existing self-loop, not a parallel implementation. |
| FatalErr CLI/HLT and stall self-loop | OpenNT FatalErr lines 1936-1943 corroborate CLI/HLT. DOS6 uses its common stall and adds HLT to another loop; inserting/reusing those instructions would change bytes. |
| ClrVDISKHeader password-server workaround | DOS6 adds model/keyboard-controller checks (I070). Retain their absence in the exact target path. |
| TempCDS / get_next_dpb / EndFile | Preserve sequential DPB_NEXT_DPB traversal and original full CDS construction. Do not import DOS6 lookup-by-letter or SlideCDSs/incremental COPYCDS behavior. |
| INSTALL execution result | OpenNT lines 2864-2882 exactly corroborate exec_exit_code, AH=4Dh, resident-status check, error_line and carry result. Retain target behavior rather than DOS6's shorter exit. |

Existing comments and procedure layout follow the applicable reference code.
The few tailored comments describe the retained DOS5 allocation rather than
claiming later authorship. No cosmetic rewrite is needed to justify these
required behavioral/data differences. Empty original conditions remain intact.

Whole-word BOP/NTVDM/VDM/NTIO/dossvc scan returned no hits. The unchanged file
was reassembled in t21-bios-21125-30761; SYSINIT1.OBJ and all other BIOS objects
matched the accepted baseline byte-for-byte, as did linked IO.SYS. The parent
verified DOS/COMMAND outputs also still matched their frozen targets.

Prefix 27/243: 4 modified, 18 reference-identical, 5 necessary differences
unchanged. Next file 28: bios/sysinit2.asm.
