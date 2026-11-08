# M2 T3 S1 resident path buffer and prefix layout

Changed only the MsgBuffer/SafePathBuffer storage in `rdata.asm` from the
NT-expanded 273 bytes to 80 (`64+3+13`). Target evidence is stronger than
the stale OpenNT comment suggesting 128 bytes: target SP initialization
at 0xE81 is `BC 3E 05`, target OldDS store at 0x1086 is `8F 06 3E 05`,
and the ARIFYN message sequence starts at file 0x441. All three agree
with the 80-byte capacity, as does DOS 6's explicit definition. The restored
MAP has RStack=OldDS=0x53E, MsgBuffer=0x469 and Int2fHandler=0x4B9.
Its LenMsgOrPathBuf constant also controls the pathname copy in tmisc1.

Clean build `m2-t3-resident-buffer-build.json`: 48,110 bytes, SHA-256
`25e647c595bb95630466a94b45d02305dfda66c905da541af05bbb83ed899ef3`.
DATARES is now 0xD40 bytes; CODERES starts at linear 0xD40 and ConProc
at 0x1560 (COM offset 0x1460), matching the target layout. Alignment means
the 193-byte storage reduction shrinks the full file by 208 bytes.

Direct comparison of file offsets 0 through 0x145F finds 5,195 equal bytes
and 21 differing bytes. All differences lie within 15 explicitly identified
word operands referring to initialization/transient data, destinations or
lengths. `m2-t3-resident-prefix-verification.json` records every differing
offset and both operand values. These operands remain unresolved; no claim
of exact resident-module identity or runtime behavior is made.

Reproduce with:

```powershell
python tools/build_command.py --report m2-t3-resident-buffer-build.json
python tools/verify_resident_prefix.py
python tools/verify_init_environment.py --report m2-t3-resident-buffer-build.json --output m2-t3-buffer-environment-verification.json
python tools/verify_command_entry.py docs/etc/evidence/m2-t3-resident-buffer-build.json --length 0x2f7 --output m2-t3-buffer-entry-verification.json
```

Both earlier bounded instruction-layout checks pass. Similar-issue search
found that transient EXECPATH and path1's buffer bound still use the NT
expanded capacity, and tmisc1 still has host-provided executable-name logic.
Those require their own target correspondence before changing the shared
constant. Initialization DoDate is still 13 bytes after its target position;
transient code starts 16 bytes after its target. These are next layout leads,
not grounds for inserting/removing arbitrary padding. T3 S1 remains active.
