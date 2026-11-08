# Current state

M3 T4 S1 is active: focused SoftPC validation of source-built COMMAND.COM.
M2 T3 is [closed](../history/M2-T3-completion-audit.md). The full goal remains active.

## M3 T4 S1 Packet

| Field | Required record |
| --- | --- |
| Identifier Mode | New |
| Admission And Approval | Active goal and explicit SoftPC authorization; O:\DOS configuration may be changed as needed. |
| Objective | Boot isolated media with reconstructed COMMAND and verify focused shell behavior under supplied SoftPC. |
| Non-goals | No claim of IO.SYS/MSDOS.SYS reconstruction or final package/deployment completion. |
| Reference Baseline | T1 image; T3 COMMAND 47845 bytes, SHA-256 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89. |
| Candidate Proposal | Roadmap M3 focused shell tests, then kernel recovery. |
| Files And ABI Surface | Test-image builder, guest batch fixtures, isolated SoftPC configuration and run evidence. |
| Applicable Rules | Execution, coding, architecture and documentation rules. |
| Verification | Direct identity before test; deterministic guest output, process lifecycle and immutable-input checks. |
| Owner Interaction Constraint | Permanent ban on Computer Use; runtime verification uses isolated desktops and probes only. Hidden windows are not isolation. |
| Expected Markers | Boot/VER, environment, FOR/IF/GOTO, file operations/redirection, nested shell and completion marker. |
| Asset Needs | Supplied SoftPC; original IO.SYS/MSDOS.SYS explicitly used as binary fixtures; disposable padded media. |
| Reporting Requirements | Distinguish reconstructed COMMAND from fixture kernel/BIOS; record padding, tested and untested behavior. |
| Stop Conditions | Unexpected original-source/media mutation, unowned process conflict; timeout is inconclusive. |
| Exit Criteria | Focused checks executed and verified under SoftPC with retained evidence; unresolved checks explicit. |
| Original Owner Request | 实现 MS-DOS 5.00 源代码考古恢复; use O:\DOS SoftPC for validation. |
| Similar-Issue Sweep | Initialization, PATH/SET, batch parsing, files and child shell paths affected by reconstruction. |

## Baseline and limits

Two clean COMMAND builds match all target bytes; current 113-file snapshot
revalidated in the T3 audit. [Evidence](../etc/evidence/m2-t3-command-identity.md).
Headless core guest tests pass. IO.SYS/MSDOS.SYS remain target binary fixtures.

Original image: 258048 bytes, BPB: 1474560. Padding an isolated test copy is
an explicit assumption, not recovered original media. Original image is immutable.

Inspected SoftPC reads adjacent softpc.ini and accepts no CLI arguments.
Preparation uses an isolated copy of supplied executable with new configuration;
final O:\DOS deployment is pending. Each VM run needs owned process, timeout,
logs and observed guest results.

First run completed as an inconclusive timeout: PID 32936 was terminated after
45 seconds with no DONE/RESULTS files. Original image and COMMAND hashes remain
unchanged. See [run evidence](../etc/evidence/m3-t4-softpc-preparation.md).
At that point no shell test had passed; this run remains inconclusive.

Owner correction supersedes that next action: Computer Use is permanently
forbidden. Next inspect available machine probes and isolated-desktop execution
support. Previous sky launch was interrupted with Escape and did not establish
boot state. The old hidden-window runner is disabled pending a verified isolated
execution path; do not retry it on the user's desktop.

Headless core probe now passes shell smoke: guest B8000 text includes all
markers and A> prompt; FAT has DONE.TXT and COPY.TXT, with INPUT.TXT deleted.
The revised fixture redirects each command separately; its latest core run
retains all expected markers in RESULTS.TXT, with exit 0 and unchanged original
image and guest system files (m3-t4-headless-runtime.json).
This uses neighboring SoftPC build objects, not the supplied product executable.
The isolated-desktop helper returned CreateDesktop error 5 (access denied)
before launching the product. Product-level verification remains pending;
do not fall back to the user's desktop. T4 stays active. See
[headless evidence](../etc/evidence/m3-t4-headless-probe.md).
