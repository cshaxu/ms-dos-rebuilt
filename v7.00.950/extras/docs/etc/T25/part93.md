# M6 T25 S1 P93, files 288–293

288 lang/usa/messages/biosmsg.inc, accepted_no_reference. The 950 BIOS
message include defines the resource header, five text offsets and text
used by bios/biosmsg.asm. The older BIOS catalogue uses a different layout.

289 lang/usa/messages/comimsg.inc, accepted_necessary. Compared against the
effective v6.22 overlay. The 950 initialization workspace and class 5
resource use 21 record-relative entries and the target startup/help text.
UINIT and INICLASS consume the respective branches.

290 lang/usa/messages/comrmsg.inc, accepted_necessary. Compared against
v6.2 effective source. The 950 resident workspace, class 6 directory of 93
entries, length-prefixed strings, pointer tables and index order follow
the target layout. RDATA includes the workspace and RESCLASS emits the
resource. Retained the target message strings and shared conditional file.

291 lang/usa/messages/sysimsg.inc, accepted_no_reference. The SYSINIT
resource offset table and text are assembled by bios/sysimes.asm.

292 lang/usa/messages/usa-ms-command.msg, accepted_necessary. The diff
contains target command strings, LFNFOR, LOCK/UNLOCK, DIR and prompt help,
catalogue record splits, and resource record 9900. Retained numbering,
data syntax and text used by the COMMAND message build.

293 lang/usa/messages/usa-ms-dos.msg, accepted_necessary. The effective
6.22 overlay comparison shows the target catalogue header, BIOS startup,
configuration and menu text, continuation counts and terminators. Kept
the target catalogue records. The MSDOS section appears unchanged in
that full diff.

The dispositions close the frozen file sequence. No source edits in P93.
Prefix 293/293. Modified 117, exact 90, necessary unchanged 47, no same-name
reference unchanged 39. Separate tool change 1. Production clean build
and completion audit are pending.
