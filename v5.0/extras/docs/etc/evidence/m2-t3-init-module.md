# M2 T3 S1 complete initialization code layout

Compared the current INIT listing with the target starting at COM offset
0x1460. The first non-address mismatch was at 0x1979: the candidate still
printed the banner before batch initialization. This is the NT relocation
of the banner, absent from the target. Earlier work restored its original
later location but left this early copy. Removed the 13-byte early copy;
this corrects the earlier intermediate banner reconstruction, rather than
adding padding to force addresses.

The next mismatch was in CheckHelp: an eight-byte `/Z` test and branch.
Removed that test, its extern, and the corresponding uinit parser descriptor
(switch count 8 to 7, pointer, 12-byte definition and public). The target's
25-byte parser header at 0x1DD6 now matches exactly, including pointers.

Removed unreferenced IRename, IAccess and IDelete wrappers at the end of INIT
(18 bytes). Whole local `.asm` token search found only their definitions;
the target transitions from get_XMMAddr return to zero alignment bytes and
then `/DEV/CON`, without those wrappers. No target instructions were replaced
with opaque binary data. DOS 6 also lacks these wrappers; its eighth parser
switch is a different feature and was not imported.

Clean build `m2-t3-init-z-build.json`: 48,062 bytes, SHA-256
`9c5b530077303d8ee82c341adff6938b3450b658b5e1372105139822405ff058`.
`verify_init_module.py` covers the complete 2,277-byte init.asm contribution
from file 0x1460 through 0x1D44. Exactly 41 bytes differ; all are within
MASM-annotated address words. There are no unmasked instruction-layout
differences. `/DEV/CON` now starts at target 0x1D50. This proves bounded code
layout, not final operand correctness or guest execution.

```powershell
python tools/build_command.py --report m2-t3-init-z-build.json
python tools/verify_init_module.py
python tools/verify_init_environment.py --report m2-t3-init-z-build.json --output m2-t3-init-z-environment-verification.json
python tools/verify_command_entry.py docs/etc/evidence/m2-t3-init-z-build.json --length 0x2f7 --output m2-t3-init-z-entry-verification.json
```

The first 5,216 file bytes now contain 14 differing bytes (previously 21),
but the complete candidate still differs from the 47,845-byte target.
Remaining transient executable-path state, capacity and code differences,
initialization message/data differences, and final address layout require
continued recovery. T3 S1 remains active; no VM validation or overall closure.
