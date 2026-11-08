# M2 T3 S1 transient executable-path recovery

Removed the NT pre-supplied executable-name/type branch in tmisc1 (15 bytes)
and its unused label. Target 0x4BF5 proceeds directly to EXECPATH initialization,
ROM check and path_search; target call resolves to 0x54F1. The 29-byte decision
prefix matches after explicit address-word exclusions, and candidate operands
are checked against MAP symbols. DOS 6 corroborates the direct search path.

Restored EXECPATH storage to COMBUFLEN+3 (131 bytes) and path1's pbuflen to
128. Target path_search contains `BB 80 00`; target executable-path operand
is 0x8C9F and RESSEG is 0x8D77, a 216-byte spacing accounted for by 131-byte
EXECPATH, 83-byte RE_INSTR and the two-byte resident-call offset. Removed the
intervening 37-byte NT cmdinfo structure (18 fields), their PUBLIC/EXTRN
declarations, and the now-unused EXECPATHLEN constant. Token scan of executable
source found no remaining consumers of these fields. All external original
source trees remain unchanged.

The initial edit script stopped at its field-count assertion because its
pattern omitted DD. At that point only tmisc1 had changed; its successful
intermediate build is retained as m2-t3-execpath-build.json. Corrected the
field enumeration and performed a separate final clean build, avoiding any
claim that the partial run represented the full changes.

Final report: `m2-t3-execpath-layout-build.json`; 47,868 bytes, SHA-256
`afa31d1e2eded3ba6bc9576b71b42d5ef04cf2945dd26a842681a79646a38583`.
This is 23 bytes larger than the target, but length proximity is not a
coverage measure: candidate search-entry position is 0x4BD0 versus target
0x4BF5, and addresses elsewhere still differ. No guest execution verified.

```powershell
python tools/build_command.py --report m2-t3-execpath-layout-build.json
python tools/verify_execpath.py
python tools/verify_command_entry.py docs/etc/evidence/m2-t3-execpath-layout-build.json --length 0x2f7 --output m2-t3-execpath-entry-verification.json
```

Both checks pass. Verification covers path prefix, symbol-resolved call/data
operands, target-corroborated capacity and field spacing; it does not claim
whole tmisc1/path1 identity. Next work: initialization messages/data and
remaining transient instruction differences, followed by exact final layout
and runtime validation. T3 S1 remains active.
