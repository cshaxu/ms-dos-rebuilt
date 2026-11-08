# IO.SYS preliminary reference investigation

This is preliminary investigation supporting the active kernel task's BIOS
interface, not admission or completion of the M5 implementation task.
`python tools/investigate_io_baseline.py` reads IO.SYS from two retained,
disposable COMMAND test images. Both contain the same 33430 bytes and match the
originally recorded target SHA-256
`dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0`.
They share the original baseline and are not independent evidence of media
origin. The hash-verified analysis copy is `build/target-io-inspect.bin`;
the original media must still be rechecked when available. Neither this copy
nor the reference binaries may be used as output data in a source build.

The [machine-readable inventory](evidence/m5-io-reference-investigation.json)
records the source link-list sequences: OpenNT has 12 modules, DOS 6 has 15,
and DOS 4 has 13. OpenNT lacks the DOS 6 link entries `msdisk`, `msdioctl`,
`msbio2`, `syspre`, `power`, and `ptime`, and instead includes three SPC
modules. This is a comparison of link lists, not proof of functional absence
or the target's original module boundaries.

Raw matching byte ranges are analysis leads only. For example, the 476-byte
match at target offset 32954 corresponds largely to message text; the 271-byte
match at offset 4 contains 269 zero bytes. Neither proves matching executable
code, a source origin, or runtime behavior.

`python tools/build_ntio_reference.py` now builds the unmodified OpenNT
reference in a fresh disposable stage. Two builds independently assembled all
12 linked modules, regenerated the four message files (identical to the
reference copies), linked and relocated with the documented `70` parameter.
Their source inventories, object hashes and outputs agree; both 33792-byte
outputs match the shipped reference NTIO.SYS byte for byte, SHA-256
`cfc8be16576bb6acd16bb8fc9b2d9a080f544bbfdd2d2d2df07ed908b3ab4937`.
See [first build](evidence/m5-ntio-reference-build-1.json) and
[second build](evidence/m5-ntio-reference-build.json). The reference fixture
was used for comparison, not as source input to the linked output. These are
NT-hosted builds, not the physical target IO.SYS.

`python tools/map_ntio_target_leads.py` checks 40 raw matching ranges against
the rebuilt NTIO and associates each with its nearest preceding public symbol
from the generated map; see [symbol leads](evidence/m5-ntio-target-symbol-leads.json).
For example, the 476-byte message match begins at reference public `badopm`.
Nearest-public labels have no established extent and cannot alone identify a
target function. Next establish bounded source-to-target correspondence and
reconstruct physical device and initialization paths, using DOS 6 and DOS 4
as comparative evidence.

The target's initial jump reaches the non-contiguous MSLOAD loader, a separate
module absent from the OpenNT NTIO link. `bios/msload.asm` is a comparative
copy of DOS 6 MSLOAD; `bios/msbio.cl1` holds the boot message candidate. The
DOS 6 skeleton documents the same message with “strike”, whereas OpenNT's
`messages/usa-ibm.msg` BOOT entry contains “press”, as observed in the target.
The local message include is an explicit source candidate, not a generated
resource; full resource provenance remains open. The candidate uses the
project's DOS 5 `versiona.inc` and DOS 6 comparison includes.

`python tools/build_msload_candidate.py` assembles and links that source in a
fresh stage. Two runs produce identical 1446-byte loaders, SHA-256
`4da72d39959057342b5340b83cca46e2f405c05b322425df5162eb294f19668e`,
each directly equal to IO.SYS offsets [0000h,05A6h). The next target byte at
05A6h begins the subsequent BIOS image. The [first](evidence/m5-msload-candidate-build-1.json)
and [second](evidence/m5-msload-candidate-build.json) reports record inputs,
tool hashes and outputs. This proves a bounded byte correspondence, not
historical source identity, full IO.SYS recovery, or successful execution.

For the BIOS proper, `bios/msbio1.asm` is currently an unmodified DOS 6
comparative candidate, not an NTIO-derived finished module. Its assembled
device chain places `res_dev_list` at BIOS offset 0023h and `Orig13` at 00B4h.
`python tools/verify_bios_device_chain.py` resolves 48 device-header words
using assembler listing symbols and an explicit 0070h BIOS segment assumption,
then compares 218 covered bytes against the target BIOS offsets [0023h,0100h).
All compared bytes agree. Three uninitialized alignment bytes at 00B1h–00B3h
are excluded because the object does not emit them. The [report](evidence/m5-bios-device-chain.json)
records source, include, assembler and object hashes, symbols and each assumed
fixup. This is a comparison harness, not a completed link or proof of the rest
of MSBIO1 or runtime behavior. NTIO remains the primary baseline for the
overall BIOS restoration; physical code requires continued three-way review.

