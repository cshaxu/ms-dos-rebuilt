# DOS 6.22 bounded build completion

## M4 T24 S1 Packet

Field | Required record
--- | ---
Identifier Mode | New; follows closed T23
Admission And Approval | Owner authorized self-directed goal; resolve observed T23 build completion timeout
Objective | Let the original DOS compile finish and exit naturally within a realistic bounded deadline, then verify/publish/pause normally
Non-goals | No DOS source, original compiler commands, target bytes or other version tool changes; no success inferred from progress markers
Reference Baseline | v6.22 current isolated runner and T23 host.log; BUILD.OK PASS at about 55s, termination at hard 60s
Candidate Proposal | Increase total bounded session allowance to 300 seconds; preserve 5s progress, process exit propagation and owned job termination
Files And ABI Surface | extras/tools/isolated_tool_runner.c and its host-tools.cmd hash pins; fixture/evidence under extras
Applicable Rules | CMD/BAT/C only; private desktop, no Computer Use; no forbidden temp paths; byte-identical three outputs
Verification | Native success/nonzero/timeout fixtures; real clean build naturally exits and completes all comparisons/publication; pause remains
Expected Markers | Child exit 0 with timeout 0, three MATCH results and normal build completion
Asset Needs | Existing DOSBox/original tools, rebuilt pinned native runner, ignored extras/build
Reporting Requirements | Root cause evidence versus inference, files modified, real build result and byte identity
Stop Conditions | Unbounded wait, swallowed child failure, changed target output, or unchanged symptom after budget adjustment
Exit Criteria | Fixtures retain failure semantics; real build completes automatic post-check/publication; documented limitation if not reproduced
Original Owner Request | Set the next goal autonomously
Similar-Issue Sweep | Total timeout versus shutdown timeout, false PASS on marker, process ownership, timeout cleanup and heartbeat

S1 and T24 complete. Observed cause of forced failure is the 60-second total budget.
Shutdown deadlock is not established by the old log. Verify with a longer but
finite budget; do not change DOSBox exit semantics merely on that assumption.

Verification complete: success/nonzero/timeout fixtures passed; production
runner passed a 65-second natural-exit fixture. Real build cmd-19618-967 exited
with timeout=0, passed all three byte comparisons, published assets and reached
the original final pause with exit code 0. All current source/tool snapshot
records match the verified build. Source changes 0; production tooling files
changed 2. See history/M4-T24-completion-audit.md and etc/T24 evidence.
