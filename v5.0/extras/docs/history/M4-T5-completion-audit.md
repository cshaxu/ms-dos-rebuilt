# M4 T5 completion audit

T5 covered the standalone kernel baseline and DOS 5 reconstruction. S1 established the OpenNT reference baseline; S2 completed the owner-directed ordered review and target build correspondence. This closes T5; project and other milestones remain open.

| Requirement | Evidence and disposition |
| --- | --- |
| Reference baseline and strategy | [S1 audit](M4-T5-S1-baseline-audit.md) records pinned references, 38-unit baseline and candidate anchor strategy. |
| Source correspondence and host screening | [S2 audit](M4-T5-S2-ordered-review-audit.md) records the 215-entry ordered universe and NT/BOP lexical screen; textual matches do not prove original source provenance. |
| Get-DPB and FAT dependencies | [Static call-chain audit](../etc/evidence/m6-getdpb-callchain-expanded-9y047lqr-v2.json) checks 16 calls and four conditional branches against target bytes; this is not a complete behavioral proof. |
| Kernel module and layout | The current `dos/msdos.lnk` lists 55 units, in the same order as the latest build report; all 55 staged object hashes were rechecked. Integrated build verifies the linked segment sizes and 6Ah SYSINITVAR invariant. |
| Target binary | `build/integrated-source-o1gc1cvu/MSDOS.SYS` equals the staged kernel and retained `O:/DOS/MSDOS.SYS` byte for byte: 37,394 bytes, SHA-256 `4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2`. |
| Build inputs | [Input audit](../etc/evidence/resource-review-004-build-inputs.json) verifies 364 recorded input entries and all three retained targets. |

Owner accepts the retained targets and does not require SoftPC validation or remounting original media. Exact binary identity is not proof of source authorship, exhaustive optional configurations, full tool/OS dependency closure, or absence of all indirect host dependencies; these limits remain in [TODO](../states/TODO.md). No source edits or deployment were performed by this task audit.
