# Building and publishing MS-DOS 6.20

Run extras/build.cmd in the v6.2 root, from Command Prompt or by double-clicking it.
It works from another current directory as well:

    O:\repos.hobby\ms-dos-rebuilt\v6.2\build.cmd

On success the exit code is 0 and the three files are published to:

    v6.2\extras\assets\IO.SYS
    v6.2\extras\assets\MSDOS.SYS
    v6.2\extras\assets\COMMAND.COM

The entry and its helper use CMD only. Python, PowerShell and Node.js are not
required. Windows certutil checks SHA-256; fc /b compares complete outputs.

## Dependencies

- Historical DOS executables at the paths and hashes in
  extras/tools/dosbuild/tools.lst.
- DOSBox at the path pinned by extras/tools/dosbuild/host-tools.cmd.
- The native private-desktop runner under extras/build. If absent, GCC on PATH
  compiles extras/tools/isolated_tool_runner.c; the resulting executable must
  match its pinned hash.
- The three previously extracted image files under extras/baselines/targets.
  They are checked against extras/tools/dosbuild/targets.sha256 before any build.
  Keep these files when cleaning scratch. If missing, restore the three original
  files from the owner-supplied msdos620_en_boot.img; the script fails explicitly
  instead of substituting assets or old build output.

The original image is read-only provenance, not a build input. Its details and
target hashes remain in ../etc/target-baseline.json. The tool executables and
image-derived targets are external prerequisites, not bundled source.

## Build and publication

Each run creates a fresh extras/build/cmd-* directory. Source directories are
copied into it without modifying the working sources. The original DOS 6.00
makefiles, tools.ini and historical message tools build the three components;
the small DOS batch under extras/tools/dosbuild controls their order.

DOSBox runs only on the native runner's private desktop, with a bounded timeout.
No Computer Use, target-image mounting or guest smoke test is used.

Inputs are hashed before and after the build. All three outputs must match the
pinned target hashes and pass full byte comparisons before publication begins.
Previous published core files are backed up under the run's previous-assets
directory. A publication failure triggers restoration; any restoration failure
is reported with the backup path. Other files in extras/assets are preserved.
The three replacements are sequential, not a single atomic directory swap.

Only one manual build may run at a time. A second invocation returns a nonzero
exit code while extras/build/manual-build.lock exists. After an interrupted
build, remove that empty lock directory only after confirming no build is still
running.

## Results and cleanup

The console prints the run directory. It contains result.txt, outputs.sha256,
inputs-before.txt, inputs-after.txt, host.log, comparison logs, and each DOS
component's make.log. Failed runs also return a nonzero exit code and preserve
their logs. No pause is added, so the entry can be called from another CMD script.

extras/build is Git-ignored. It is disposable after retaining any desired logs
and previous-assets backups; a missing runner is rebuilt on the next run.
extras/assets is the requested local publication directory. No Git commit or
external deployment is performed.

All Python and PowerShell scripts, including ignored Python backups and bytecode,
were removed in M5/T7. Historical JSON/Markdown audit evidence remains historical;
its old Python command lines are not current build instructions.

The latest CMD acceptance is recorded in ../etc/cmd-build-acceptance.json.
The source spelling and symbol attribution remain partly reconstructed even
though the complete three binaries match the original targets.

## Visible progress

The console prints six host stages, a counter every 25 hash operations, and
the latest DOS batch phase every five seconds during compilation. These are
activity indicators, not a byte-match percentage. Native messages are flushed
to both the console and host.log. Detailed compiler output stays in make.log;
failure prints the last phase and relevant log paths. A stale native launcher
cache is automatically rebuilt and checked against the pinned hash.