The same verifier also assembles DOS 6 `mschar` and `msdisk`, using the
reference link order and WORD-aligned BIOS_CODE contribution lengths to derive
their table bases (00E4h and 04A2h). With 29 explicit address and relative
call fixups, the candidate's 109 bytes at BIOS offsets [06F5h,0762h) match
the target. This interval covers `strategy`, the CON/PRN/AUX/CLOCK/disk
entry stubs, and `cdev_entry` through its call to `EnsureA20On`. The table
placements and fixups are comparison assumptions backed by the assembled
reference modules, not a complete linked BIOS or verification of the called
drivers and A20 implementation. Results and individual fixups are in the same
device-chain report.

`python tools/build_bios_comparison.py` builds and links all 15 DOS 6 BIOS
reference modules with the DOS 5 version definition. It uses a temporary
combination of OpenNT USA-MS and USA-IBM BOOT messages; class 3 defaults are
taken from the DOS 6 skeleton because the OpenNT message source lacks later
multi-configuration entries. These are explicitly comparative resources, not
accepted DOS 5 resources. The first 1760 bytes of the linked BIOS match the
target's BIOS bytes directly, including the three previously uninitialized
alignment bytes. The linked [06F5h,0762h) device-entry interval also matches;
the subsequent [0762h,08F9h) interval, including interrupt handlers, matches
for another 407 bytes. This actual-link comparison independently checks the
earlier manually resolved device-header and entry results. It does not validate
runtime behavior or prove every handler's surrounding dependencies.

The linked comparison BIOS is 38896 bytes versus 31984 bytes remaining after
the target MSLOAD; there are 24867 differences in their common prefix. The
first occurs at BIOS offset 06E0h. See the [build evidence](evidence/m5-bios-comparison-build.json)
for all 15 object hashes, input snapshots, generated messages and tested
intervals. Full IO.SYS reconstruction and a complete dependency review remain
open.

The first comparison-layout investigation identified two DOS 6 initialization
blocks absent at the corresponding target positions: the startup banner and
the Compaq dual-controller mode setup. `bios/msinit.asm` is a DOS 6-derived
physical candidate with those two blocks removed; OpenNT's `msinit.asm` remains
the primary NT baseline but omits substantial physical initialization. The
candidate preserves the surrounding source and its procedure conventions.

`python tools/build_bios_comparison.py --candidate` overlays the local MSBIO1
and MSINIT candidates into the same 15-module comparison build. Two independent
runs have identical source inventories, object hashes and outputs. The linked
BIOS_CODE start moves from 25C0h to 2570h, matching the target segment pointers;
the BIOS prefix [0000h,08F9h) and initialization interval [0900h,19C0h) match
the target directly. Differences in the common prefix fall from 24867 to 15667.
See [first run](evidence/m5-bios-physical-candidate-build-1.json) and
[repeat with interval checks](evidence/m5-bios-physical-candidate-build.json).
These counts include layout effects; the candidate still uses provisional
DOS 6 sources and messages, and is not an accepted or boot-tested IO.SYS.

The next comparison identified a 13-byte DOS 6 `install_bds` EOT update that
is absent at the corresponding target return. `bios/msbio2.asm` preserves the
surrounding BDS insertion procedure and removes that update in the candidate.
Two candidate links with identical inputs, objects and output now place the
complete BIOS_CODE segment at [2570h,3FD0h); all 6752 linked bytes match the
target directly. The segment contains contributions from multiple modules,
some still unmodified DOS 6 comparison sources. SYSINITSEG starts at 3FD0h.
Evidence: [first build](evidence/m5-bios-bds-candidate-build-1.json),
[repeat with complete segment check](evidence/m5-bios-physical-candidate-build.json),
and [previous candidate](evidence/m5-bios-before-bds-build.json).
The overall BIOS still has 14594 common-prefix differences, with 12 differing
bytes in [0900h,2570h); those include unresolved downstream layout references.
This result does not establish runtime behavior, whole IO.SYS identity or
historical authorship.

In SYSINIT, the hardware-interrupt stack switch differed at the DOS 6
`found02` path. The target instruction sequence agrees with the retained
OpenNT `sysinit1.asm` implementation. The local `bios/sysinit1.asm` candidate
therefore uses that NTIO sequence inside the DOS 6-derived physical module,
retaining the surrounding physical code. Two isolated candidate builds agree
in source inventories, object hashes and output. Their actual linked SYSINIT
prefix [3FD0h,4238h) matches 616 target bytes, and the complete BIOS_CODE
segment remains equal. The [first build](evidence/m5-bios-sysinit-stack-build-1.json)
and [repeat](evidence/m5-bios-physical-candidate-build.json) record inputs and
outputs; [the preceding build](evidence/m5-bios-before-sysinit-stack.json)
preserves the prior state. Overall common-prefix differences are now 14390;
three bytes still differ in BIOS initialization [0900h,2570h). This does not
establish interrupt or startup runtime behavior.

