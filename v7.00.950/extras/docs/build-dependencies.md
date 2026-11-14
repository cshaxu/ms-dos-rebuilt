# Build dependencies

Run `extras\build.cmd` from the version root on the existing Windows toolchain
host. The entry uses CMD/BAT and native executables only. It prints eight
phases, reports the active DOS compilation phase every five seconds, and pauses
after success or failure. Every invocation uses a new build directory.

| Dependency | Location / record |
| --- | --- |
| NMAKE, MASM, ML, C 6.00, LINK, LIB, BUILDIDX, RELOC, NOSRVBLD | `O:/repos.hobby/ms-dos-archaeology/v6.0/c6ers/tools6/bin` |
| C 6.00 headers and small-model runtime | The same `tools6/include` and `tools6/lib/slibce.lib` |
| STRIPZ | `O:/repos.hobby/ntvdm64/tools/opennt/tools16/stripz.exe` |
| DOSBox 0.74-3 | `C:/Program Files (x86)/DOSBox-0.74-3/DOSBox.exe` |
| Original large-model CRT | `O:/repos.external/OpenNT/public/sdk/lib16/llibce.lib` |
| Native host compiler | GCC on PATH; the isolated launcher is checked against its reproducible executable hash |
| Boot logo | `extras/resources/boot-logo/manifest.json`, `logo.mrc`, `logo.bmp` |
| Verification targets | `extras/baselines/targets/IO.SYS`, `MSDOS.SYS`, `COMMAND.COM` |

Historical tools, C headers and runtime inputs are pinned in
`extras/tools/dosbuild/tools.lst`; host settings are in `host-tools.cmd`.
COMMAND's BUILDMSG is compiled from `cmd/command/buildmsg.c` by Microsoft C 6.00.
It generates the required class headers directly.

The original large-model CRT SHA256 is
`6dd7fdf103a71d0cec3433aa3bd7d05b73f90c3e9f24e667c29d5f3c0f9a9389`.
`crtlib.c` resolves its OMF aliases; original LIB rebuilds the compatible
archive. Its verified SHA256 is
`b362c8454f1c2bc9dd46c686b1d86d8b4dfbb51fd337f2d918299e53f366df35`.
The explicit DOS-startup option preserves the documented startup-symbol
adaptation. Code, data and fixup records are retained.

Configuration source organization and link order are maintained in
`bios/config.mak` and `bios/config.lnk`. `omforder.c` preserves source-generated
machine code and fixup operands while serializing OMF records in the required
order. Symbolic boundaries are declared in the six `.omf` files under
`extras/tools/dosbuild`. Original LINK produces the EXEPACK stream and decoder.

`msgindex.c` arranges generated message classes. `cmdimage.c` and `ioimage.c`
write resource/container headers from linked components. They do not read target
executables. The boot logo remains a declared original graphic resource.

Input hashes before and after compilation must match. All three generated
files must compare byte for byte with the fixed targets before publication to
`extras/assets`. Logs, snapshots, hashes and the result are retained under the
printed `extras/build/cmd-*` directory. Build outputs are ignored by Git.
