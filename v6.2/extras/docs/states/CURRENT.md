# DOS 6.20 DOS6-only source audit

## M5 T22 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; T22 follows closed T21
Admission And Approval | Owner explicitly requested v6.2 audit in fixed DIR order; proceed autonomously
Objective | Minimize unnecessary v6.2 differences against original v6.0 source while preserving current structure and DOS6.20 output bytes
Non-goals | No other DOS reference versions, no cross-version image comparison, no directory restructuring, no speculative simplification of original code
Reference Baseline | O:/repos.hobby/ms-dos-archaeology/v6.0 source only; v6.2/extras/baselines/targets for output acceptance only
Candidate Proposal | Freeze actual dir /a /b /s order; audit each file, retain necessary differences, restore reference forms where justified
Files And ABI Surface | All 225 files under bios, cmd, dos, inc, lang; metadata and ignored builds excluded from source universe
Applicable Rules | Latest owner DOS6-only restriction supersedes broader historical reference lists; CMD/BAT/C only, no Computer Use, no forbidden temporary paths
Verification | Every edited file must compile affected scope and preserve pre-edit outputs before advancing; three core outputs must match frozen DOS6.20 targets; unchanged files do not require redundant compilation
Expected Markers | Fixed ordinal, entry hash, reference hash/path, disposition and verification evidence for each file
Asset Needs | Existing original compiler tools and isolated runner; extras/build staging, extras/assets outputs
Reporting Requirements | Modified count, exact-reference count, necessary-difference count, current ordinal and remaining count; distinguish global hash classification from completed audit
Stop Conditions | Changed output, ambiguous provenance, concurrent source change, failed compiler; repair before advancing the file
Exit Criteria | All 225 records dispositioned; each edit verified; separate T completion audit and unchanged three targets
Original Owner Request | Audit v6.2 in DIR order against DOS6 only, minimize diff and preserve structure
Similar-Issue Sweep | Follow fixed sequence; preserve original empty conditionals, comments and declarations; avoid duplicate paths and invented wrappers

S1 and T22 closed after full-scope verification. Prior packet archived at history/pre-T22-current.md.

## Frozen scope and current position

`etc/T22/dir-raw.txt` records the actual `dir /a /b /s` output. `inventory.csv`
retains the filtered order and source entry hashes; `references.csv` records
same-name DOS6 reference paths and hashes. Source filtering preserves DIR order.
Whole-scope classification: 225 files, 195 exact and 30 differing.

Completed: 225/225. Modified: 4; exact: 195; retained necessary differences without edits: 22;
accepted without same-name reference: 4. No next file and no active S remains.

File 10, bios/msbio1.asm: the sole difference is the bds2 structure initializer
`<bds3,seg Bios_Data,0,1>`. The logical drive byte must be 1. Existing retained
file-review-008-msbio1.json identifies target offset 2397 and the 0-to-1 change.
Original DOS6 structure initializer syntax, surrounding comments and layout are
already retained. No safe reduction is justified; no source edit or rebuild.

Current extras/assets IO.SYS, MSDOS.SYS and COMMAND.COM were directly compared
with the same-version frozen targets using FC /B: all three have no differences.
This is an existing-artifact check, not a claim of a fresh compilation.

Subsequent verification: files 34 and 35 restored 1 and 14 original DOS6 source
lines respectively, without instruction changes. Each was separately compiled
and byte-verified before acceptance. See etc/T22/part2.md, reviewed.csv and the
retained result files for cmd-2134-27375 and cmd-2556-4896. Both edited objects
also compare byte-identical to their respective preceding build objects.

File 45 restored original VerVal declaration and Not_SlashV convergence label
without changing instructions or branch layout. COPY.OBJ compares identical
to the preceding accepted build. Full build cmd-3212-2638 verifies all three
targets; see etc/T22/part3.md and file45-build-result.txt.

File 50 restored the original standalone JMP line beside an added anonymous
label. DIR.OBJ and all three targets were byte-verified by cmd-3702-9267.
The remaining differences through file 221 were reviewed in source order and
retained as necessary. See etc/T22/part4.md. All 195 exact files have been
accepted after current source/reference hash verification. Four language files
were subsequently reviewed separately because the DOS6 source tree has no same-name reference inputs.

Final language review: etc/T22/part5.md. All four remain unchanged and have
accepted_no_reference dispositions, not exact-source claims. Final verification
confirms all 225 current source inputs equal the last accepted build inputs,
and all three target/build/asset hashes agree. Direct FC/B of all three assets
against DOS6.20 targets also passed. See etc/T22/final-check.txt and
history/M5-T22-completion-audit.md for the requirement-by-requirement closure.
