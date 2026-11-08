# M2 T3 S1 DOS 5 initialization messages

Restored CopyrightMsg in `messages/comimsg.inc` from the OpenNT banner to
the exact target DOS 5 text, including two leading CR/LF pairs, `(R)` markers,
Version 5.00, thirteen leading spaces on the copyright line, and 1981–1991.
The source `msg` macro produces the 94-byte length-prefixed message; no output
binary patch or padding was used. This include is assembled directly; the
BUILDMSG indexed usa-ms catalog was not modified.

Message payload increased by 25 bytes. With paragraph alignment, the clean
binary increased by 32 bytes and transient code now begins at the target
address. TCOMMAND is COM offset 0x2324. A longer candidate here is a correction
to its content, not a regression inferred from total size.

Clean report `m2-t3-message-build.json`: 47,900 bytes, SHA-256
`ecf74be88326d1f1687679d3d3c5aa118fa4f50dbd519a8dfe5597bf62e72916`.
The target is 47,845 bytes and still differs. Verification establishes:

- All 839 message bytes from 0x1E9B through 0x21E1 match exactly.
- All but 18 bytes in the first 8,736 bytes match directly, without masking
  the initial comparison. Remaining differences are enumerated within 14
  later-layout operand words, with both candidate and target values retained.
- Bounded environment and 759-byte command-entry opcode checks still pass;
  command-entry call-site offsets now equal their target offsets as well.

```powershell
python tools/build_command.py --report m2-t3-message-build.json
python tools/verify_init_messages.py
python tools/verify_init_environment.py --report m2-t3-message-build.json --output m2-t3-message-environment-verification.json
python tools/verify_command_entry.py docs/etc/evidence/m2-t3-message-build.json --length 0x2f7 --output m2-t3-message-entry-verification.json
```

This corrects the whole initialization-message region, but does not establish
transient message equivalence. The pre-transient prefix still depends on
unresolved transient size and symbol addresses. Remaining transient internal
code/data differences and guest execution require further work; T3 S1 and
the overall IO.SYS/MSDOS.SYS/COMMAND.COM objective remain open.
