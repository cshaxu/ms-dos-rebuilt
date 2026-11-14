# M6 T25 S1 P51: files 142-144

142. dos/abort.asm -- accepted_necessary. Full effective-reference diff has
the null FCB-table guard and two ClearDirSft calls in place of direct reference
count clearing. The shared dos/dir.asm helper clears both the count and saved
directory association while preserving general registers. Keep these changes;
no duplicate cleanup path or unnecessary formatting change found.

143. dos/alloc.asm -- accepted_necessary. The sole difference selects the
sign-extended immediate encoding of CMP AX,-1. Attempting the ordinary mnemonic
with the original assembler emitted 3D FF FF instead of 83 F8 FF. Reject that
attempt and restore the accepted source. The object mismatch and checksum change
are retained in file143-rejected-build.txt (stage t25-alloc-25309-10211).
No rejected source or object is adopted. The following 293-input check confirms
the restored source matches the accepted stage.

144. dos/buf.asm -- accepted_modified. Full effective-reference diff reviewed.
Normalize only added declarations/instructions to the inherited tab columns;
preserve the inherited M039 instruction formatting. Remove a stale SS-override
comment on a CS access and the leftover fragment of the old write-success
comment. Retain the reverse queue search/free-buffer preference, removal of
LASTBUFFER, relocated cache fields, per-drive flush state and target carry
calculation. Explicit CMP register encoding stays intact. No instruction,
operand, data value, label or conditional changed.

Validation: original MASM freshly compiled BUF.OBJ, which compares byte-exact
to the previous accepted object. All 293 source inputs match the stage;
the three inherited images compare exact with their own frozen 950 targets.
This is object-preservation evidence, not a new full link or repack.
Stage: extras/build/t25-buf-26292-1449; file144-build.txt.

Prefix 144/293: modified 71, exact 21, necessary unchanged 16, no same-name
reference unchanged 36. Separate modified tool count one. Next: 145 dos/close.asm.
Final full build and complete LFN semantic acceptance remain pending.
