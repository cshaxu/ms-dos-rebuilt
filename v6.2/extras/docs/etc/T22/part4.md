# T22 S1: files 50 through 221

Source comparison is exclusively against v6.0. Every differing file in this
range was read as a complete source diff in fixed order. Exact files retain
their original bytes and reference hashes; no compilation required for them.

50. cmd/command/dir.asm: separate the added anonymous label from the original
    JMP drCom line, restoring that original line verbatim. No instruction or
    symbol changed. Keep SetDisplayWidth, the wide-directory padding descriptor
    and call: these select the target 40/80-column widths and grouping flags.
    One original DIR display flow, not a separate implementation.
54. init.asm: retain /Y import, parser branch and SetYSwitch state change.
    Expanded conditional jumps are needed by the target layout; existing
    /C, /K, /E, /MSG dispatch remains in the original parser.
61. rdata.asm: two required resident words and their exports only. Existing
    segment/data structure remains, with descriptive comments on additions.
64. stub.asm: preserve the three target tail bytes spelled as DB 'cox'. Their
    origin is explicitly unknown; do not invent functionality or provenance.
70. tcode.asm: retain batch/single-command origin state and /Y stepping in
    the existing input path. BatchStep uses existing message and newline
    services; repeated console reads are the extended-key handling, not a
    second execution implementation. Header ENTRY/EXIT/USED style is retained.
71. tdata.asm: three help IDs, -Y switch characters, COPYCMD name and generated
    message aliases are required. Aliases share storage instead of duplicating
    answer characters. Existing table and MSG_SERVICES organization retained.
75. tmisc1.asm: SWCOUNT 8 matches cparse and the eight-character switch_list.
79. tprintf.asm: export the existing SYSDISPMSG for COPY; no duplicate routine.
80. tranmsg.asm: retain grouping bit, wider numeric fields, wide padding and
    batch prompt descriptors. Same original table structure, KOREA conditional
    and comments. Removing any of these data changes would change target bytes.
81. tspc.asm: COPY's 11-byte substitution list and three state bytes belong in
    the existing transient workspace. No separate allocation or alternate path.
83. uinit.asm: ninth /Y parser entry uses the existing parameter-table form.
    The count and pointer additions agree with INIT; preserve existing entries.
95. dos/dir.asm: JB-to-JNZ boundary check and explicit CLC are required code
    changes. Removing the old 'Always clears carry' comment is appropriate:
    the explicit CLC is precisely what now establishes success on this path.
157. inc/bdsize.inc: only BIOS/DOS data-size equates differ, preserving exact
    original syntax. These describe this build, not reference-version sizes.
176. ds_vers.inc: internal revision 10 replaces 6; no other difference.
197. msgserv.asm: COMT enables input services and wraps the existing number
    conversion with grouping/country handling. Shared conversion is reused.
    Existing COMR and non-COMT branches remain. Retain target NOP and branch
    layout; there is no justified byte-preserving code deletion here.
212. sysmsg.inc: second/third separator positions 7 and 11 account for inserted
    separators. Original equate structure/comments unchanged.
217. versiona.inc: minor version 20 is required; all original syntax retained.

All other files through 221 are byte-identical to their recorded DOS6 source.
The verifier rechecks current source hashes against the frozen inventory and
reference hashes against actual DOS6 files. Modified files have post-edit
hashes in reviewed.csv; entry hashes remain in inventory.csv.

File 50 build: cmd-3702-9267. DIR.OBJ is byte-identical to cmd-3212-2638.
All three compiled outputs match v6.20 targets. See file50-build-result.txt.
No source files after 50 were edited or compiled gratuitously in this part.

Remaining: files 222-225, language inputs without same-name DOS6 sources.
These must be separately reviewed; they are not reference-identical files.
