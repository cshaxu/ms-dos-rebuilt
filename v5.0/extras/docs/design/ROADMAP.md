# Roadmap

Milestones express a dependency sequence; they do not claim completion or allocate tasks.

- **M0 — Governance and target baseline:** establish authorities, pin image and three files, audit truncated image and reference inventory. Exit: reproducible extraction, hash and provenance checks; missing evidence listed.
- **M1 — Build and binary analysis foundation:** inventory exact tools, sources, includes and message generation; establish reproducible reference builds where possible, disassembly, map and byte-diff tools. Exit: recorded results and blockers; no fabricated successful build.
- **M2 — Three-way module map and vertical slice:** map OpenNT, DOS 6, DOS 4 and target; classify NT host seams. Reconstruct one bounded COMMAND routine and trace from source through object to target bytes and behavior. Exit: repeatable evidence or explicit unresolved blocker.
- **M3 — COMMAND.COM:** reconstruct resident/transient and initialization, parser, commands, batch, environment, messages and layout. Exit: exact target match.
- **M4 — MSDOS.SYS:** reconstruct kernel and real DOS filesystem, buffer, devices, process and memory paths. Exit: exact target match.
- **M5 — IO.SYS and boot:** reconstruct boot handoff, initialization, CONFIG.SYS and drivers with real machine interfaces. Exit: exact target match.
- **M6 — Full reproducibility and deployment:** clean rebuild all three, compare bytes and hashes against the original image, audit every module/resource and provenance, deploy to authorized destination, record final hashes and exact test conditions. Exit: all goal criteria met, independent task and milestone audit complete.

Ordering reflects risk reduction; a later component may be investigated earlier to unblock interfaces. Partial byte matches and smoke tests are intermediate evidence, not project closure.
