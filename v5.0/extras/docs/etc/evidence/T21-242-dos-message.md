# T21 file 242: messages/usa-ms-dos.msg

This named variant has no exact same-name reference. Compared in full with
the original OpenNT usa-ms.msg and the maintained USA-MS input. Restored
COMMAND record 1040 to the exact DOS4 wording 'MS-DOS Version %1.%2', removing
the residual '.500' suffix also removed from the shell input. It was unused
by the BIOS/kernel skeletons, but retaining it in the source was unnecessary.

The rest is the original native message-catalog structure with two system
resource additions: MSBIO 0026 for the existing POWER class and the BOOT
section. The BOOT message and continuation match DOS4 USA-MS.MSG:548-549
exactly. POWER's banner is corroborated by DOS6 bios/power.asm:3692 (commented
literal); its optional-message limitation was already recorded at file 9.
No claim is made that a same-named pristine Microsoft source was found.
Catalog revision/count/index fields account for the system variant. BUILDIDX
regenerates offsets on staged copies; source offsets are not binary patches.
The native build copies this variant to DOS.MSG for BIOS/kernel skeletons,
while COMMAND uses USA-MS.MSG. Keep the existing named resource-input boundary;
no new selection script, second code path or duplicate executable is added.

Full original-tool build cmd-32179-8869 completed with exit 0. Both message
indexes were regenerated; BIOS, DOS and COMMAND were compiled from clean
staged inputs. All 104 raw objects match prior accepted object baselines;
IO.SYS/MSDOS.SYS/COMMAND.COM match frozen targets byte-for-byte and were
published to extras/assets. Production before/after source snapshots match.
All 243 ledger inputs match the stage, with the documented original BUILDIDX
rewrite of staged usa-ms.msg and audit-only relocated metadata copy handled
explicitly. See T21-final-object-compare.log and T21-final-stagecheck.log.

Prefix 242/243: 20 modified (19 source/build files plus one metadata relocation),
193 reference-identical, 29 necessary differences. Next: 243 messages/usa-ms.msg.
