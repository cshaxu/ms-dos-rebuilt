# M4 T5 S2 completion audit

Scope: owner-directed ordered source correspondence, NT/BOP screening and target build identity. The subsequent second-class conversion pass and nine selected resource reviews are also recorded here. This closes S2 only; it does not close T5 or the whole reconstruction goal.

## Exit criteria and evidence

- Frozen source universe: `python tools/file_review_status.py` passed with 172 round 1, 28 round 2, 14 manual, one retired, no pending. Current file hashes and lexical screen are enforced by the tool.
- Reference integrity: `../etc/evidence/current-automatic-reference-integrity.json` and `../etc/evidence/current-round2-passage-verification.json` record reference hash and passage checks after the second-class conversion pass.
- The 48 ordered second-class conversion decisions are complete: 20 converted, 28 retained; see `../etc/round2-to-round1-ledger.json`.
- Nine selected active non-code resources were reviewed; current resource hashes and evidence references were rechecked in `../etc/resource-review-ledger.json`. This does not cover every optional resource.
- Fresh source build `build/integrated-source-o1gc1cvu` directly matches the retained `O:/DOS` files. `../etc/evidence/resource-review-004-build-inputs.json` checks 364 recorded inputs and all three target files; `python tools/audit_style_cleanup.py` passes current snapshot checks.

| File | Bytes | SHA-256 |
| --- | ---: | --- |
| IO.SYS | 33430 | dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0 |
| MSDOS.SYS | 37394 | 4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2 |
| COMMAND.COM | 47845 | 74ad25067e7d9f5c3a0ac2f2967347defb0ffef9e6ed60b60e6499f0b1a8cc89 |

## Limits and transfers

Text matching and lexical screening do not prove the original Microsoft source or exclude all indirect host dependencies. The POWER message is inferred and optional configurations remain unverified. Full OS/tool dependency closure, provenance, and rights remain in `../states/TODO.md`; byte identity uses the owner-accepted retained targets. SoftPC runtime validation and remounting original media are not required by the owner. Later task and milestone closure require their own audits.

Reviewed the current evidence and direct target bytes for the stated S2 exit criteria. No source changes are made by this audit.
