# M6 T25 S1 P36: file 127

127. tcmd2b.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Restore SETUP_PARSE_ERROR_MSG verbatim with its original contract, ASSUME,
constants, local label and comments; the literal 2 is existing LessArgs_Ptr.
Restore TAB instruction layout throughout the changed command routines and
replace eight DOS service literals with existing service symbols/expressions.
Keep the emitted instruction sequence and target layout unchanged.

CTTY retains shared argument parsing, trailing-colon handling and extended
read/write open with its sharing/action flags. CHCP preserves result-value
handling, 100..999 validation and common parser-error reporting. TRUENAME
retains parsed argument metadata and dynamic output buffer. Do not reinstate
the removed parse_with_msg/parse_check_eol wrappers alongside the shared parser.

EXIT's Int 2Eh return, saved vector restoration, return-code filtering and
conditional resident retention are required target behavior. Its two cleanup
tails terminate differently (normal exit versus stay resident), so replacing
them with a new shared tail would alter target control flow/bytes. LOCK and
UNLOCK share LockOperation, including confirmation, drive iteration and IOCTL
fallback. Preserve its target padding and two API attempts; no second command
implementation has been introduced.

Verification: file127-build.txt; extras/build/t25-tcmd2b-16998-8751.
Original COMMAND build passes. Messages and linked executables remain exact.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Prefix 127/293: modified 57, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: file 128.
Final full automatic build remains pending. P36 is delivered separately.
