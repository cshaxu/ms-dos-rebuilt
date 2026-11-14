# T25 sequential audit: file 104

104. cmd/command/cparse.asm -- accepted_modified.
Reviewed complete diff and actual switch table/callers. Restore reference STC,
CLC and token-pointer return annotations/formatting. Retain the original
interface-comment structure but correct obsolete claims: the token includes
the switch character, star expansion is conditional, quoted input and wildcard
suffix have state flags, UNC paths are exempt from drive insertion, NUL and
malformed switches can return carry. No instruction changed.

The 950 quote-aware and ASCIIZ parser, UNC handling, counted full-token switch
matcher and wildcard suffix state are necessary differences. The eleven-entry
TDATA switch table agrees with the matcher count. QuoteDelim is shared by the
parser, TBATCH and TMISC1, rather than duplicated per caller. CParseSwitch and
CParseMatchSwitch form one token collection/classification flow. Preserve
required NOP, branch reach and alternative exit bytes; no speculative removal
of target instructions. Existing inherited historical comment blocks remain.

Verification: file104-build.txt; extras/build/t25-cparse-6685-12932.
Original command build passes; generated messages and linked executables are
unchanged. Fresh COMMAND.COM matches own frozen 950 target. IO.SYS/MSDOS.SYS
inherited and exact. All 293 current inputs match stage. Final full automatic
build remains pending.

Prefix 104/293: modified 41, exact 18, necessary unchanged 11, no same-name
reference unchanged 34. Next: 105 cratio.asm, effective v6.22 local overlay.
