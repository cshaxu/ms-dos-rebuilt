# T25 sequential audit: files 107-110

107. envdata.asm -- accepted_necessary. Complete diff is the default PATH:
c:\windows\command instead of c:\msdos. Required 950 environment value;
Environment structure and symbolic size consumers in INIT retained. No edit.

108. fordata.asm -- accepted_modified. Restore original file-description line;
retain the useful explanation of fixed header and dynamic argument strings.
The argv header has five words: arg_unit's two words plus three following
words in TSPC, copied by TFOR using FOR_COM_START. Therefore restoring SIZE
arg_unit alone would truncate the saved header. Path/search buffers and search
handle support the actual PathFindFirst/Next calls; dynamic strings follow
SIZE for_info. Preserve all offsets and existing structure, no new mechanism.
Fresh original COMMAND build and repack pass, linked outputs/messages unchanged;
fresh COMMAND.COM equals own target, inherited IO.SYS/MSDOS.SYS also equal.
All 293 inputs match extras/build/t25-fordata-8589-20565; file108-build.txt.

109. ifequ.asm -- accepted_exact. Direct FC/B against effective reference passes.

110. iniclass.asm -- accepted_no_reference. Complete nine-line resource wrapper
includes resmsg.equ and language comimsg.inc in DATARES, with no implementation
duplication. Makefile independently assembles/links it; production CMDIMAGE
consumes its executable/map as the initialization resource. Merging into the
code object would lose the separate resource boundary. Keep unchanged.

Prefix 110/293: modified 44, exact 19, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 111 init.asm.
Unchanged files were not rebuilt separately. Final full build remains pending.
