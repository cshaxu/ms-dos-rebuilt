# Execution rules

Adapted from SoftPC `docs/rules/EXECUTION.md`; project-specific rules below are authoritative here. Explicit user instructions take precedence.

## Permanent runtime interaction constraint

The owner permanently prohibits Computer Use. Use isolated desktops and probes
only for runtime interaction/observation. CUA, sky and equivalent automation of
the user's desktop are forbidden. Hidden windows and separate working directories
do not satisfy desktop isolation. Verify the execution boundary before launching
a GUI VM; use machine probes and retained guest/log artifacts where possible.

## MTSP and admission

M is a roadmap milestone; T is a globally increasing implementation task number allocated on admission; S is a subtask, numbered within T; P is a complete reviewable delivery part, not a claim of task completion. Td is a milestone-local governance task and does not consume a numeric T. One active S at a time. The user has authorized planning and governance in this conversation; ordinary work within that authorization does not require repeated permission. Admit subsequent work on user direction or authorization already given; do not manufacture approval gates.

Lifecycle: accepted → planned → active → implemented → verified → closed, with blocked/deferred states recorded honestly. `CURRENT.md` owns the sole active packet. Packet heading is `## M<m> T<t> S<s> Packet` or `## M<m> Td S<s> Packet`; use a `Field | Required record` table with Identifier Mode, Admission And Approval, Objective, Non-goals, Reference Baseline, Candidate Proposal, Files And ABI Surface, Applicable Rules, Verification, Expected Markers, Asset Needs, Reporting Requirements, Stop Conditions, Exit Criteria, Original Owner Request, Similar-Issue Sweep. Identifier modes are New, Continuation, Corrective, Owner-Reopen, Governance; never reuse identifiers. Scope or acceptance changes require packet revision reflecting existing user authorization.

## Verification and closure

An S closes only against its criteria and applicable checks, after reviewing actual changed files and evidence. A T additionally needs a separate audit mapping its request, all S records, open transfers and verification to its completion standard. Whole-domain claims require a finite convergence ledger: frozen universe, units, dispositions, proof for each and completion predicate. Record changes in the universe. Defect repair includes a similar-issue sweep and disposition; transfer out-of-scope issues to TODO or a proposal.

Use reproducible commands and evidence proportional to the actual change. Target identity requires direct byte comparison and hashes; a successful build, smoke test, or matching hash of one component cannot close the project. Record exact tools, source and generated-resource versions, flags, link order and differences. Long jobs need an owner, log, exit result, timeout and no-progress budget; timeout is inconclusive. Keep scratch under owned disposable paths, preserve inputs and other work, and clean only verified owned scratch after retaining concise evidence.

A P contains a coherent implementation and its relevant proof. Review actual changes independently in coordinator role before accepting. Use `M<n> T<n> S<n> P<n>: ...` or `M<n> Td S<n> P<n>: ...` if making commits. Do not commit, push or publish solely because a borrowed rule says so; follow user authorization and environment constraints. Never treat documentation validation as proof of factual completion.
