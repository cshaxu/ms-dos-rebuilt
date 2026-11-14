# T21 file 9: bios/msbio.skl

Twelve definitions restored directly from DOS6 bios/msbio.skl: 03, 04, 22,
05, 06, 07, 08, 10, 11, 13, 14, 15. Only directive spelling and whitespace
outside quoted strings changed. The comparison preserves literal case and
embedded whitespace; it does not lowercase message text. No macro, helper,
conditional path or new message was added.

## Remaining differences and reference selection

- DOS6's messages 29-42 describe its startup, bypass/confirmation and menu
  features. Its message 43 is the DoubleSpace version error. Do not restore
  these later feature resources merely to match the reference file.
- Message 12 retains DOS5's lowercase `block devices` spelling.
- Message 24 retains DOS5's `Logical drives` wording and CR/LF/$ terminator.
  These affect output bytes; keep them as explicit message definitions in
  the reference's existing class/definition structure.
- OpenNT lacks physical bootstrap/single-drive and selected OEM/POWER classes;
  DOS6 corroborates their existing organization. OpenNT also uses a different
  HMA warning string; the current form agrees with DOS6. Do not restore NT
  deletions or change target strings just to match OpenNT.
- Optional POWER message provenance remains the existing documented TODO;
  definition 26 and its optional behavior were not changed in this file edit.

## Verification

Clean production build: cmd-18179-2258, through extras/build.cmd.
Accepted: input snapshots matched, all three full targets passed and the
entry returned zero and published. Direct BIOS object/result comparisons are retained in
T21-009-object-compare.log. Generated message-source whitespace may differ;
emitted object bytes and linked target bytes must not.

Original file hash stays in the frozen ledger. New input hashes are in the
build's input snapshots. No source after file 9 has been edited.

Following file 10, bios/msbio1.asm, passed direct FC /B against DOS6's same
file and is accepted unchanged. A lexical NT/BOP scan only matched the text
"conventional keyboard" through the substring "ntio"; this is not a host
dependency. Prefix 10/243: two verified modifications, six exact-reference
files, two necessary differences retained. Next 11: bios/msbio2.asm.
