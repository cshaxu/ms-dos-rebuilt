# T25 sequential audit: file 106

106. cmd/command/dir.asm -- accepted_modified.
Read the complete 3586-line effective-reference diff. Restore matching
declarations/instructions/comments in attribute/order parsing, file counting,
short-name display and date decoding. Correct inherited comments which no
longer describe the parser contract or number of order fields. Replace twelve
numeric DOS service expressions with existing symbols. Remove orphan routine
headers for external pathname helpers and stale no-files/open comments.

Retain required 950 long-name search and short-name fallback adapters, shared
parser dispatch, access-date acquisition/sorting, variable entry/name storage,
disk geometry and allocation statistics, detailed/bare/wide output, UNC path
handling and paging state. Distinct DOS result formats require the two search
adapters; common name formatting, compression calculation and output helpers
remain shared. The buffer-active output path shares the character-output entry;
ASCIIZ and fixed-length appenders share their tail. Recursive listing retains
the inherited ListSubds framework. No additional implementation or file added.
Conditional DBLSPACE/DBCS branches, segment overrides and branch sizes retained.

Verification: file106-build.txt; extras/build/t25-dir-8093-25207.
Original COMMAND build passes; all regenerated messages and linked executables
unchanged. Fresh COMMAND.COM matches the 950 target. Inherited IO.SYS/MSDOS.SYS
also match their targets; all 293 current source inputs match the stage.

Prefix 106/293: modified 43, exact 18, necessary unchanged 11, no same-name
reference unchanged 34. Tool modification separately one. Next: 107 envdata.asm.
Full automatic final build remains pending.
