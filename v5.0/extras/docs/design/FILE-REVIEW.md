# Ordered source-file review

The frozen universe and sequence are in [file-review-ledger.json](../etc/file-review-ledger.json).
It started with 215 `.asm`, `.inc`, `.c`, `.h`, `.equ` and `.sw` files under
BIOS, DOS, COMMAND, shared includes and message includes, including optional
code. A retired duplicate retains its original ledger index and evidence but
is excluded from the active source universe; its preserved archive is hash-checked.
Link scripts, messages, documentation, binaries and host build tools remain
separate work. Reconcile changes to the universe explicitly; do not silently
renumber or erase a prior record.

Every round must also screen for NT/NTVDM host services, BOP encodings and
known post-DOS-5 features; textual identity to OpenNT or a later DOS reference
does not excuse those findings. The `tools/nt_residue.py` lexical screen scans
comments and conditional branches too. A hit is a review lead, not automatic
proof of execution or version; do not automatically qualify the file until
its disposition is established. A no-hit result does not prove there are no
indirect host dependencies or other later-version code. During ordered manual
review investigate the actual semantics and preserve the target binary.

The owner authorized three rounds:

1. Automatically qualify files byte-identical to a same-name DOS 6, DOS 4 or
   OpenNT reference file.
2. Automatically qualify a remaining file only if all of its code lines are
   covered by identical contiguous passages in same-name reference files.
   Assembly comments, blank lines and edge whitespace are ignored; spelling,
   internal whitespace and string literals are retained. Matching passages
   may come from different versions; each underlying matching block has at
   least two code lines. Alternatively, a file with at least two code lines may
   qualify if every line occurs in order within one same-name reference, even
   when reference-only lines separate matches. C and H comments are retained
   conservatively. Individually reviewed isolated statements and corresponding
   definitions in another reference file may be used when their precise
   reference locations and context are recorded. Files with no code are not qualified. The evidence identifies every
   source and reference line, and conservative misses remain pending.
3. Audit only the remaining files, in the original order. Inspect unmatched
   passages, provenance, NT host seams, structure, names, calling conventions,
   comments, and target evidence to decide whether each file qualifies. Work on
   one file at a time; make only justified changes to that file and record
   evidence and limitations before advancing. Verify affected build scope and
   all three target files if an active build input changes.

Owner clarification: in third-round files, align statements whose only
relevant differences are capitalization, indentation or whitespace with the
corresponding DOS 6 source (DOS 4 where applicable). After alignment, rerun
reference classification and move newly matching files into round 1 or 2.
Preserve target-specific instructions and accurate corrections; verify every
active-source change by a fresh integrated build. This explicitly authorizes
the one-time formatting revisit of already reviewed third-round files. Process
the remaining files in ledger order and record all changes and evidence.

Automatic qualification is a text-based decision under the owner's criteria;
it is not proof of exact DOS 5 history, macro expansion, dependency behavior,
or complete optional-configuration verification. Outside the owner-directed formatting revisit, do not edit other files or
revisit a qualified file. If an indispensable later change would require it,
stop and explain the conflict to the owner. A blocked pending file remains the
current file. Record discoveries about later files without changing them.

Run `python tools/file_review_status.py` to check the frozen universe, completed
file hashes, evidence links, counts and the next pending file. The full sweep
evidence is [file-review-automatic-rounds.json](../etc/evidence/file-review-automatic-rounds.json).

## Second-class conversion audit

The owner directed a further pass over all 48 files classified in round 2.
The frozen order and decisions are in `../etc/round2-to-round1-ledger.json`.
Review exactly one file at a time in original ledger order, and record why each
reference is or is not safe to adopt. Do not restore NT/BOP or post-DOS-5
content merely to obtain an exact reference match. A changed active source
requires a fresh integrated build and all three exact target comparisons; update
the original classification and matching evidence only after verification.
Prior reviews remain preserved.
