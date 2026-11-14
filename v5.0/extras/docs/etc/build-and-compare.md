# Build and compare DOS 5.00

From O:/repos.hobby/ms-dos-rebuilt/v5.0 run:

```bat
extras\build.cmd
```

Success publishes IO.SYS (33430 bytes), MSDOS.SYS (37394 bytes), and
COMMAND.COM (47845 bytes) to v5.0/extras/assets. All three freshly compiled
files must pass FC /B before publication. Targets are never published as outputs.

## Requirements and execution

Windows CMD, certutil, FC and XCOPY are host utilities. The pinned DOSBox
installation and historical DOS tools are listed in
extras/tools/dosbuild/host-tools.cmd and tools.lst. Keep their absolute
reference locations available. GCC builds the native private-desktop launcher
when its cached executable is absent. Source and reproducible output hashes
are checked. No Python, PowerShell or other script runtime is used.
DOSBox runs only on the private desktop.

Frozen targets are in extras/baselines/targets; their hashes are in
extras/tools/dosbuild/targets.sha256. The original image and read-only FAT12
extraction are recorded in evidence/quality-target-baseline.json. Targets
and build directories are Git-ignored. This checkout requires those local
external tools and baseline files; it is not a bundled tool distribution.

Fresh sources are staged under extras/build/cmd-*. DOS MASM, NMAKE and
historical message/link tools build the three components. Input hashes are
checked before and after. Makefile dependency forms derive from DOS6/OpenNT,
adapted to the selected DOS5 modules. BOOT messages are now source data;
no build-time source patch or output-byte patch is applied.

All three comparisons precede publication. Previous assets are backed up;
a partial publication failure restores them. This is sequential replacement
with rollback, not a three-file atomic transaction. Logs, maps, listings,
input hashes and result.txt remain in the run directory. A nonzero exit code
means failure. The root entry prevents concurrent builds with an empty lock
directory; after forced termination remove that stale lock only after
confirming no build is running.

## Accepted evidence

The complete accepted run is extras/build/cmd-6108-11594. See
evidence/quality-cmd-build.json, quality-cmd-negative.json and
quality-runner-rebuild.json. Final cleanup is covered by quality-final-audit.json.
Documentation-only edits and deletion of unused debug/editor inputs after
that run do not change assembly or build behavior and do not require a rebuild.
No image mount, SoftPC runtime test, candidate archive or O:/DOS deployment
is required. Historical documents describe retired workflows, not commands
to execute today. Output identity does not prove original source provenance.

## Visible progress

The console prints six host stages, a counter every 25 hash operations, and
the latest DOS batch phase every five seconds during compilation. These are
activity indicators, not a byte-match percentage. Native messages are flushed
to both the console and host.log. Detailed compiler output stays in make.log;
failure prints the last phase and relevant log paths. A stale native launcher
cache is automatically rebuilt and checked against the pinned hash.