The target's early SYSINIT data places the default command line immediately
after `DirStrng`, consistent with the OpenNT SYSINIT1 source. The DOS 6
comparison puts it in SYSINIT2 and has an additional `top_of_cdss` variable
before `DirStrng`. The local SYSINIT1/SYSINIT2 candidates restore the NTIO
command-line definition and module ownership. Because unfinished DOS 6 paths
still reference `top_of_cdss`, its storage is temporarily retained next to the
SYSINIT temporary stack; that placement is a comparison seam, not a claimed
DOS 5 layout. Model-byte and other later variables still require review.

Two isolated builds match in inputs, object hashes and output. Their linked
SYSINIT data [423Bh,43D0h) matches 405 target bytes, while all previously
asserted BIOS and stack intervals remain equal. Overall common-prefix
differences are 14174; see [first build](evidence/m5-bios-command-layout-build-1.json),
[repeat](evidence/m5-bios-physical-candidate-build.json), and
[prior state](evidence/m5-bios-before-command-layout.json). The SYSINIT jump,
later variable placement, physical initialization paths, message resources,
full link identity and runtime remain open.

The NTIO request packet uses one `drivenumber` byte where the DOS 6 comparison
has separate `devdrivenum` and `drivenumber` bytes. The candidate now aliases
those names to the same byte, so remaining DOS 6 callers still link; this is a
temporary compatibility seam and its runtime semantics require review. An
explicit `--oembase` probe disables DOS 6 DblSpace hooks using the existing
Microsoft conditional. Two isolated builds with that option have identical
inputs, objects and output, and match target bytes [423Bh,4456h), 539 bytes,
while preserving all earlier asserted intervals. Evidence: [first](evidence/m5-bios-oembase-probe-1.json)
and [second](evidence/m5-bios-oembase-probe.json). The probe has 14137
common-prefix differences and is not yet the accepted build configuration.
Moving the temporary `top_of_cdss` to the end of the segment caused a MASM
phase error; that experiment was reverted, and no failed output was accepted.
The [default candidate](evidence/m5-bios-physical-candidate-build.json) was
rebuilt from the current source and has 14170 common-prefix differences.

The `top_of_cdss` seam has since been removed. SYSINIT now uses OpenNT's
`confbot`/`alloclim` temporary CDS allocation flow instead of the DOS 6
preallocation for 26 CDSs. The physical temporary-buffer initialization
remains active, with the buffer segment taken from the preallocation address.
Two isolated OEMBASE builds match target SYSINIT bytes [423Bh,44E1h), and 34
bytes of the `TempCDS` allocation core at candidate [4D2Dh,4D4Fh) against
target [4C1Ch,4C3Eh). The latter is a displaced comparison and does not prove
its earlier call, the full routine or runtime. Inputs, objects and outputs
agree between [first build](evidence/m5-bios-cds-probe-1.json) and
[repeat](evidence/m5-bios-oembase-probe.json); the [prior probe](evidence/m5-bios-before-cds-probe.json)
preserves the previous state. The OEMBASE probe has 13309 common-prefix
differences. The refreshed default candidate has 14141; OEMBASE selection,
drive-number alias behavior, remaining SYSINIT code and execution are open.

An isolated `--singleconfig` experiment comments out the four DOS 6
`MULTI_CONFIG` definitions in the staged SYSINIT1, SYSINIT2, SYSCONF and
SYSIMES copies, alongside OEMBASE. It does not change those four source files
in the project. The obsolete `StartMsg` external declaration was removed
from the local MSINIT candidate because its sole banner use was already
removed; leaving the unused import caused the first probe link to fail.
Two successful builds then had identical staged source inventories, objects
and output. Their actual linked BIOS prefix [0000h,19DBh), 6619 bytes, matches
the target directly, and the earlier BIOS_CODE and SYSINIT interval checks
still pass. See [first build](evidence/m5-bios-singleconfig-probe-1.json) and
[repeat](evidence/m5-bios-singleconfig-probe.json). The complete comparison
BIOS remains 34688 bytes versus the target's 31984 bytes after MSLOAD, with
12736 common-prefix byte differences. The staged conditional changes are an
investigation result, not an accepted full DOS 5 source or runtime validation.

The DOS 6 `ClrVDISKHeader` contains a 25-byte password-server-mode workaround
before its block move; the corresponding target enters the block move directly.
The SYSINIT1 candidate removes that later machine-specific branch. Two isolated
single-configuration builds agree in inputs, object hashes and output, and the
entire 42-byte linked `ClrVDISKHeader` at [4B6Eh,4B98h) matches the target.
Previously asserted BIOS, SYSINIT and 6619-byte prefix intervals remain equal.
See [first](evidence/m5-bios-vdisk-probe-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json), and
[before change](evidence/m5-bios-before-vdisk-probe.json). The single-config
probe still has 12464 common-prefix differences; refreshed OEMBASE and default
builds have 13315 and 14153 respectively. These counts include layout effects;
physical execution and other initialization paths remain unverified.

The single-config target prepares the shell command line by scanning and
copying its null-terminated text, appending CR, and writing the measured
length. This sequence is present in OpenNT SYSINIT1; the candidate now uses
that source block, preserving its NOEXEC alternatives. Two isolated links
have identical inputs, objects and output, and the 25 bytes at BIOS offsets
[47D9h,47F2h) match the target directly. See [first build](evidence/m5-bios-command-prepare-build-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json), and
[prior probe](evidence/m5-bios-before-command-prepare.json).

