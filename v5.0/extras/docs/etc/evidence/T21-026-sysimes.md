# T21 file 26: bios/sysimes.asm

Restored the `toomanydrivesmsg` PUBLIC line exactly from OpenNT's corresponding
module, retaining its M029 comment. After this one-line change, the only
OpenNT difference is deletion of the NT DOSEm port-history block. Keep that
deletion; it would misidentify this standalone source. No copyright attribution
was invented. DOS6's additional exports belong to multi-config and DoubleSpace
messages absent from the target; adding them would leave undefined externals
or require later-version resources. DOS4's older segment/SYSSIZE/SHAREWARNMSG
organization is not applicable to this selected source set.

## Affected-scope verification

Parent clean build: cmd-19587-14534. Successful isolated copied stage:
`extras/build/t21-bios-21125-30761`.

Rebuilt all BIOS generated objects/resources from the original NMAKE rules and
linked IO.SYS. All 15 BIOS objects, msload.com, msbio.bin and IO.SYS are byte
identical to accepted cmd-6108-11594. IO.SYS also directly matches the frozen
target. Unaffected MSDOS.SYS and COMMAND.COM were inherited from the verified
parent, not recompiled; both were compared again with their frozen targets.
No asset publication is necessary because every output remains identical.

Before/after checks cover all 243 current source inputs. 242 match the staged
files byte for byte. The original BUILDIDX rewrites the staged usa-ms.msg
header/index information; its maintained source is instead verified against
its frozen queue hash. This documented generated-input exception does not
permit a source change. See audit-inputs-before.log/audit-inputs-after.log.

Evidence in the stage: audit-parent.txt, build.bat, bios/AUDIT.LOG, host.log,
audit-object-compare.log, audit-*-compare.log, and result.txt. The result says
affected BIOS rebuild, not full three-component rebuild. Parent input snapshot
files copied into this stage are inherited evidence, not fresh snapshots.

Two earlier isolated attempts are retained: t21-bios-20691-10247 stopped on the
BUILDIDX staged-file distinction before launching the compiler; t21-bios-20929-8449
failed when NMAKE /A invoked an unwanted implicit rule against existing output.
The accepted run clears only generated BIOS files in its newly created copy
and runs ordinary nmake io.sys. No production build script was changed.

Prefix 26/243: 4 modified and verified, 18 exact-reference, 4 necessary
differences retained. Next 27: bios/sysinit1.asm.
