# M6 T25 S1 P65: files 164-167

164 dos/dosmes.inc: accepted_necessary. Complete reference diff consists only
of omitted include divmes.inc and include yesno.asm. These emit message bytes,
length fields and four NLS bytes, rather than declarations only. Reinstating
them would add bytes to the existing verified kernel layout. No alternate
implementation or formatting changes to remove. Retained unchanged.

165 dos/dosprint.asm: accepted_exact. FC /B against effective v6.22 supplier
v6.2/dos/dosprint.asm reports no differences. No rebuild needed.

166 dos/dostab.asm: accepted_modified. Full reference comparison and full
source read. Retained 950 filename uppercase mappings, moved FILE_CHAR_TAB,
HMA/executable-patch state, removal of obsolete data, relocated secondary
cache data, and version-4 Windows instance tables including the second table
and nesting counters. Restoring reference data would change layout/content.
Moved the original file-character-list heading to FILE_CHAR_TAB; removed
the orphan VxDpath comment after that variable's removal. Restored M074/M019
comments on corresponding instance entries. Normalized only new public/data
declarations to neighboring original style. No data or instructions changed.

MSDATA includes DOSTAB: recompiled MSDATA, linked kernel, compared new kernel
with prior verified stage, repacked IO.SYS and compared to frozen target.
Unaffected MSDOS.SYS/COMMAND.COM inherited from the verified stage and also
compared exactly. All 293 current inputs match stage. Evidence file166-build.txt
and file166-make.txt; stage extras/build/t25-msdata-509-21922.

167 dos/dup.asm: accepted_exact. FC /B against effective v6.22 supplier
v6.2/dos/dup.asm reports no differences. No rebuild needed.

Prefix 167/293: modified 85, exact 25, necessary unchanged 21, no same-name
reference unchanged 36; separate tool change remains 1. Next 168 exechot.asm.
Full clean build and completion audit remain outstanding.
