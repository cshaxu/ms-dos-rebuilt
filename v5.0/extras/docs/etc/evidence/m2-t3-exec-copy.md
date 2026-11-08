# M2 T3 S1 EXEC pathname copy and PATH construction

Restored tmisc1's fixed-length pathname copy to resident storage. Target
0x4C31 includes `BF 69 04 B9 50 00 FC F3 A4 BF 5C 00`: destination
SafePathBuffer, count 80, CLD, REP MOVSB, then the FCB copy setup. OpenNT
instead used a bytewise loop, NUL test and forced truncation. DOS 6
corroborates the target REP MOVSB path. Removing the loop reduces code by
11 bytes; removed loop labels have no remaining local-source consumers.

Removed path1's six-byte UNC bypass (`cmp [si],5C5Ch; je CopyPath`). The
target at 0x5547 directly begins drive-letter processing, matching DOS 6.
The source still performs ordinary pathname construction; no blanket UNC
feature claims are made from this one branch or from text searches.

Final clean report `m2-t3-path-unc-build.json`: 47,888 bytes, SHA-256
`e47fe94b809ab2414aeedf3e7be1f2e2701563ac705b0e07744ae99974764a64`.
An intermediate EXEC-copy-only build is retained separately. Final binary
is still unequal to the 47,845-byte target, and no guest test was performed.

```powershell
python tools/build_command.py --report m2-t3-path-unc-build.json
python tools/verify_transient_modules.py
```

The sequential comparison now covers 21 code contributions through cparse,
17,379 bytes starting at 0x2324 and ending before 0x6707. No differences
remain outside MASM-annotated address words in this bounded universe.
The exact EXEC copy sequence, drive-processing prefix, prior PATH scanner
call and eight-byte scan helper are additionally asserted without masking.
Remaining address operands are still recorded as differences per module;
this is not complete binary or behavior equivalence.

Next comparison is tparse at 0x6707. Its include/listing representation must
be checked before classifying apparent differences: an unannotated operand
from a suppressed include is not automatically a code defect. tparse and
later modules are outside the current passing comparison universe. T3 S1
and the full DOS reconstruction remain active.
