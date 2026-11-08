# M3 T4 S1 SoftPC fixture and first run

T3 closure audit revalidated the current 113-file source snapshot and both
34-object clean build outputs. T4 is admitted for shell tests under supplied
SoftPC; the exact COMMAND result remains unchanged.

`prepare_command_vm.py` creates a new owned stage. It validates the original
image hash, pads a disposable copy to the BPB size, explicitly copies the
source-built COMMAND into its existing FAT chain, and adds AUTOEXEC/SMOKE.BAT
using free FAT12 clusters and root entries. Both FAT copies are updated.
It verifies all three system-file hashes after image creation. IO.SYS and
MSDOS.SYS are original fixture binaries, not reconstructed source products.
Missing-tail zero filling is a stated test assumption only.

The stage contains a byte-identical copy of O:\DOS\softpc64.exe and a new
adjacent configuration: isolated floppy, direct writes, no hard disk, 16 MB,
window presentation, console control disabled. Original O:\DOS configuration
and executable were not changed or used as configuration input.

Fixture corrections before execution: made the batch literal raw to preserve
DOS backslashes, and used the documented config boolean `0` rather than
`false`. The first prepared stage was never launched; a fresh corrected stage
was created. Current preparation record is m3-t4-prepared.json.

First run: m3-t4-runtime.json, owned PID 32936. No DONE.TXT or RESULTS.TXT was
produced within 45 seconds; host log was empty. The runner terminated only its
own child process and waited for exit. This is an inconclusive runtime result,
not evidence that COMMAND failed or that boot succeeded. All expected markers
are missing. Original image hash and guest COMMAND hash were checked after
the run and remain pinned values.

```powershell
python tools/prepare_command_vm.py
python tools/run_command_vm.py
```

Each run requires freshly prepared media because the runner checks its initial
hash. Planned checks: VER, SET/IF, PATH, FOR, file copy/type/delete/redirection,
child COMMAND and final status. These tests are prepared but not passed.
Next action: inspect actual SoftPC startup presentation and determine whether
the machine stopped before boot, at an interactive prompt, or in shell execution.
Do not repeat the same blind timeout or attribute it to source reconstruction.
T4 S1 remains active. Final O:\DOS deployment and the kernel/BIOS rebuild are
still pending.
