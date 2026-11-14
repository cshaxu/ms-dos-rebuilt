# M4 T24 completion audit

## Finding and repair

T23's runner allowed twelve five-second waits for the entire DOSBox session,
not a separate shutdown grace period. Its log reported compilation complete
around 55 seconds, then forcibly terminated the owned job at 60 seconds.
That is direct evidence of an exhausted total budget, not proof of a shutdown
deadlock. The repaired runner allows 300 seconds for the complete session.
Progress remains every five seconds; only natural process exit is success.
Nonzero child status and bounded timeout/job termination remain unchanged.
No BUILD.OK or progress message bypasses process exit checks.

Production changes: extras/tools/isolated_tool_runner.c and the two runner
hash pins in extras/tools/dosbuild/host-tools.cmd. No DOS source, build.cmd,
DOS build.bat, makefile, compiler command or target was modified.

## Evidence

Requirement | Result
--- | ---
Natural success | Native isolated fixture exits 0; runner returns 0 with timeout=0
Child failure propagation | Fixture exits 23; runner returns exactly 23
Bounded failure | Same source built with a five-second test budget terminates a 15-second fixture with exit 124 and timeout=1
Old boundary removed without unbounded waiting | Production runner lets a 65-second fixture exit naturally with code 0; heartbeat continues through 60 seconds
Reproducible pinned executable | Two builds from the formal source path and fixed epoch yield SHA256 2af3c0bed85f074dbeac47406756b1d6bc5fd52137059579392bab9e17f31805
Real original-tool build | cmd-19618-967 exits naturally, timeout=0; before/after input snapshots match; all three target comparisons pass; publication completes; outer exit code 0
Manual visibility and pause | Original five-second heartbeat and build.cmd phase output preserved; final pause remains unchanged. Automated validation supplies stdin NUL rather than waiting for user input
Binary identity | IO.SYS, MSDOS.SYS and COMMAND.COM freshly built and byte-compared with frozen v6.22 targets before publication
Scope | Only v6.22 runner and pin file changed; no Computer Use, worktrees, other-version source or forbidden temp paths

An initial test under the workspace sandbox could not create a private desktop
(error 5); the authorized isolated-desktop run passed. An initial integration
build correctly rejected the EXE hash produced under a temporary source name.
The final hash was reproduced from the formal source path twice; checks were
not disabled. Both earlier failures remain in their logs.

The real successful run finished its child in under 60 seconds; it alone does
not prove historical shutdown timing was fixed. The independent 65-second
production-runner test proves the changed deadline behavior. Five minutes
remains a finite total allowance; this is not a claim that arbitrary hangs
cannot occur. T24 acceptance is met with no remaining task.