The additional code shifts later SYSINIT addresses. Consequently the old
continuous [0000h,19DBh) result is historical: the current build differs at
08F9h, with [0000h,08F9h) and [08FAh,19DBh) still equal. The earlier VDISK
routine is now displaced and has four byte differences needing relocation
analysis; it is not claimed byte-identical in the current link. The overall
single-config probe has 12874 common-prefix differences, a layout-sensitive
count; refreshed OEMBASE/default builds have 13309/14158. Full target
identity, reference-branch review and runtime remain open.

The four displaced VDISK operand differences and BIOS pointer at 08F9h were
checked against the actual MASM listing and link map. In the earlier build,
all five reflected a 10-byte SYSINIT displacement; the current build has a
one-byte displacement. The [comparison-only verifier](../../tools/verify_bios_relocations.py)
resolves four named operands and confirms all 42 VDISK bytes after normalization,
plus the corresponding `FTryToMovDOSHi` pointer. It does not patch the output;
see [current evidence](evidence/m5-bios-vdisk-relocation-verification.json).

The non-multi-config shell EXEC path now follows the retained NTIO structure:
memory error goes to `mem_err`, the saved filename is popped before EXEC setup,
and AX is prepared with the original instruction sequence. After failed EXEC,
the candidate calls the error handler and loops as observed in the physical
target; it does not use NTIO's host-exit service. Two isolated links agree in
inputs, objects and output. Linked intervals [4849h,4864h) and [4869h,489Bh)
match the target directly; intervening and preceding address operands remain
unresolved. See [first](evidence/m5-bios-exec-path-build-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json) and
[prior state](evidence/m5-bios-before-exec-path.json). The current single-config
probe has 12487 common-prefix differences, including layout effects. The
OEMBASE TempCDS check now locates the routine through the actual link map
instead of relying on a fixed candidate offset. Runtime remains unverified.

The physical target's `TempCDS` follows `dpb_next_dpb` sequentially; the DOS 6
comparison instead re-finds each DPB by drive letter. NTIO has removed this
physical DPB traversal, so the local SYSINIT1 candidate restores the target
walk using the physical source structures and removes the later lookup helper.
Two isolated single-config builds agree in inputs, objects and output. The
[TempCDS verifier](../../tools/verify_bios_tempcds.py) compares all 152 linked
bytes at candidate BIOS offset 4C06h against target 4C05h, with one explicit
relative call normalized. It independently checks that this call reaches the
named `ParaRound` in the candidate and the corresponding 12 target bytes at
5120h. See [first build](evidence/m5-bios-dpb-walk-build-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json),
[routine and call evidence](evidence/m5-bios-tempcds-verification.json), and
[previous candidate](evidence/m5-bios-before-dpb-walk.json). Current
single-config/OEMBASE/default common-prefix differences are 12447/13303/14132;
these counts include layout effects. The verification does not exercise the
DPB chain or prove system boot.

The target's `INSTALL=` return path checks INT 21h function 4Dh and accepts a
resident exit; the same check remains in OpenNT SYSINIT1. The candidate now
restores that check, and its non-multi EXEC parameter setup uses AX as observed
in the physical target. The latter differs from the NTIO environment setup and
must not be attributed to NTIO. Two isolated single-config builds agree in
inputs, objects and output. Linked candidate bytes at [5111h,511Ch) and
[5120h,512Dh) equal the target at offsets one byte lower; the intervening
external error-handler call remains layout-dependent. See [first build](evidence/m5-bios-install-exit-build-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json), and
[before](evidence/m5-bios-before-install-exit.json).

With the later layout restored, the full linked TempCDS now equals its target
152-byte counterpart directly at a one-byte displacement, including the actual
ParaRound call displacement; [updated evidence](evidence/m5-bios-tempcds-verification.json).
The current single-config/OEMBASE/default common-prefix difference counts are
12497/13296/14159. The source, full boot and runtime remain incomplete.

The one-byte displacement originated in `AllocMemForDOS`'s fatal path: DOS 6
jumped to a later common stall routine, while both the target and OpenNT use
`CLI` followed by `HLT`. The local SYSINIT1 candidate restores that sequence.
Two isolated single-config builds have identical inputs, objects and output.
The [first build](evidence/m5-bios-fatalerr-build-1.json) and
[repeat](evidence/m5-bios-singleconfig-probe.json) directly match the 6619-byte
BIOS prefix [0000h,19DBh). TempCDS at 4C05h and ClrVDISKHeader at 4B6Eh now
also match directly at the target locations, and the FTryToMovDOSHi pointer
is 0A84h in both. See the refreshed [TempCDS](evidence/m5-bios-tempcds-verification.json)
and [VDISK/pointer](evidence/m5-bios-vdisk-relocation-verification.json)
checks and the [prior build](evidence/m5-bios-before-fatalerr.json).
The complete single-config/OEMBASE/default common-prefix difference counts
are 10738/13287/14162. Configuration selection and runtime are still open.

