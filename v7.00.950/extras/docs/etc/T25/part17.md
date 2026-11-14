# T25 sequential audit: file 101

101. cmd/command/copy.asm -- accepted_modified.
Reviewed the complete reference diff. Restore 27 inherited initialization
comments verbatim on their unchanged instructions, original VerVal/EnvirSeg
external declaration grouping, and five existing EXTOPEN/CHDIR/CURRENT_DIR/
CHMOD expressions instead of numeric DOS service constants.

Preserve the 30-byte bulk state clear: TSPC SrcHand through OCtrlZ accounts
for those exact bytes. Keep 950 parsed-argument pointers, switch assignments,
long filename selection, path enumeration and canonicalization through shared
interfaces. Source and destination select independently because they can use
different file systems. Preserve the ASCII state around flush calls, required
branch reach, destination actions, localized overwrite response and 13-byte
message substitution ABI. No parallel COPY implementation introduced; file
and path calls are selected for the existing core flow.

Verification: file101-build.txt; extras/build/t25-copy-5742-19602.
Original COMMAND build passed; generated messages and linked command/message
executables compare unchanged. Repacked COMMAND.COM is exact to the own 950
target. Unaffected IO.SYS/MSDOS.SYS inherited and exact. All 293 current inputs
match the stage. Full automatic final build remains pending.

Prefix 101/293: modified 39, exact 18, necessary unchanged 10, no same-name
reference unchanged 34. Tooling modification separately one. Next: 102 copypr1.asm.
