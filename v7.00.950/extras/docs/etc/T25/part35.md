# M6 T25 S1 P35: file 126

126. tcmd2a.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Remove unused PrepareEnvironmentChange external. Restore TAB-based layout in
the changed VER, prompt and PATH routines; restore the reference-exact
scan_white/disppath blocks, including their comments, and original register
case in build_dir_string. Keep existing module boundaries and procedure order.

Retain VER's shared parser, simplified character output, prompt reentry flag,
selected get-directory function and LFN conversion. PATH/SET share PathFromSet;
the Y-switch merge, case-folded comparison, quote-aware component splitting,
DBCS handling and conditional canonicalization are necessary 950 behavior.
PathAddComponent and PathIsDelimiter are shared within that flow, and final
storage uses SetEnvironmentValue rather than duplicating environment mutation.
The unused preparation declaration is removed, not the implementation in TENV.
Preserve dynamic PATH display scratch space and resource-name length handling.
No runtime instruction sequence or data layout changed.

Verification: file126-build.txt; extras/build/t25-tcmd2a-16459-4736.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS
also match, and all 293 source inputs match the verified stage.

Prefix 126/293: modified 56, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 127 tcmd2b.asm.
Final full automatic build remains pending. P35 is delivered separately.
