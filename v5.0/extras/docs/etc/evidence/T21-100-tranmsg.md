# T21 file 100: cmd/command/tranmsg.asm

Complete OpenNT/DOS6 diffs reviewed. Restored AN000 maximum-width comment to
the exact original text. The one-byte major-version width stays 1, as in DOS6
and the DOS5 target, not OpenNT's width 2. All other content matches OpenNT.
The missing DOS6 tail is later LOADHIGH custom-parser and DoubleSpace ratio
messages, absent from the selected implementations and target. Existing
NO_SUBST spacing and EOF marker are original OpenNT style, retained.

Only the comment changed. No new data declarations, conditional branches or
message code. Whole-word NT/BOP screening previously returned no hits; restored
comment adds none. Verification appended after affected compilation succeeds.

Affected build t21-command-26774-13280 passed, parent t21-command-26461-30009.
All 34 objects and COMMAND.COM unchanged; all three frozen targets match
(IO/DOS inherited). Fresh audit-inputs, audit-object-compare, audit-*-compare,
COMMAND/AUDIT.LOG and result.txt provide evidence. Prefix 100/243:
11 modified entries (one metadata), 74 exact, 15 necessary differences.
Next: 101 tspc.asm.
