# T25 sequential audit: files 102-103

102. cmd/command/copypr1.asm -- accepted_necessary, unchanged.
Complete diff is limited to destination open-function/action state and shared
DestDelete. COPY sets the selected destination API; the post-open action feeds
COPY's close handling. Error cleanup calls the same destination deletion helper
instead of repeating short/long-name selection. Existing concatenation, sharing,
device handling and original-file recovery paragraphs remain inherited.
No edit or redundant build.

103. cmd/command/copypr2.asm -- accepted_modified.
Reviewed the complete reference diff. Restored 76 matching reference lines of
case, spacing and comments, plus two original continuation comments, in the
destination classification, copy-mode, EOF trimming and path-checking code.
Reviewed the generated diff to exclude a historical annotation that happened
to match PUSH SI in the new extension splitter; new routines do not acquire
unrelated revision history. Instructions and operands remain equivalent.

Retain variable-length destination pattern construction instead of fixed FCB
8.3 substitution, shared BuildName for base/extension and shared extension
splitter for source/pattern. Retain independent source/destination open choices,
attribute-based path inspection, common canonicalization API, required ASCII
state update, wildcard representation and existing DBCS path scanning.
These replace or extend existing flows rather than adding a second COPY engine.

Verification: file103-build.txt; extras/build/t25-copypr2-6199-17051.
Original command build passes; generated messages and linked command/message
executables compare unchanged. Fresh COMMAND.COM matches own frozen 950 target;
IO.SYS/MSDOS.SYS inherited and exact. All 293 current inputs match the stage.
Final full automatic build remains pending.

Prefix 103/293: modified 40, exact 18, necessary unchanged 11, no same-name
reference unchanged 34. Tool modification separately one. Next: 104 cparse.asm.
