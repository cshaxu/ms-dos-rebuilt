# M6 T25 S1 P56: files 152-153

152. dos/devcache.asm -- accepted_modified (no same-name effective reference).
Compare the full module with its source paragraphs in effective v6.22 dev.asm.
Keep inherited cache algorithms and paragraph organization; retain CS-relative
cache state, removal of two redundant CMP AX,0 operations, and the VIRREAD
SC_FLAG precheck moved to its caller. DEV calls this single cache implementation.
The existing module/link ordering preserves target layout; no merging or second
implementation is introduced.

Remove 19 unused copied declarations: IOXAD, IOSCNT, DEVIOBUF, IOCALL, IOMED,
IORCHR, DMAAdd, CallDevAd, DPBHead, ThisSFT, ThisDPB, VerFlg, CALLNEWSC,
InterChar, InterCon, SaveCurFlg, DOS34_FLAG, fshare, IoStatFail. The remaining
ten DOSDATA declarations are consumed by the cache paragraphs.
Correct copied module TITLE/NAME and contents list, split external declarations,
restore segment/end formatting, and correct the blanket SS-override notes for
the actual CS-relative cache fields. Correct VIRREAD's misnamed procedure header
and its required nonzero SC_FLAG entry, checked in DEV before the call.
No executable instruction or data value changed.

Original NMAKE/MASM/LINK freshly rebuilds the kernel byte-identical. IO.SYS
freshly repacked from it matches the frozen target; the two inherited unaffected
images also compare exact. All 293 source inputs match the stage.
Evidence: file152-build.txt, file152-make.txt. Stage recorded in build evidence.

153. dos/dinfo.asm -- accepted_exact. Direct FC/B against the frozen effective
v6.22 supplier v6.2/dos/dinfo.asm reports no differences. No edit or rebuild.

Prefix 153/293: modified 76, exact 22, necessary unchanged 19, no same-name
reference unchanged 36. Separate modified tool one. Next: 154 dos/dir.asm.
Final full build and completion audit remain pending.