The single-config target's `SWITCHES` parser table has three options, /K, /T
and /W, matching the OpenNT SYSCONF definition. The DOS 6 comparison included
two additional multi-config options even when that feature was disabled. The
local `bios/sysconf.asm` candidate now conditions those two options on
`MULTI_CONFIG`, preserving them in the multi-config build. Two isolated builds
agree in source inputs, objects and output. The 54-byte linked table matches
the target after ten individually named pointer words are normalized for a
one-byte module displacement; see the [verifier](../../tools/verify_bios_switches.py)
and [evidence](evidence/m5-bios-switches-verification.json). This comparison
does not alter the linked binary and does not prove command runtime behavior.
[First build](evidence/m5-bios-switches-build-1.json),
[repeat](evidence/m5-bios-singleconfig-probe.json), and
[before](evidence/m5-bios-before-switches.json) record the change. Current
single-config/OEMBASE/default common-prefix difference counts are
10723/13287/14162; the full BIOS and runtime remain incomplete.

The single-config `doconf` buffer allocation and initial `TempCDS` call now
follow NTIO and the target instructions: allocate below `confbot`, rebuild the
CDS, and reload `confbot` before reading CONFIG.SYS. The DOS 6 multi-config
branch is retained. The linked 148-byte entry through the error return matches
the target after five named address normalizations; the verifier independently
checks the `ParaRound` and `TempCDS` destinations and the CONFIG.SYS name.
See [the verifier](../../tools/verify_bios_doconf.py) and its
[evidence](evidence/m5-bios-doconf-verification.json). The remaining DOS 6
high-load data still displaces this routine, and this comparison does not prove
startup behavior or complete IO.SYS identity.

The single-config CONFIG.SYS multi-pass dispatch now follows the target's
ordinary INSTALL path: the DOS 6 INSTALLHIGH precheck and execution path are
absent from that configuration. The physical target checks `H` but has no
NT-only `E` echo-console branch. The [multi-pass verifier](../../tools/verify_bios_multipass.py)
compares the actual 170 linked bytes at target [61C2h,626Ch), after eight
individually checked relative-address normalizations; it also checks the
`multi_try_doshi` and `tryb` branch destinations. See
[verification evidence](evidence/m5-bios-multipass-verification.json).
Two independent single-config builds produced SHA-256
`469d339a5372b7a6855e08ad40c94eb8cd2d21a5d282257a9a0e3f973a3bca43`.
The retained multi-config comparison also assembles and links; this does not
establish its runtime behavior. The target buffer handlers and downstream
routines remain separate verification obligations.

The single-config DEVICEHIGH entry now follows the NTIO path confirmed by the
physical target: retain the original error position, parse SIZE=, terminate
the driver name and select the UMB path using `DevUMB`. `ParseSize` also uses
the target's SI/BX behavior. The following DEVICE load prelude uses the NTIO
allocation and error paths, without the later DOS 6 `/L` loader setup. The
[linked verifier](../../tools/verify_bios_devicehigh.py) checks the 79-byte
entry, 63-byte SIZE parser and 111-byte DEVICE prelude against the target,
with respectively 9, 8 and 16 individually named address fixups. It checks
all three branches leaving the DEVICEHIGH entry. Evidence is
[here](evidence/m5-bios-devicehigh-verification.json); comparisons do not patch
the output. Two independent single-config builds produced SHA-256
`b5511b05e249f80185bcfae70bc4ceb8262e7705e156c723fc7a43a874a8eed9`.
The retained multi-config reference branch builds with its previous output
hash; neither that build nor these slices prove full driver initialization,
startup execution or whole IO.SYS identity.

Single-config driver initialization now omits DOS 6's temporary drive-count
swap, UMB-loader cleanup and DoubleSpace/PROTMAN postprocessing. The block
path retains the physical DOS device and DPB construction, including its
short branch on an excessive sector size. The existing
[device verifier](../../tools/verify_bios_devicehigh.py) now additionally
checks the 135-byte driver-init interval and the 364-byte device-link/DPB
interval, with 13 and 22 individually named address fixups respectively.
Together with the preceding DEVICE prelude these cover the contiguous target
range [63D1h,6633h), 610 bytes, under comparison-only fixups. See the
[updated evidence](evidence/m5-bios-devicehigh-verification.json). Two
single-config builds agree at SHA-256
`659dff07e5e10b123f3e3d5e7c684e9b44fa3ec8ab955fa906be339e379e2470`;
the multi-config comparison retains its previous output hash. The called
routines, actual boot/device runtime, full IO.SYS and original-image access
remain separate obligations.

