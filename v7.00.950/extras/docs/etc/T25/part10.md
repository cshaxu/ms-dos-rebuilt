# T25 S1: files 83 through 84

83. bios/rqvalue.asm: no same-name effective reference; no edit. Reviewed
    all five entries. Query/set and default/named-value wrappers have distinct
    arguments; they already share RegQueryValueCore and RegSetValueCore.
    Windows-provider calls use reversed argument order and callee cleanup;
    local calls use the C frame. Preserve both actual runtime providers and
    the check-policy exchange. Do not combine unlike argument marshalling.
84. bios/si1tail.asm: no same-name reference; reviewed against the inherited
    sysinit1.asm in the frozen effective-v6.22 reference. Preserve the existing
    split and segment organization. Reviewed temporary CDS creation/lookup,
    COPYCDS support, EndFile allocation, INSTALL execution/checksum relocation,
    sector-buffer placement, buffer queue, hardware stack initialization,
    vector installation and conditional TAIWAN routines. Retain original
    comments/conditional forms and necessary 950 changes: relocated BDS links,
    recorded device table, high-memory allocation, runtime message resources,
    expanded checksum extent and Windows stack-instance fields.
    Replace two numeric INT 2Fh function constants with already declared
    symbols: 4A03h -> (multMULT shl 8)+multMULTALLOCHMA7 and
    4A01h -> (multMULT shl 8)+multMULTGETHMAPTR. GetBufferAddr7 already uses
    the former symbolic form. No additional implementation or build exception.

Evidence: file84-build.txt. Original NMAKE rebuilt BIOS and loader; MSLOAD.EXE
and MSBIO.BIN are byte-identical to the preceding verified stage. Freshly
packed IO.SYS matches the frozen 950 target. The two inherited unaffected
images also compare exact, and all 293 source inputs match the stage.

Counts through 84: modified 28, exact 17, necessary unchanged 5,
no-reference unchanged 34. One tooling change is counted separately.
Stage: extras/build/t25-si1tail-31851-25394.
Next: 85 bios/si2front.asm. T25 remains active; final full automatic build
and completion audit remain outstanding.
