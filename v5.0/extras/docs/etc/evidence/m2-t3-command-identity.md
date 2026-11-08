# M2 T3 S1 COMMAND.COM whole-file identity

Later provenance correction: the `source_snapshot` fields in the two older
verification reports were collected from the live workspace *after* each
build. They show what was present at verification time; they do not establish
the historical bytes of shared includes used by the assembler. The staged
module copies and four staged inputs can be checked separately. Subsequent
comment-only edits mean the current source requires a fresh build; see
[COMMAND style adjustment](../command-style-adjustment.md).

COMMAND.COM now rebuilds from the local reconstructed sources to exactly the
47,845 target bytes. Direct byte comparison and SHA-256 both pass:

`74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89`

Two clean builds used different newly created stages, generated message
resources, assembled all 34 link-list objects, linked and converted with
RELOC. Neither build consumes the target image; target extraction happens
only in verification. Source snapshots accompanying the two verifications
are identical. No output patching, target-binary embedding or address-word
masking is involved in this result.

| Evidence | Result |
| --- | --- |
| m2-t3-command-identity-build.json | First successful complete identity build |
| m2-t3-command-exact-verification.json | Direct equality, zero differences, source hashes |
| m2-t3-command-repeat-build.json | Independent clean stage, same output |
| m2-t3-command-repeat-verification.json | Second direct equality and same source snapshot |

Earlier report names are historical, not success assertions. In particular,
`m2-t3-command-exact-build.json` still had one different byte and correctly
records target_match=false. The verifier fails on any unequal byte or length.

Final recovery work:

- Enabled the suppressed parser listing; the resulting binary hash stayed
  unchanged. All 24 transient code modules then passed the bounded listing
  comparison. The full-file check now supersedes address-masked checks as
  the final identity evidence for this source snapshot.
- Removed `.500` from the VER message source. Updated 13 subsequent indexed
  message-section offsets by four bytes, checking that each still points to
  the same catalog content. Rebuilt all message classes from source.
- Removed the unreferenced 37-byte NT_INTRNL_CMND table and stale extern.
  Target transitions directly to TEMP= at that position; preserved TEMP=
  because the pipe implementation references it.
- Removed JUNK1 and FOO_JUNK. Despite their source syntax `DB 2(?)`, the MASM
  listing proves each emits one byte. Neither has a consumer; target data
  addresses and DOS 6 lack both entries.
- The last mismatch was COM offset 0xA520: maximum width for the VER major
  number in tranmsg.asm. Restored width 1 rather than 2. This is meaningful
  message metadata, not a binary patch.

Reproduce from project root:

```powershell
python tools/build_command.py --report m2-t3-command-identity-build.json
python tools/verify_command_exact.py
python tools/build_command.py --report m2-t3-command-repeat-build.json
python tools/verify_command_exact.py --report m2-t3-command-repeat-build.json --output m2-t3-command-repeat-verification.json
```

Dependencies remain the historical MASM, BUILDMSG, DOS LINK/RELOC and DOSBox
paths recorded by the build script and reports. This is reconstructed source,
not a claim to have recovered Microsoft's original DOS 5 source text.
Rights/provenance work before distribution remains in TODO.

Scope: COMMAND.COM identity is achieved. IO.SYS and MSDOS.SYS reconstruction,
SoftPC shell/boot tests, final three-component packaging and O:\DOS deployment
remain unfinished. Overall goal is active. T3 technical evidence is ready for
its separate closure audit; M3 still requires focused shell tests.
