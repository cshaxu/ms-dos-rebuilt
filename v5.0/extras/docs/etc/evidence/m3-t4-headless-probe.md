# M3 T4 S1 headless SoftPC core probe

Owner permanently prohibits Computer Use. This work uses machine APIs only,
without CUA/sky, desktop capture, host input injection or a product window.

The existing SoftPC runtime fixture exposes start/stop and physical-memory
reads. A local C probe creates the core with direct access to a disposable
floppy, starts its runtime, waits 15 seconds, stops it, reads B8000 text memory,
and destroys the runtime and core. Outer process timeout is 35 seconds.
The build script compiles into a fresh local stage and links against existing
neighboring test objects/libraries read-only; compiler and all link inputs
are hashed in m3-t4-probe-build.json. It does not rebuild or edit SoftPC.

First successful run stage: build/command-vm-i23yw5y5. Process exit 0;
machine create=0, started state=1, pre-stop state=2, stopped CS:IP F000:E83F,
video-read=0. Text memory contains the DOS A> prompt and all expected markers:
VER 5.00, ENV-PASS, PATH=A:\, FOR-ONE/TWO/THREE, FILE-CONTENT, FILE-PASS,
CHILD-PASS and SMOKE-PASS. These are guest-generated output, not host predictions.
The FAT inspection additionally found DONE.TXT=FINISHED, COPY.TXT=FILE-CONTENT,
and no live INPUT.TXT. Original system-file bytes remain fixtures except the
source-built COMMAND, whose full hash is identical to the target.

RESULTS.TXT exists but is empty: the CALL/batch redirection did not retain
the screen output. Therefore file-only collection is not a sufficient oracle
for this fixture. Acceptance here uses stopped guest text memory and on-disk
completion/file-operation artifacts. The earlier product run also lacked
DONE.TXT, so its timeout is not explained by RESULTS.TXT alone.

Evidence: m3-t4-probe-runtime.json and the owned stage's probe.log. Repeat with
the new bounded driver (fresh media is mandatory):

```powershell
python tools/build_softpc_probe.py
python tools/prepare_command_vm.py
python tools/run_softpc_probe.py
```

The retained driver was then executed on a second fresh medium,
build/command-vm-yu79dpx5. m3-t4-headless-runtime.json records exit 0,
no missing markers, passed=true and unchanged guest system-file hashes.

Scope limitation: this verifies the SoftPC core from the neighboring build,
not the supplied O:\DOS\softpc64.exe. Its product-level startup/configuration
still needs an isolated-desktop probe. No source-level DOS kernel or BIOS
reconstruction is claimed. T4 remains active; original images and O:\DOS
configuration were not altered.

Latest continuation: per-command redirection replaces CALL-level redirection.
The fresh medium build/command-vm-5e3s_yo_ passed the bounded core driver:
exit 0, all eleven expected markers in guest RESULTS.TXT, no SMOKE-FAIL,
and unchanged original image and guest system-file hashes. The current
m3-t4-headless-runtime.json records this file-based observation; its legacy
screen_markers key names the expected markers, not the observation source.

Before that core run, the isolated product helper failed at CreateDesktop
with Win32 error 5 (access denied), before CreateProcess. Its retained log is
build/command-vm-5e3s_yo_/isolated-probe.log. No product startup or boot can be
inferred from that attempt. No fallback to the user's desktop is permitted.

Subsequent approved isolated-desktop product execution succeeded after the
probe submitted `start` to its owned console. See m3-t4-product-runtime.json
and ../../history/M3-T4-completion-audit.md for the superseding T4 disposition.
