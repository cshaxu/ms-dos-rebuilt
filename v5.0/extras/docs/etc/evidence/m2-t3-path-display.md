# M2 T3 S1 PATH display and environment scan limit

Sequential listing comparison found the first substantive transient instruction
change in tcmd2a's `print_path`, after seven modules' worth of comparison.
The NT implementation scans at most 128 bytes and derives a copy count from
DI-SI. Restored the target/DOS 6 path: call scasb2, test CX against 0xFF,
branch to path0 when appropriate, and compute the copy count as 0x100-CX.
This adds five bytes, restoring subsequent code positions. The call at file
0x41CC now exactly targets scasb2 at 0x46B2.

Following this dependency exposed tenv's NT scan limit 0x1000. Target bytes
at 0x46B2 are `32 C0 B9 00 01 F2 AE C3`; restored CX=0x100. DOS 6 confirms
this value. Both SCASB1 and SCASB2 use this shared SCASBX bound; the change
therefore covers both callers' shared implementation, not just PATH display.

The scanner now handles MASM `---- E` words as external address placeholders,
alongside hexadecimal E/R words. The initial dir findings were address words,
not source defects. No changes were made to dir based on those findings.

Final clean report `m2-t3-scan-limit-build.json`: 47,905 bytes, SHA-256
`f5dafeef14662ab5d42ce50ec04a3eea35c70b0364968aad0564cca881f185ae`.
The candidate remains unequal to the 47,845-byte target.

```powershell
python tools/build_command.py --report m2-t3-scan-limit-build.json
python tools/verify_transient_modules.py
```

The check covers nine sequential code contributions: tcode (from TCOMMAND),
tbatch, tbatch2, tfor, dir, tcmd1b, tcmd2a, tcmd2b, tenv. Their 9,331 bytes
from file 0x2324 through 0x4796 have no differences outside listing-annotated
address words. Remaining differing-byte counts are recorded per module;
this is not a claim that those operands or runtime behavior are correct.
The PATH call and eight-byte scan routine additionally match exactly.

Next comparison begins with tenv2 at file 0x4797. Remaining later transient
code/data and full binary identity are unresolved; no guest validation has
been performed. T3 S1 remains active.
