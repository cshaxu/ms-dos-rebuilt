# T25 sequential audit: file 114

114. cmd/command/makefile -- accepted_modified.
Read complete current makefile and effective-reference rules. Restore the
original module heading, dependency-section marker, inc/MSG_DIR path macros,
object-rule ordering and matching dependency-line formatting. Keep the actual
950 dependency set and place additional dependencies after inherited entries.
The effective-reference text diff is reduced to 112 insertions/187 deletions.

Independent dependency comparison after macro expansion confirms all 540
object dependency edges are unchanged across 37 object rules. Link OBJS order,
all target, compiler options, message generation prerequisites, original
MASM/CL/LINK recipes and resource executable targets remain unchanged.
IPARSE's original parse.asm include is commented out; its small current
dependency set is intentional. TDATA/TPRINTF receive command.ctl through the
shared OBJS rule. ROM image/media compression targets absent from the current
950 build are not fabricated as alternate production paths. No special-case
binary patching or additional scripting introduced.

Verification: file114-dependencies.txt and file114-build.txt.
Original COMMAND build passes using the modified makefile. Generated messages
and linked executables are unchanged; fresh COMMAND.COM matches its own target.
Inherited IO.SYS/MSDOS.SYS also match. All 293 current sources match stage
extras/build/t25-command-make-10562-24538.

Prefix 114/293: modified 47, exact 20, necessary unchanged 12, no same-name
reference unchanged 35. Separate tool modification one. Next: 115 parse2.asm.
Full automatic final build remains pending.
