# Deferred debt

- **P1 — Complete build-input and rights inventory.** The T1 manifest pins only its named directories. Audit transitive tools, libraries and message resources, including missing DOS 6 `messages`; separately resolve source origin and redistribution rights before any publication. Admission: [build dependency investigation](../proposals/build-dependency-investigation.md) or explicit publication request.
- **P2 — Original media tail and release provenance.** The supplied image is shorter than its BPB geometry; no FAT cluster in the missing tail is allocated, but original bytes, exact OEM/language and source are unknown. Admission: availability of authoritative media or provenance evidence.

- **P2 — Optional POWER message provenance.** Message 26 is inferred from the commented `INIT_MSG` in `bios/power.asm`; the original DOS 5 wording and optional POWER-enabled link/runtime remain unverified. The message and POWER module assemble with POWER enabled; the target build has POWER disabled. See [evidence](../etc/evidence/m6-power-message-reconstruction-audit.json).

- **Source-review limitation.** The owner-directed 215-entry file ledger has no pending entries. Textual reference coverage and lexical NT/BOP screening do not prove historical origin or exclude indirect dependencies. The owner directed that completed file reviews not be revisited; retain this limitation without scheduling another sweep. The historical 104-module [reference ledger](../etc/evidence/m6-linked-module-reference-ledger-3qm3v2jp.json) and [line-difference triage](../etc/evidence/m6-module-difference-triage-3qm3v2jp.json) describe earlier snapshots.

- **P2 — EXEC failure AL behavior.** The byte-identical target reloads AL from LoadHiFlg before an error-message branch that compares AL. Static evidence and limits: [EXEC return audit](../etc/evidence/m6-command-exec-error-register-audit.json). Preserve target bytes; establish runtime behavior only if later needed.

