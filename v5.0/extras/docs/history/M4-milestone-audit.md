# M4 milestone audit

The M4 roadmap exit criterion is a source-reconstructed MSDOS.SYS matching the accepted target. The separate [T5 audit](M4-T5-completion-audit.md) records both completed subtasks, the 55 linked units, source correspondence and build inputs.

The latest integrated output `build/integrated-source-o1gc1cvu/MSDOS.SYS` was directly compared with `O:/DOS/MSDOS.SYS`: all 37,394 bytes match; SHA-256 is `4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2`. The [Get-DPB/FAT static call-chain record](../etc/evidence/m6-getdpb-callchain-expanded-9y047lqr-v2.json) refers to this same target hash; its 16 call and four branch instruction byte sequences were rechecked directly against the retained target.

M4 is closed for the declared target-identity criterion. The comparison does not prove exact original source authorship, all optional configurations, or complete behavioral equivalence beyond the target output. The owner accepted retained targets and does not require SoftPC runtime validation or remounting the image. Provenance and dependency limits remain in [TODO](../states/TODO.md). M5, M6 and whole-project acceptance require separate reviews.