The single-config `InitDevLoad` now uses the target DOS 5 UMB selection, and
`GetUMBForDev` again marks the allocated arena inline as in the physical target
and the disabled original path in NTIO. The target interval [6B2Fh,6C32h)
covering `InitDevLoad`, `SpaceInUMB?`, `GetUMBForDev` and `DevSetMark` is 259
bytes and passes the [linked verifier](../../tools/verify_bios_devicehigh.py)
with 24 named address checks; the `ShrinkUMB` body remains separately open.
The now-unreferenced DOS 6 high-load code and its private variables are excluded
from this configuration. The DOS 6 comparative SYSPRE source mentions `ConvLoad`; subsequent inspection
of the actual listing showed that its DoubleSpace branch was not assembled, so
the single-config `ConvLoad` definition has since been removed.
See [evidence](evidence/m5-bios-devicehigh-verification.json).
Two independent single-config builds produce SHA-256
`fd7a8cc32229da274798685dacadbf0ed414439fb6065a60a7afe666308dbc4c`;
the output is 32400 bytes versus the 31984-byte target BIOS remainder and is
not identical. The preserved multi-config comparison also builds with its
previous hash. These comparisons do not establish runtime behavior.

A recheck of the assembled SYSPRE listing corrected the earlier source-only
inference: DoubleSpace hooks and the associated `ConvLoad` references are not
assembled in this candidate. The single-config variable can therefore be
removed without altering SYSPRE. The DOS 6 `driver_units` data byte is also
absent from the physical target and now restricted to the multi-config
comparison. The target's checksum-error loop spins without the later HLT; the
single-config `sysinit_base` now follows it. `doconf` and its tables now land
at their target absolute addresses. The [absolute layout verifier](../../tools/verify_bios_absolute_layout.py)
compares [512Ch,5160h) and [6082h,612Eh) directly, 52 and 172 bytes with no
address normalization; see [evidence](evidence/m5-bios-absolute-layout-verification.json).
The candidate builds twice with SHA-256
`0b3908310f860430befc9aa16bf2e8b6e0874282ccdfa25646f70e19a7b307dd`.
The output still differs from the target and no runtime identity is claimed.

The single-config configuration-command order now follows the target and
NTIO: comment/REM handling precedes SWITCHES, and the unknown/null command
paths occupy their target locations. The target DRIVPARM path checks carry
after `diddleback`; that check is restored. SHELL filename and parameter
copying also follows NTIO and the target rather than the later DOS 6 path.
The target `SizeDevice` does not preserve DS and reserves the larger of the
file's paragraph size and SIZE=; both behaviors are restored. The obsolete
PROTMAN arena adjustment is excluded from this configuration.

The absolute verifier now checks eight intervals totalling 868 bytes,
including [6B2Fh,6CCFh), 416 contiguous bytes of UMB allocation, SIZE= sizing,
EXEC setup and the start of break-address processing, with no normalization.
See [evidence](evidence/m5-bios-absolute-layout-verification.json). Two
single-config builds agree on SHA-256
`06b2444a9419d667a372e78ef15ccc2beab8a4f77d475c003c3c237e5fcae32c`;
the preserved multi-config comparison builds with its previous output hash.
The full BIOS and DOS runtime remain unverified and different from the target.

The CONFIG.SYS organizer now follows the target and NTIO single-config
behavior: command-name slash handling and the later INSTALLHIGH case are
excluded, and INSTALL precedes DEVICE. `get2` explicitly reads ES:[SI] and
increments SI, matching the target independently of the direction flag.
`setparms` restores the target BIOS flag-update ordering and excludes the
later EOT change. The target's 17-entry command table is restored in the
original order and matches 145 bytes directly at its displaced location;
`setparms` and `diddleback` match 87 bytes with eight named data-address
normalizations. See [configuration-table evidence](evidence/m5-bios-config-table-verification.json).

The [absolute verifier](../../tools/verify_bios_absolute_layout.py) now covers
1411 raw-equal bytes in eight intervals, including 570 contiguous bytes at
[6B2Fh,6D69h) and the organizer excluding its relocated table pointer.
Two single-config builds agree at SHA-256
`3d35422bee8bfd2941dd5efb0d18a94a57d9d21246fdbec5862563454796e17b`;
the preserved multi-config comparison retains its prior output hash. The
candidate remains 32336 bytes versus the target BIOS remainder of 31984; the
command table and associated data are still displaced, and complete BIOS
identity and runtime are not established.

The NTIO `inc/copyrigh.inc` (SHA-256
`5f5ba93635d6200394f545d20d91532da8ff30d1eacda0d786d79d61cd488ae7`)
is now included in the candidate at the same location as the target. The
DOS 6 extra command-length byte is excluded in single-config mode. The
class-3 message source `bios/msbio.cl3` is reconstructed from the NTIO
`usa-ms.msg` MSBIO entries in target order; DOS 6-only menu messages are not
included. The single-config BIOS build is now 31984 bytes and directly equals
the pinned target BIOS remainder, SHA-256
`09df7ec418edb1728662b1fe911a62c1a7bd3e19ad20b82548f022dd654750ad`.

