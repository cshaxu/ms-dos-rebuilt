# Manual three-core build

Run extras/build.cmd from the version root. Verified IO.SYS, MSDOS.SYS and
COMMAND.COM are published to extras/assets only after all three full FC /B
comparisons pass. The files are compiled outputs, not copies of the targets.

The sibling v6.2 source tree is the direct baseline for both 6.21 and 6.22.
Only local version differences are stored in the source overlay. There is no
6.22 dependency on the v6.21 tree. baseline.lst and overlay.lst under
extras/tools/dosbuild list exact paths and hashes. Missing, changed or extra
files under bios, dos, inc, cmd and lang cause failure. Changes require an
explicit reviewed manifest update. Historical file-ledger.json is retained
as old reconstruction evidence, not the current build manifest.

CMD stages declared sources, invokes the original DOS makefiles and historical
MASM/NMAKE/LINK/message tools, then checks input hashes again. No build-time
source rewriting or binary patching occurs. Both versions use the same host
builder and DOS batch; target hashes and source manifests carry version data.

## Local prerequisites

Windows CMD, certutil, FC and XCOPY; pinned DOSBox and DOS tools in
extras/tools/dosbuild/host-tools.cmd and tools.lst; the sibling v6.2 tree;
and image-derived files in extras/baselines/targets. GCC compiles the native
C launcher if its cached executable is absent. Its source and output are
hash-checked. DOSBox uses a private desktop with a bounded owned process job.
No Python, PowerShell, Node or other scripting runtime is required.

## Results and failures

Each invocation has a fresh Git-ignored extras/build/cmd-* directory containing
compiler logs, maps, input snapshots, comparisons, output hashes and result.txt.
Nonzero exit means failure. Source/baseline hash errors occur before compilation.
All three output checks precede publication. Previous assets are backed up and
restored if any replacement fails; this is not a three-file atomic transaction.
The root entry rejects simultaneous builds of the same version with a lock
directory. Remove a stale lock after forced termination only when no build runs.
No image mounting, SoftPC smoke test, O:/DOS deployment or candidate packaging
is part of acceptance. Exact output does not prove exact historical source text.

See etc/quality-build-acceptance.json for the accepted build, source audit,
guard tests and script-retirement evidence. Historical Python commands in
archived documents describe retired workflows and must not be executed.

## Visible progress

The console prints six host stages, a counter every 25 hash operations, and
the latest DOS batch phase every five seconds during compilation. These are
activity indicators, not a byte-match percentage. Native messages are flushed
to both the console and host.log. Detailed compiler output stays in make.log;
failure prints the last phase and relevant log paths. A stale native launcher
cache is automatically rebuilt and checked against the pinned hash.
