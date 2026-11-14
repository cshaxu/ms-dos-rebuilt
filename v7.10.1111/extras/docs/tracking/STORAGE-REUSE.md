# Original-line retention in the unapplied storage draft

Compared the thirteen proposed replacement bodies with their current original
procedures. Removed comments/whitespace and folded case ONLY for matching;
operands, registers, symbols and numeric spellings were not abstracted away.
An ordered common-subsequence match retained 99 existing instruction lines
in the draft without changing its normalized instruction text. This is a
format-preservation step, not an assembly/binary equivalence claim.

The small exact-text overlap does NOT prove little semantic reuse is possible.
In particular RegSaveFile maps to RegSaveFileState PLUS its factored key/data
writers, copy helper and commit helpers. Comparing only the entry body would
misclassify factored original logic as replaced. Stack offsets, register choices,
numeric spelling and ABI changes also defeat this deliberately strict matcher.
Do not report the overlap as a reuse percentage or restoration percentage.

The revised diff is still unapplied and cannot build on its own: shared cache
ownership, target helper factoring, caller conventions and segment placement
remain to be integrated. Continue manually reconciling whole responsibilities
before activating the new ABI. Original production remains the only linked
path; there are no newly restored or exact functions from this draft work.

Production source changes: 0. New identical-file certifications: 0. Confirmed
whole IO functions: 461. IO.SYS: 233548 bytes. No assets published.
