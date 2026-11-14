# T21 file 74: cmd/command/makefile

Compared DOS6/OpenNT build structure and the actual maintained include inputs.
Restored the reference banner and the original tabbed, column-aligned dependency
list form for all 34 object targets. Restored OpenNT's multiline command.ctl
dependencies, including makefile itself. Kept the single native build path.

Fixed missing direct include prerequisites identified from the actual sources:
comseg for COMMAND1/2; arena for RUCODE; xmm for STUB; dossym/pdb/syscall/comequ
for RDATA; envdata/xmm for INIT; resmsg for UINIT/TENV; doscntry for DIR;
bpb for TMISC2; dossym for TPRINTF. Added version.inc for consumers of comsw.asm,
as already done in the DOS6 makefile. Full per-target additions are recorded
in T21-074-dependencies.log. The existing prerequisites were preserved.

The direct-include scanner was rerun on the edited makefile: no further missing
direct prerequisites or comsw/version edges were found, and the repeated output
is byte-identical. This is a direct-include check, not a claim to model every
conditional or transitive assembler dependency. An initial scratch-only repeat
check exposed a multiline command.ctl handling error in the helper; it was
fixed before that repeat check passed. The installed source was unaffected.

Remaining reference differences are intentional:

- Standalone inc/msg paths and usa-ms configuration replace OpenNT make.inc
  and DOS6's full multilingual product build environment.
- No NT binplace, NT include roots or cmdsvc dependency.
- No DOS6 DoubleSpace/cratio, ROM image, compression/distribution or debug
  variants; the project reconstructs this one native disk COMMAND.COM.
- Buildmsg uses the supplied original tool. Native LINK uses the unchanged,
  previously accepted command.lnk; its object/link order is unchanged.
- The existing COPY/RELOC/DEL recipe is the original tool sequence, explicit
  for this target, with no binary patch, target-byte injection or special case.
- MASM inference remains the existing tools.ini rule. Warning level and
  compiler/include arguments are unchanged. Object dependency block order is
  retained and does not change the response file's linker order.

Fresh full build cmd-24194-8951 passed with exit code 0; IO.SYS, MSDOS.SYS and
COMMAND.COM all match the frozen targets and were published to extras/assets.
All 34 COMMAND objects and linked COMMAND.COM match the earlier accepted full
build cmd-19587-14534 byte-for-byte (T21-074-object-compare.log). Build input
snapshots before and after compilation match. The makefile source matches
the fresh staged input. No subsequent source file changed before this gate.

Prefix 74/243: 6 modified and verified, 56 reference-identical, 12 necessary
differences retained. Next: 75 cmd/command/parse2.asm.