The [combined evidence](evidence/m5-io-combined-verification.json) records a
byte-for-byte comparison of the existing source-built MSLOAD and BIOS outputs
concatenated against the complete 33430-byte IO.SYS extract, SHA-256
`dd0915ed366b3f640284df4be30ed35f413dfd5b6966c1f25eee9598a5bf53e0`.
This is a combination of existing builds, not a fresh integrated build or
runtime test. A requested command to run the combined build was rejected by
automatic approval review due to concern that DOSBox could use a non-isolated
desktop; no alternative invocation was attempted. A read-only retry of the
original E: floppy image failed with Windows invalid-argument error, so source
media revalidation remains open. The build-report source has since been
corrected to record the class-3 source hash; that reporting-only edit received
Python syntax validation, but has not been exercised by another build.

The [three-file candidate verifier](../../tools/verify_existing_three_files.py)
collects existing source-built IO.SYS, MSDOS.SYS and COMMAND.COM into an owned
workspace stage and directly compares each against both hash-checked retained
FAT12 media copies. The copies share the original baseline and are not
independent original-media evidence. All three comparisons passed; see
[evidence](evidence/m6-three-file-existing-candidate.json). This is not a new
integrated build or a boot test.

Review found `tools/build_command.py` still started DOSBox with a hidden window
rather than a private desktop. It now invokes the hash-pinned
`isolated-tool-runner.exe`, writes an owned configuration and host log, and
checks the batch marker. A mocked invocation checked command arguments, config,
marker and log; no DOSBox or GUI was launched. The old
`tools/link_command_reference.py` hidden-window experiment is disabled.
This change has not yet been exercised in a fresh build. The existing runner
source calls `CreateDesktopA` and supplies that desktop in `STARTUPINFO`, but
static inspection does not supersede the automatic approval rejection or prove
a new execution's isolation. Fresh builds and runtime remain pending.

All 15 BIOS link modules now have project-local `bios/*.asm` files. Eight
previously external comparative modules were copied byte-for-byte from the
retained exact-build input, with DOS 6 source provenance in
[source completion evidence](evidence/m5-bios-source-completion.json). A
static include scan found 44 additional source/include files used directly or
transitively (including conditionals); these are now under `bios/` or
`bios/inc/`, with [individual hashes and source paths](evidence/m5-bios-include-snapshot.json).
The separate `bios/inc/` avoids overwriting shared COMMAND or kernel includes
that have the same names but potentially different versions. Existing
`bios/copyrigh.inc` and `kernel-source/inc/versiona.inc` remain the canonical
inputs for those two names.

The candidate BIOS build script now overlays all 15 project-local modules and
these local includes. [Static verification](../../tools/verify_bios_local_inputs.py)
checks them against the retained exact-build stage and reports 15 modules and
44 includes; it does not execute the build or establish dynamic-include
closure. The DOS 6 tree, assembler/linker tools and message-generation inputs
are still build dependencies. This material is a reconstruction with restricted
reference provenance, not an assertion of original authorship or distribution
rights. The changed build recipe has not been run because of the existing
automatic approval rejection.

The BIOS candidate now has local copies of the prior build's `msbio.lnk`,
`msbio.skl` and NT `usa-ms.msg`, with hashes and reference paths in
[build-input evidence](evidence/m5-bios-local-build-inputs.json). The already
local `messages/usa-ibm.msg` matches the retained input. The exact files are
kept separate from COMMAND's similarly named message source.

`build_bios_comparison.py --candidate --oembase --singleconfig --local-source`
and `build_msload_candidate.py --local-source` are prepared to stage BIOS and
MSLOAD sources/includes from the project instead of copying the neighboring DOS
6 source tree. The MASM, linker, resource tools, DOSBox and isolated runner
remain external dependencies. The [static input audit](../../tools/verify_bios_local_inputs.py)
compares 15 BIOS modules, 44 BIOS include files, four build assets, MSLOAD and
its 13 discovered include references against the prior matching builds.
This does not prove dynamic include closure or that the new recipes execute;
no new build or GUI process was launched after the automatic approval
rejection. Source rights and distribution remain unassessed.

A reviewable integrated entry point is prepared at
`tools/build_integrated_source.py`. It invokes the local-source MSLOAD and
BIOS builders, the consolidated kernel builder, and COMMAND builder in order;
requires a new stage from each; checks component report hashes; compares all
three candidate files byte-for-byte against the hash-checked retained FAT12
media; and writes only to an owned `build/` stage after all comparisons pass.
It does not deploy to `O:\DOS` or claim original-media/runtime acceptance.
Pure in-memory comparison tests rejected missing or modified files; a fully
mocked four-builder test checked the orchestration, source flags and staged
output without launching any subprocess. The entry point has not been run
against the real toolchain. The existing automatic approval rejection for the
DOSBox execution path remains in force and was not bypassed.

A disposable FAT12 test image was prepared from a hash-checked retained media
copy, explicitly rewriting its IO.SYS, MSDOS.SYS and COMMAND.COM chains with
the existing source-built candidates and installing clean smoke scripts. All
three file contents were read back and no old result files existed; see
[preparation evidence](evidence/m6-integrated-vm-prepared.json). The original
image and `O:\DOS` configuration were not modified.

The supplied-product private-desktop helper returned exit 3 before creating a
private desktop or launching SoftPC; its two source branches for that code are
failure to open or query the input desktop. The image remained unchanged and
no guest results existed immediately after that attempt. See
[attempt evidence](evidence/m6-integrated-product-attempt.json); it is not a
product boot result.

The independently executed existing headless SoftPC core probe returned zero
and booted the same disposable candidate media. Guest artifacts show DOS 5.00,
environment, PATH, FOR, file copy/delete and child COMMAND markers, plus
`SMOKE-PASS` and `FINISHED`; all three system-file hashes remained unchanged.
See [headless evidence](evidence/m6-integrated-headless-runtime.json) and its
[verifier](../../tools/verify_integrated_headless.py). The probe uses neighboring
SoftPC core objects, not the supplied product binary; it does not replace a
fresh integrated build, original-media revalidation or product runtime test.

A diagnostic DOS COM program was assembled from
`tests/dos/dpbfat.asm` using the native console NASM; the tool, source and
output hashes are in [probe build evidence](evidence/m6-dpbfat-probe-build.json).
A new disposable disk explicitly carries the three existing source-built
candidates, the diagnostic and clean startup scripts. The headless SoftPC core
probe ran it to completion. INT 21h/AH=32h returned matching A: and default
DPB pointers, the expected drive, sector-size and FAT-count fields, and FFh
for invalid drive 27. The guest wrote and reread 2048 bytes, comparing the
whole buffer. Independent FAT12 inspection found the expected byte pattern,
four clusters, equal FAT copies and unchanged system-file hashes. See
[runtime evidence](evidence/m6-dpbfat-headless-runtime.json) and
[verifier](../../tools/verify_dpbfat_headless.py). This exercises the Get-DPB
call chain and a bounded FAT file operation; it is not full FAT coverage, a
fresh build, original-image validation or a supplied-product runtime result.

A local source-only package candidate was assembled from the current BIOS,
consolidated kernel and COMMAND trees, their required local include/message
inputs, and selected build scripts. Historical `COMMAND.COM`, `.exc`, `.map`
and other system/tool binaries are excluded. The package retains
`kernel-source/` and `bios/inc/` as documented layout departures to avoid
mixing incompatible include versions. It does not include the original media,
fixed target extracts, historical tool binaries, or the compiled private-desktop
runner. Its recipes still refer to external tools and pinned comparison media.

The [package manifest](evidence/m6-source-package-candidate.json) records all
323 source files and hashes; [static verification](../../tools/verify_source_package.py)
checks every entry, excludes binary artifacts and verifies the link-list module
names. The package has not been built or booted, and its dynamic dependency
closure, source provenance and distribution rights remain open. The existing
DOSBox execution approval rejection was not bypassed.

A static host-call signature audit now covers the retained exact-build OMF
objects for all three components, rather than only the earlier kernel probe.
The parser checks OMF record checksums, expands nested LIDATA and scans final
emitted segment bytes for `C4 C4`. It found zero matches in 55 MSDOS objects
(34828 emitted bytes), 15 BIOS objects (31216 bytes), the MSLOAD object (1446
bytes), and 34 COMMAND objects (45600 bytes). COMMAND's RDATA has two
conflicting record-order overwrites, explicitly counted; the audit uses the
last emitted value and does not claim independent linker-semantics proof.
Evidence: [kernel](evidence/m4-t5-exact-kernel-bop-audit.json),
[BIOS and MSLOAD](evidence/m5-bios-exact-bop-audit.json), and
[COMMAND](evidence/m3-command-exact-bop-audit.json). The current kernel's 126
source inputs and the local BIOS inputs were checked against their retained
build stages; the COMMAND audit concerns the retained objects and does not
establish a current source snapshot. These scans do not exclude non-BOP host
interfaces, address-fixup effects or prove runtime behavior.

The current 34 COMMAND source modules named by the link list and four staged
link/message assets compare byte-for-byte with the retained exact build. See
[local input audit](evidence/m3-command-local-source-audit.json). The earlier
build read shared include files in place without snapshotting them, so this
check cannot establish that those includes are unchanged; a clean build is
still required. This narrows, but does not close, the COMMAND source-identity
limitation in the exact-object BOP audit.

The local BIOS class-3 message source is now checked independently against the
numbered MSBIO entries in the NTIO `usa-ms.msg` source. All 15 messages expand
to the same bytes as their reference entries, and their 472-byte concatenation
matches the exact linked BIOS and target interval at 7B14h. The
[verifier](../../tools/verify_bios_message_source.py) reads only source and
existing build/target evidence; it does not feed target bytes into a build.
See [message-source evidence](evidence/m5-bios-message-source-verification.json).
This is a bounded resource-provenance check, not a fresh build or full resource
history determination.
