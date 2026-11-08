# M4 T5 S2 initial DOSINIT recovery

The target header E9 displacement points to file offset 31145. Its first
instructions are CLI, CLD, PUSH DX/SI/DS/DI, MOV BX,ES. OpenNT used INVOKE DOCLI.
DOS 6 msinit.asm also uses native CLI. Local dos/msinit.asm now uses CLI.

After copying DOSDATA and swapping segment registers, the target immediately
stores DI/BX into the BIOS communication pointer. OpenNT instead performs DEM
drive discovery, debugger symbol registration, DTA/error/VDM/command host
registration before those stores. The target's consecutive instruction stream
contains none of that block. The corresponding bounded block was removed from
the OpenNT-based local source; subsequent initialization remains unchanged.
This does not establish that drive initialization is complete: real DOS device
and disk initialization paths still need reconstruction elsewhere.

Clean build m4-t5-init-recovery-build.json succeeds, producing 27746-byte
intermediate SYS, SHA-256
446dc0969301fedd6bac6cefdccf0ff2adec7979f690c5558d68f661391da3be.
The unmodified reference build/report remains retained separately.

tools/verify_kernel_init.py derives both entry locations from the file header,
checks the exact eight entry bytes, and compares the first 88 bytes. Twelve
explicit word operands (addresses and data length) remain unresolved and are
reported individually rather than silently accepted. All other bytes match.
The full 88-byte prefix is NOT exact. This is instruction-structure evidence,
not whole-function, kernel or runtime equivalence. Evidence:
m4-t5-init-prefix-verification.json. No recovered kernel was booted or deployed.

The target initialization operands independently constrain layout: ORG 3DD0h,
memstrt BC77h, paragraph-aligned data start BC80h, DOSDATA length 1362h.
Thus data starts at file offset 7EB0h; adding 1362h gives 9212h = 37394 bytes,
exactly the target length. These are inferred segment boundaries backed by
initialization instructions and file length, not a target linker map.

Similar-issue sweep: other DOCLI invocations remain in msdisp.asm and other
host calls remain throughout the kernel. They are deliberately not blanket
replaced; each needs target-path evidence. S2 remains active for wider layout
and recovery work.

## ORG constraint follow-up

The local origin.inc calculates PARASTART as the paragraph-rounded sum of
0700h, BIODATASIZ, BIOCODESIZ and DOSDATASIZ, less 40h. Target PARASTART
3DD0h therefore constrains the three size constants' sum to 3701h..3710h,
inclusive; rounding prevents deriving a unique sum. The target's copied data
length 1362h is established by DOSINIT, but it has not been shown to equal
the DOSDATASIZ constant used in the ORG calculation. Consequently neither
individual BIOS size nor the original three constants can yet be inferred.
origin.asm and mshead.asm both consume PARASTART, and origin.inc is shared;
altering a shared size constant without resolving its consumers would create
an unsupported reconstruction. The observed header value remains a target
constraint for the next build-layout investigation, not a recovered constant.

## DOSDATA-only alignment

tools/compare_kernel_data.py reads the candidate DOSDATA bounds from its actual
linker map and the target bounds from DOSINIT's inferred layout. The candidate
data is 5602 bytes versus the target's 4962. A greedy monotonic comparison found
21 unique identical blocks of at least 16 bytes, totaling 4360 bytes. Their
offsets and hashes are in m4-t5-data-anchors.json. They are alignment candidates,
not proof of field identity or completeness. In particular, the 1331-byte and
648-byte matches previously listed as whole-file anchors are within DOSDATA;
their nearest preceding DOSCODE public names are not function attribution.
This narrows the next investigation to data layout and NT-specific additions;
it does not justify deleting unmatched bytes without source-level evidence.

## DOSDATA NTVDM pointer recovery

The MASM listing places an NTVDM `DosWowDataStart` pointer at DOSDATA:0090,
immediately before JShare. DOS 6's corresponding source has no such pointer.
The target's subsequent 587-byte exact block starts at data offset 00CAh;
before this change the candidate block started at 00CCh. Removed only the
two-byte NTVDM pointer from dos/msconst.asm. A clean isolated-tool build
(m4-t5-data-recovery-build.json, stage kernel-clean-4cb34gcv) succeeds.
The same 587-byte block now begins at 00CAh in both candidate and target;
JShare moves 0092h to 0090h, and the linked user_SP offset moves 0586h to
0584h, matching the target initialization instruction's stored offset.
The JShare pointer values themselves remain different and are not asserted
equal. Total candidate DOSDATA length remains 5602 bytes, so this does not
claim overall size convergence; padding or other layout changes require analysis.

## Current DOSDATA suffix alignment

compare_kernel_data.py now accepts explicit build and report names. Re-running
it against m4-t5-data-recovery-build.json finds 18 unique monotonic blocks,
4493 bytes total; exact block totals are heuristic and not a completeness score.
Evidence: m4-t5-data-anchors-current.json. The final 147 bytes match exactly:
candidate DOSDATA offset 154Fh corresponds to target offset 12CFh, a difference
of 280h (640 bytes), equal to the complete DOSDATA size difference. The candidate
listing identifies that suffix as beginning with DOSP1_ID after lmstub.asm ends.

The intervening candidate area contains NT-specific vheVDM, SCS buffers,
FAKE_NTDPB, NetCDS, DOSWOWDATA and virtual-interrupt routines, but also EXEC
header storage and other data. Several remaining kernel modules reference those
NT fields. The matching suffix establishes an alignment constraint, not proof
that one contiguous 640-byte source block can be deleted. Restore callers and
classify individual declarations before removing them.

The bounded lexical reference inventory is now reproducible with
`python tools/kernel_nt_data_refs.py`; m4-t5-nt-data-references.json records
line-level occurrences and source hashes for 17 selected NTVDM symbols. It
includes declarations and inactive conditional branches, so it is not an
active call graph. In particular NetCDS appears in macro.asm's redirected-drive
path, FAKE_NTDPB in misc.asm, vheVDM in msctrlc.asm, and DOSWOW state also has
initialization references. DOS 6 places EXEC header fields in dostab.asm, which
reinforces that those fields cannot simply be removed with adjacent NT state.
These references provide a concrete caller-by-caller recovery order; no further
source deletion or binary identity is claimed by this inventory.

## Get-DPB caller reconnaissance

The target contains a candidate $GET_DEFAULT_DPB entry at file offset 0F94h:
`B2 00 16 1F 8A C2 E8 EF 5C 72 22 C4 3E A2 05 26 F6 45 44 80 75 17`.
It shares the default-drive setup and network-CDS test with both reference
sources. After that test it calls three near routines, checks carry, and stores
BP and ES to the user stack. This instruction shape agrees with the DOS 6
source's critical-section / FATRead_CDS / critical-section sequence, while
OpenNT instead invokes HRDSVC with FAKE_NTDPB and returns DI and SS.

This is a strong mapping candidate, not yet a complete verified replacement:
the three call destinations and their target semantics remain to be mapped,
and FATRead_CDS and its dependencies are absent from the current OpenNT link
list. Restoring only the caller would leave unresolved symbols and omit media
checking, so no speculative source edit was made. The candidate signature
also occurs at 0F50h in another drive-related routine; the network-CDS test
and following return-register sequence distinguish the 0F94h candidate.

Follow-up: decoding the three E8 relative calls at 0FAAh, 0FADh and 0FB0h
gives target file offsets 1356h, 5899h and 1376h respectively. The first and
third destinations begin with nearly identical instruction sequences and
contain INT 2Ah with AX=8001h and AX=8101h respectively, consistent with
enter/leave disk critical sections. At 5899h the bytes begin `06 57 26 C4 6D
45 26 8A 46 00`: PUSH ES, PUSH DI, LES BP,ES:[DI+45h], MOV AL,ES:[BP].
This matches the initial operations of DOS 6 FATREAD_CDS, including loading
the CDS device pointer and DPB drive byte. These are bounded instruction-level
correspondences, not proof of the entire function or its dependency graph.
The initial GETTHISDRV and later get_user_stack calls resolve to 6C8Ch and
04A5h respectively. All offsets are file offsets, not segmented addresses.

FAT dependency work: tools/probe_fat_dependencies.py compiles DOS 6 fat.asm
against the local kernel headers in owned scratch. Native OpenNT CDS lacks
CURDIR_DEVPTR and CURDIR_ID, causing six assembly errors. A scratch-only DOS 6
curdir.inc override resolves all errors and yields object SHA-256
2f2f50581dd06cf6e239cc0bb7d1580eadf9fdc43117b4ef126ff7f507dfe6f0.
The OMF EXTDEF records enumerate 37 external dependencies, including GOTDPB,
GETBUFFRB, BUFWRITE, DEVIOCALL2, HARDERR and buffer state. These require symbol
resolution and target verification before integration. Both unsuccessful and
successful probes are retained in m4-t5-fat-dependency-probe.json and
m4-t5-fat-full-cds-probe.json. Shared headers and production link order were
not changed; the override establishes a concrete missing structure dependency,
not proof that the entire DOS 6 FAT implementation matches DOS 5.

FAT EXTDEF resolution against the actual current map finds 31 names present
and six missing (m4-t5-fat-symbol-resolution.json). Five are buf.asm routines:
ScanPlace, GetCurHead, INC_DIRTY_COUNT, GETBUFFRB and BUFWRITE. GOTDPB survives
inside OpenNT mscode.asm's disabled GETBP block. The target FATREAD_CDS call at
58A6h resolves to file 060Bh, whose nine bytes are 892E8A058C068C05C3.
Correction: the earlier narrative incorrectly recorded this call site as 5906h;
the executable regression now asserts opcode E8 and decodes displacement AD62h
at 58A6h directly from the pinned target. The callee attribution is unchanged.
Re-enabled only GOTDPB as a separate procedure, leaving GETBP disabled.
Clean build m4-t5-gotdpb-build.json succeeds; the linked nine-byte body is
exactly identical, including both THISDPB addresses, to that target routine.
Evidence: m4-t5-gotdpb-verification.json. Position differs and no whole-kernel
identity is claimed. Existing external names still require semantic review;
FAT is not yet linked and the five buffer routines remain outstanding.

Buffer follow-up: tools/probe_buf_dependencies.py assembles DOS 6 buf.asm in
owned scratch against current local headers with no override and no errors.
Object hash: 674106c12dcab33f45e021234c53086e74b2d535c3b09293242e9a445127c374.
Its 20 EXTDEF names include three absent from the current linked kernel:
FATSECRD and DREAD are defined in DOS 6 disk.asm; DWRITE in disk2.asm.
The other 17 names resolve, but this does not prove semantic compatibility.
Probe and resolution reports retain the exact source/tool/object/map hashes.
This establishes the next concrete dependency boundary rather than providing
fake implementations: disk I/O and its target correspondence must be recovered
before the real FAT/Get-DPB path can be integrated. No production link-order
change or target-byte equivalence for buf.asm is claimed yet.

Disk comparison probes now cover both disk.asm and disk2.asm. The first
assembles against current headers; the second reports exactly two undefined
fields, SF_LSTCLUS and SF_CLUSPOS, in SETCLUS. Both fields exist in DOS 6's full
SFT and represent last cluster accessed and its position. A scratch sf.inc
override resolves the assembly errors; the resulting disk2 object hash is
0350f17462dbd38c5619893d7abd6da875bdb8868f40df43633863107e88fefb.
Reports preserve source/header/tool hashes and EXTDEF records. This adds SFT
restoration to the CDS prerequisite. Successful assembly does not establish
compatible structures across the separate probes or target implementation
identity. No mixed-header objects were linked into the production kernel.

Unified comparison group now compiled by tools/probe_storage_group.py:
fat, buf, disk, disk2 and disk3 all assemble with one scratch full CDS/SFT
header pair. All OMF record checksums are validated before reading external and
public definitions. m4-t5-storage-group-probe.json records inputs, tool, object
hashes and full symbol sets. Against the group and current kernel map, 14 names
remain unresolved: ALLOCATE, BUFRD, BUFWRT, DOS_COMMIT, FIGREC, FNDCLUS,
FastOpen_Update, LOCK_CHECK, LOCK_VIOLATION, NEXTSEC, OPTIMIZE, RELBLKS,
RELEASE and SKPCLP. Ten have DOS 6 definitions in rom.asm (ordinary cluster
and file routines despite that filename), two in lock.asm, and one each in
close.asm and delete.asm. Existing symbols can still be NT-specific implementations;
name resolution alone does not prove behavior. No integrated executable or
production source substitution has been claimed for this comparison group.

Expanded group (`--expanded`) includes rom, lock, close and delete with the
same scratch headers. All nine modules assemble. It introduces 11 public-name
overlaps with the current kernel, including DOS_READ, DOS_WRITE, SETSFT and
$LOCKOPER; these require source-path replacement, not additive linking. The
remaining unresolved names include directory traversal, DOOPEN, SHARE entry/
exit, DATE16, media-ID and patch data. m4-t5-storage-expanded-probe.json retains
the exact sets and objects. This is not a completed storage recovery.

GetCurHead target probe: the full 18-byte instruction pattern from the compiled
BUF listing has one occurrence, file offset 23206 (5AA6h). Bytes:
36C53E6D0036C7061E00FFFF36893EBB0EC3. It loads a far pointer, invalidates a
word to FFFFh, stores DI and returns; the three memory operands are 006Dh,
001Eh and 0EBBh. They correspond structurally to BufferQueue, LastBuffer and
FIRST_BUFF_ADDR but field attribution still requires independent cross-checks.
tools/verify_getcurhead_target.py validates the target hash and uniqueness;
result is m4-t5-getcurhead-target.json. No broad byte-equality claim is made.

GetCurHead recovery continuation: the current linker map independently assigns
BufferQueue=006Dh, LastBuffer=001Eh and FIRST_BUFF_ADDR=0EBBh, the same operands
observed in the target. Added dos/buf.asm containing the bounded comparative
DOS 6 GetCurHead source slice (original lines 82-90), with origin noted in-file;
OpenNT remains the primary kernel source. Added buf.obj after fcb.obj in the
intermediate link list; final target link order is not claimed. build_kernel.py
now snapshots newly linked local module sources as well as imported inputs.

Clean build m4-t5-getcurhead-build.json yields 27762 bytes. The verification tool
uses the build hash and actual GetCurHead map address to compare its full
18-byte body, with no masked operands, against the unique target match.
All bytes match; candidate file offset 11518 differs from target 23206.
Evidence: m4-t5-getcurhead-verification.json. The remaining buffer module is
explicitly incomplete; no standalone FAT behavior or whole-kernel identity
is inferred from this routine recovery.

Queue recovery extends dos/buf.asm with comparative ScanPlace, PlaceBuf and
PointComp source. Clean build m4-t5-buffer-queue-build.json succeeds. The four
consecutive routines from GetCurHead through PointComp total 101 bytes and
match the target at file 23206 exactly, including addresses, calls and branches.
tools/verify_buffer_queue.py derives candidate start from the linker map and
end from MASM PointComp ENDP=0065h. An initial hand-counted 16-byte PointComp
length included the following module's first byte; it was corrected to the
assembler-derived boundary (PointComp itself is 15 bytes). This correction
does not mask any instruction bytes. Verification is recorded in
m4-t5-buffer-queue-verification.json. File position and the rest of the kernel
still differ; no runtime or complete buffering implementation claim is made.

Dirty-count recovery adds the comparative DOS 6 INC_DIRTY_COUNT and
DEC_DIRTY_COUNT procedures to local BUF. The existing linked DirtyBufferCount
symbol is 0071h, agreeing with the unique target increment pattern at 5D16h
and adjacent decrement routine at 5D1Ch. Clean build
m4-t5-dirty-count-build.json succeeds. verify_dirty_count.py compares the
complete 6-byte increment and 14-byte guarded decrement bodies, including
segment overrides, address words and the zero-test branch, without masking.
Both match exactly; m4-t5-dirty-count-verification.json records bytes and offsets.
The routines occupy different file positions in the candidate. GETBUFFRB and
BUFWRITE and their disk dependencies remain unreconstructed in production.

Cache-parameter continuation: imported the bounded SET_RQ_SC_PARMS operation
from comparative DOS 6 buf.asm, using the existing local DPB definitions and
SC_SECTOR_SIZE/SC_DRIVE symbols. PUSH/POP AX expand the source SAVE/RESTORE
macros equivalently. Target 0x5D03 contains the exact 19-byte routine, including
DPB offsets 2/0 and DOSDATA operands 0DADh/0DAFh. Clean isolated build
m4-t5-cache-parms-build.json yields 27890 bytes, SHA-256
4ab89a50319cfbc7953901cbd080b4b401a6415d1a7cfb6d0050d5a7d79dc367.

Reproduce with `python tools/verify_fat_chain.py`. It verifies pinned target,
candidate and linker-map hashes, uses assembler PROC/ENDP boundaries and
checks eight entire routines (149 bytes), including prior queue/dirty/GOTDPB
slices. All compare exactly with no masked operands. It additionally decodes
six E8 target call edges from audited sites. This caught the old 5906h typo;
the GOTDPB edge is actually 58A6h -> 060Bh. No target/candidate bytes were
changed to repair the report. These are static observations; named target
entry attribution remains comparative and the whole call chain is not run.

Reproduce the current external-name ledger with
`python tools/resolve_fat_dependencies.py --build m4-t5-cache-parms-build.json --report m4-t5-fat-current-resolution.json`.
35 of the comparative FAT object's 37 EXTDEF names resolve. GETBUFFRB and
BUFWRITE are the two remaining absent names. Full CDS/SFT and disk-I/O ABI
compatibility remain separate requirements; production FAT is still absent.

Full BUF candidate: dos/buf.recovery.asm preserves the comparative module
structure and all procedures, replacing only its HMA read-copy sequence with
the target sequence. In particular, the target POPF precedes MOV CX/SHR, has
no second PUSHF around the copy, and branches over the non-HMA POPF. This is
a target-fidelity change, not an attempt to adopt DOS 6's flag-preservation
behavior. The resulting module is one byte longer than the DOS 6 comparison.

tools/verify_full_buf.py assembles this candidate with local headers. It parses
checksummed OMF LEDATA and explicit OFFSET fixups, rejects unsupported forms,
verifies complete nonoverlapping module coverage, and records every resolved
symbol/offset. DOSDATA operands come from the pinned current kernel map;
internal DOSCODE fixups use the target module base. The three external near
calls use source-attributed addresses independently decoded at the target call
sites: FATSECRD at 5B91h -> 3837h, DREAD at 5B98h -> 3863h, DWRITE at 5CEAh
-> 38C5h. These prove address correspondence, not disk-routine implementation.

All 644 bytes at target [5AA6h,5D2Ah) compare exactly, SHA-256
81b7450c2bd236515ba523c97535dfc4474fd1be89bbbe8804885d08826df19b.
Report: m4-t5-full-buf-verification.json. GETBUFFRB is module offset 0067h,
GETBUFFR ends at 0164h, FlushBuf at 01A6h, CHECKFLUSH at 01CFh, BUFWRITE at
025Dh, and the remaining cache/dirty routines end at 0284h. The comparison
contains no opaque target-byte substitution, stubs, masked bytes or ignored
relocations. It is not a real integrated kernel link or runtime test. Keep
the existing bounded buf.asm linked until disk dependencies are recovered;
then replace it with this candidate rather than linking duplicate definitions.

Disk read/write wrapper recovery: extracted bounded comparative FATSecRd through
EndProc FATSecRd into dos/disk.read.recovery.asm, including the preceding shared
RET used by DREAD's retz. Extracted DskRead through EndProc HARDERRRW into
dos/disk2.io.recovery.asm. No SFT override is needed for these DPB/device paths.
The source retains calls to real named dependencies; no stub implementations.

The initial comparisons against the unchanged current DOSDATA map each failed
at one operand: ReadOp=0576h in current source versus 0575h in the target.
Retained reports m4-t5-disk-read-nt-layout-mismatch.json and
m4-t5-disk2-io-nt-layout-mismatch.json establish this failure. The target writes
zero at 3868h and one at 38CAh using 36 C6 06 75 05 xx. The harness now records
ReadOp=0575h as an explicit target-layout symbol assignment, retaining the
current-map value alongside it. This does not correct the production ABI.
Source inc/ms_data.asm currently allocates SecClusPos/Trans/ReadOp/ThisDrv
at 0574h/0575h/0576h/0577h; target disk SETUP also accesses Trans=0574h and
ThisDrv=0576h. The causal layout change has not yet been established.

Under that recorded layout, the complete 72-byte read slice and 114-byte
physical-I/O/error slice compare exactly; see m4-t5-disk-read-verification.json
and m4-t5-disk2-io-verification.json. Calls resolve through explicit symbolic
relocations to DSKREAD/HARDERRRW and SETREAD/SETWRITE/DEVIOCALL2/HARDERR;
the latter four remain external target-address attributions, not verified
implementations. The first slice includes one byte from the preceding routine
to preserve MASM return-sharing behavior; do not duplicate that byte when
restoring the whole disk.asm module.

Generalized the bounded OMF harness as tools/verify_storage_candidate.py:
`--module disk-read`, `--module disk2-io`, or `--module buf`. The existing
verify_full_buf.py remains a compatibility entry point. All three assemblies
and target-layout comparisons pass; BUF remains exactly 644 bytes with no
data-layout overrides. Candidate integration and runtime verification remain
outstanding, as do CDS/SFT restoration and complete kernel layout.

ReadOp root-cause repair: the OpenNT const2 baseline inserts vheDev SYSDEV
(18 bytes) at 03B1h; its shortened CDS is 71 bytes rather than the target's
88. The net +1 persists through the byte fields and is absorbed at the next
EVEN alignment, explaining why later user_SP/THISDPB already matched. Target
GetCDSFromDrv uses MOV BL,58h / MUL BL at 6CF3h. Target GetThisDrv stores
DummyCDS=04F3h at 6CA9h. These independent instruction operands agree with
removing the fake device and restoring the full CDS, rather than shrinking
or aliasing ReadOp itself.

Added kernel-only inc/kernel/const2.asm (OpenNT baseline minus vheDev) and
inc/kernel/curdir.inc (DOS 6 comparative full layout). The latter retains NT
TOSYNC/NT_FIX constants solely for still-unrecovered callers; their behavior
is not accepted as final DOS 5. Original shared inputs remain unchanged.
build_kernel.py snapshots these overrides; kernel include precedence selects
them. In dos/msctrlc.asm, restored the comparative HardErr prefix through
FATAL1, with DPB-based drive/device pointers and transfer/error-region logic.
This removes all production references to vheDev while leaving later NT
INT24 seams for explicit subsequent recovery.

Clean isolated build m4-t5-cds-harderr-build.json passes. The linked prefix
[HARDERR,FATALC) is 98 bytes and equals target [54AAh,550Ch) with no relocation
masking. verify_cds_harderr.py derives its bounds from the assembler listing,
checks target CDS instructions and linked data offsets, and verifies existing
COMMAND source snapshot inputs unchanged. Production DummyCDS is now 04F3h,
ReadOp=0575h, Trans=0574h and ThisDrv=0576h, while user_SP=0584h and
THISDPB=058Ah remain correct. Evidence: m4-t5-cds-harderr-verification.json.

The storage harness now uses the corrected production map and asserts ReadOp
already equals 0575h; it no longer assigns a substitute address. All three
candidate comparisons pass with empty data_layout_differences. Earlier failing
NT-layout reports remain historical evidence. Full kernel identity and runtime
behavior are still unproved; full storage linking, SFT and NT INT24/path seams
remain work, not implied completion from this prefix match.

Device-tail recovery and storage integration: the comparative DEVIOCALL through
SC2BUF tail matches target [47DFh,4A3Ah), 603 bytes. The initial comparison
exposed NT EnterCrit/LeaveCrit macros expanding to no instructions; explicit
invoke EcritDevice/LcritDevice restores the target calls at 47E2h and 485Ah.
The actual comparative names are EcritDevice/LcritDevice, replacing earlier
descriptive EnterCritDevice/LeaveCritDevice labels used only in attribution.
The comparative crit.asm's four handlers match all 128 target bytes at 1356h.
Reports: m4-t5-dev-io-verification.json and m4-t5-crit-verification.json.

Installed these proven sources into the current kernel: dev.asm retains its
OpenNT-derived earlier routines and gains the recovered tail; buf.asm gains
the full recovery; disk2.asm contains the physical wrappers; diskread.asm is
a documented temporary module for FATSECRD/DREAD plus shared preceding RET;
crit.asm supplies critical sections. msdos.lnk includes the new units. Frozen
*.recovery.asm files remain comparison inputs and are not duplicate link units.

Two clean isolated builds produce the same 29282-byte output, SHA-256
f843203d4b24eca1f8ca45ea094f13405c90d4d9f63f42af2e78dfd26c11b9a2.
The final source-comment cleanup is reflected in m4-t5-storage-linked-build.json;
the first is retained as m4-t5-storage-first-linked-build.json. All current
snapshot files and previously frozen COMMAND input files match their hashes.

tools/verify_linked_storage.py verifies actual linked slices, not just scratch
comparison objects: BUF 644, disk read 72, disk2 I/O 114, device tail 603, CRIT
128 bytes (1561 total). For the 12 enumerated external E8 calls it decodes the
actual destination and requires the linker map's named symbol; it then derives
the expected displacement for this layout. Every other byte must match the
target slice unchanged. All pass. Raw equality is separately false for the
four relocated slices and true for CRIT, so this is explicitly not a claim of
target-layout or whole-file identity. Report m4-t5-linked-storage-verification.json.

Rechecked the comparative FAT object's externals against the new production
map: 37/37 names resolve (m4-t5-fat-linked-resolution.json). This removes the
missing-name barrier; FAT implementation, callee semantics, SFT compatibility,
remaining NT seams and actual disk-I/O runtime remain required work.

FAT recovery: the unmodified comparative DOS 6 fat.asm, assembled with current
kernel full CDS headers, matches all 984 target bytes at [56CEh,5AA6h) after
explicit target-layout relocation. Source/object/map/reference identities and
all relocations are in m4-t5-fat-verification.json. The OMF resolver needed one
additional strict form: external frame and external target with identical
index (26h), used by pre-segment declarations GetCurHead/ScanPlace. It accepts
only that equality and named code targets, not a generic unknown-fixup bypass.

Imported this proven module as dos/fat.asm and added it before BUF in the
intermediate link list. Restored misc.asm's complete Get-DPB procedure from
the comparative source using explicit EcritDisk/LcritDisk invokes, since the
NT critical macros are disabled. Get-DPB now calls FATREAD_CDS and returns
BP/ES in user BX/DS instead of the host-service-generated DI/SS fake DPB.

Clean isolated build m4-t5-fat-getdpb-build.json succeeds, 30258 bytes, SHA-256
2a2069afd7cdcabbcd32f390438614fc26ca71dad2c00368835098cf1fcffda3.
Extended verify_linked_storage.py with --build/--report arguments and the full
FAT plus assembler-bounded Get-DPB slices. Reproduce with:
`python tools/verify_linked_storage.py --build m4-t5-fat-getdpb-build.json --report m4-t5-fat-getdpb-verification.json`.
All 2593 bytes across seven slices correspond, with 35 explicitly verified
external calls; target-versus-linked displacement differences are retained
as raw inequality, not called exact full-file reproduction. Get-DPB itself
is 48 bytes including its error return. Snapshot checks find no changed build
inputs and no changed previously frozen COMMAND inputs.

This is integrated static evidence only. In particular dos/macro.asm still
uses NT_FIX/TOSYNC flags and SVC_CMDGETCURDIR in the CDS construction/sync path.
Real CDS DPB pointer initialization is not proved by merely restoring the
88-byte structure. Next recovery must address this path and startup, along
with the still-incomplete SFT/file and NT INT24 handling; no boot claim is made.

CDS construction/lookup recovery: restored comparative FIND_DPB and InitCDS
in the OpenNT-derived macro.asm, adding its DPB include and DPBHead external.
FIND_DPB walks dpb_next_dpb by drive number; InitCDS bounds the physical drive,
sets root path/ID/end fields, and stores the real DS:SI DPB pointer. Replaced
GetCDSFromDrv's NT global/remote sync and SVC_CMDGETCURDIR branches with the
target CDSCount bounds check, 88-byte indexed lookup and ThisCDS assignment.
Retained unrelated macro routines and NT seams for separate verification.

Clean isolated build m4-t5-cds-path-build.json succeeds, 30178 bytes, SHA-256
710b89a7684e702913a51ea53dec1ee43e50967eb1d3b207ac7c6ca2c2160538.
The actual linked FIND_DPB/InitCDS slice exactly equals target 6BB8h..6C1Ah
(98 bytes, no displacement adjustment). GetThisDrv through GetCDSFromDrv
matches the target 6C8Ch..6D07h (123 bytes), with only the verified InitCDS
external call displacement adjusted to the current layout. Combined regression
now covers 2814 bytes and 36 external calls. Run verify_linked_storage.py with
--build m4-t5-cds-path-build.json --report m4-t5-cds-path-verification.json.
Current source snapshots and existing COMMAND input snapshots remain intact.

Follow-up audit found a separate upstream dependency in msinit.asm: after
initializing the clock, its perdrv loop still treats subsequent devices through
charinit and continit invokes SVC_DEMGETDPBLIST. Therefore restoring InitCDS
does not yet prove a real startup-built DPBHead chain. This block-device/DPB
construction is the next concrete recovery target. path.asm CurrentValidate
still invokes SVC_DEMQUERYCURRENTDIR and checks NT_FIX, independently of the
now-restored GetCDSFromDrv; retain this as a distinct remaining NT seam.

Startup physical-DPB recovery: target perdrv starts at 7AC3h and reaches
continit at 7B45h, then terminates the final DPB link through 7B55h. Replaced
the abbreviated NT device loop and SVC_DEMGETDPBLIST path with the comparative
DOS 6 perdrv/perunit/continit block. It filters character devices, reads the
returned unit count/BPB array, assigns logical drive and physical unit,
invokes $SETDPB, updates MAXSEC/NUMIO, stores DPB links/device headers and marks
first access. Target DPBSIZ is 21h; both link fields terminate at FFFFh.
The reference's ROMDOS conditional remains inactive in this build. No opaque
DPB-list binary or host substitute was introduced.

Clean isolated build m4-t5-dpb-init-build.json yields 30290 bytes, SHA-256
1bea04a82fae7cfd663cb7c95578e00f25eadcd451cca3db4ff08f125b08ca8c.
Extended verify_linked_storage.py --init to derive local perdrv/continit/
charinit addresses from the listing relative to linked DOSINIT. The 146-byte
perdrv block and 40-byte charinit match their target slices except for three
explicitly decoded calls to charinit/$SETDPB/DEVIOCALL2, whose actual linker
destinations all agree. The rest of each slice, including all internal branches
and data/structure operands, matches without exemptions. Aggregate regression
is 3000 bytes and 39 named external calls. Report:
m4-t5-dpb-init-verification.json. Source and COMMAND snapshot checks pass.

This replaces the identified DPB-list host call but does not establish complete
startup. $SETDPB behavior, earlier startup operands/data placement and BIOS/CDS
table setup still require whole-path review, alongside remaining path validation,
NT error and SFT/file operations. Runtime boot is not yet claimed.

$SETDPB audit found the OpenNT public entry was an NT SCS multiplexer before
real_setdpb. It handled console allocation/freeing, TSR/prompt/DOSONLY flags
and NT-handle queries when BP/SI were zero. Removed that dispatcher and its
obsolete API description; the retained OpenNT real_setdpb body is now the
direct $SETDPB procedure, with EndProc at the actual conversion return.
The preceding word3 constant remains source-defined as DW 3. No DOS 6 1992
FAT-size overflow fix was imported: the retained body matches the DOS 5 target.

Clean isolated build m4-t5-setdpb-build.json produces 29970 bytes, SHA-256
a83b0f5a74b58e178676ca016e3f3d4d945c12baf5b667b1164575dd819de554.
verify_linked_storage.py --setdpb derives the full 200-byte procedure length
from PROC/ENDP and includes the preceding two-byte constant. All 202 target
bytes at [0FF7h,10C1h) correspond except for the named CS:word3 relocation.
The DIV instruction at target 10A4h is required to be 2E F7 36, its original
operand must address target word3, and the actual linked operand must address
the actual word3, whose value is checked as 3. No mismatching byte is ignored.

Run with --build m4-t5-setdpb-build.json --report m4-t5-setdpb-verification.json
--init --setdpb. All 3202 bytes, 39 external calls and the constant reference
pass. Source/COMMAND snapshot checks pass. The build remains an incomplete
kernel; the static conversion match does not establish boot or filesystem
runtime behavior, and remaining NT startup/path/INT24/SFT seams persist.

Segment reinitialization: target [7CE7h,7D70h) has no NT debugger symbol move
callback. Removed the SCS_ISDEBUG/SVC_DEMSYSTEMSYMBOLOP block and restored the
direct JNE patch_vec_seg. First assembly failed with branch range +5; the
listing showed get_cpu_type injecting an NTVDM/MIPS BIOS-state check before
native FLAGS detection. Scoped inc/kernel/cputype.inc now uses comparative
DOS 6 native detection, preserving shared COMMAND headers. The failure stage
kernel-clean-vnn908kw retains its diagnostic; no binary from it was accepted.

Clean build m4-t5-segreinit-build.json yields 29922 bytes, SHA-256
28853145a2f43b0cd9f742d95a2d2ec799f235d433af3a273e6fcefe290db1f5.
verify_segreinit.py derives the complete 137-byte PROC/ENDP boundary and checks
every byte, resolving 17 explicitly named operands through map/listing/header
identities. Six are near calls; the rest are code/data symbols. Raw equality
is false and remaining data-layout mismatches are expressly retained:
DOSINTTABLE=1040h versus target 1062h, DosHasHMA=11D9h versus target 1211h,
and corresponding HMA patch pointers. No corrected data layout is implied.
Report m4-t5-segreinit-verification.json has no unexplained instruction bytes.

Existing storage/startup/SETDPB regression passes against this build in
m4-t5-segreinit-storage-regression.json; snapshot checks pass for current
kernel and previously frozen COMMAND inputs. Call-relative differences show
patch_misc_segments starts at the expected relative distance but patch_offset
and patch_in_nops are each 30 bytes later than the target correspondence.
Inspect the intervening patching code next; none of these static results proves
boot, full initial data correctness or whole-file identity.


Patch-misc continuation: removed the NT-only DosWowDataStart segment patch
block (one pointer load and nine segment stores, 30 code bytes) from msinit.asm.
Clean isolated build m4-t5-patchmisc-build.json yields 29890 bytes, SHA-256
f8431a161a9eb8e5d75be1ea853648f4503d48780fffb897151032dca28b00f8.
The file shrank 32 bytes because of alignment; the removed code is 30 bytes.

verify_segreinit.py --build m4-t5-patchmisc-build.json --report
m4-t5-patchmisc-verification.json --patchmisc verifies the entire 81-byte
patch_misc_segments at target [7DB3h,7E04h): raw byte equality is true,
including all six checked data-symbol operands. The 137-byte seg_reinit
still corresponds with explicitly enumerated symbols; all six near-call
displacements now equal the target. Its DOSDATA/HMA layout differences remain.

verify_linked_storage.py --build m4-t5-patchmisc-build.json --report
m4-t5-patchmisc-storage-regression.json --init --setdpb passes for 3202 bytes,
39 named external calls and the word3 reference. All 111 current kernel inputs
match this build snapshot; all 113 frozen COMMAND inputs remain unchanged.
No runtime or whole-file identity is claimed. Next audit remaining startup
data/layout and physical path validation, then outstanding NT INT24/SFT seams.


Current-directory continuation: recovered the retained OpenNT ValidateCDS
body as dos/validatecds.recovery.asm. Its complete 190 bytes [43CBh,4489h)
match the target with explicit OMF symbol resolution. Reproduce with:
python tools/verify_storage_candidate.py --module validatecds
This is target-layout candidate proof, not integration or runtime proof.

Integration exposed missing DOS_ChDir and then GetPath (excluded by ifdef 0
in dir2.asm). No dummy implementations were accepted. Formal path.asm,
dir2.asm and msdos.lnk were restored to the patchmisc build snapshot; all
111 kernel and 113 frozen COMMAND inputs match. Latest accepted kernel is
still m4-t5-patchmisc-build.json, 29890 bytes. Unaccepted experiments remain
in path.currentdir.recovery.asm and dircall.recovery.asm; the latter has a
temporary adjacent error tail and is not target-layout equivalent.

Evidence: m4-t5-currentdir-dependency-audit.json records source provenance,
failed build stages, candidate hashes and snapshot checks. Next recover the
physical GETPATH/directory-search dependency closure, then integrate the
CurrentValidate/ValidateCDS/DOS_CHDIR chain. Full binary/runtime work remains.


Physical GetPath continuation: dos/getpath.recovery.asm restores retained
OpenNT GETPATH/ROOTPATH/FINDPATH code and its adjacent helper procedures,
including the omitted DATE16 call in Build_device_ent. Full target interval
[4071h,43CBh), 858 bytes, matches after explicit OMF symbol resolution.
fastpath.recovery.asm restores retained LookupPath/InsertPath with dpb.inc;
all 296 bytes at [44CEh,45F6h) match. Commands:
python tools/verify_storage_candidate.py --module getpath
python tools/verify_storage_candidate.py --module fastpath

These add 1154 target-layout candidate bytes, not linked/runtime coverage.
m4-t5-getpath-closure-audit.json records primary source identity and external
symbol inventory. Physical dir.asm is absent from the OpenNT source directory;
comparative DOS 6 dir.asm supplies the next SEARCH/FindEntry/GETENTRY/
SETDIRSRCH/SETROOTSRCH candidate. SET_BUF_AS_DIR and transitive disk helpers
also need restoration. dir2.physical.recovery.asm remains an exploratory
assembly candidate with NT remnants, not a production replacement. All 111
production kernel and 113 frozen COMMAND inputs still match their snapshots.


Directory-search production integration: added full comparative dir.asm
(433 bytes), bounded FIGREC in rom.asm (44 bytes), and DirRead/FIRSTCLUSTER/
SET_BUF_AS_DIR before existing diskread.asm routines. The 115-byte DirRead
proof includes the preceding shared RET and trailing RET shared with the old
FATSecRd/DREAD proof. Initial link exposed STARTSRCH still inside ifdef 0;
moved its retained 20-byte body outside that conditional, matching target.

Clean isolated build m4-t5-directory-build.json: 30498 bytes, SHA-256
3ecfc3d1381f378e619a0d18b2538d79799616b3c27d34b72a14ba5c317f952e.
Actual-link regression m4-t5-directory-verification.json passes: 3813
unique target bytes (3814 summed slice bytes, one overlapping RET),
50 external calls and SETDPB word3 reference. Segment initialization and
patch_misc regression also passes (m4-t5-directory-segreinit-regression.json).
Kernel/COMMAND snapshot checks pass; see m4-t5-directory-integration-audit.json.

Bounded rom.asm and diskread.asm are temporary departures from the final DOS 6
module layout, to merge as surrounding procedures are recovered. GetPath,
FastOpen and ValidateCDS remain proven candidates, not yet integrated; DATE16
and complete DOS_CHDIR/error paths remain next. No standalone boot or whole
binary identity is implied by these static source and link checks.


Time/GetPath production continuation: restored complete comparative time.asm.
Its 483-byte target [0A5Ch,0C3Fh) includes all four date/time APIs, DATE16,
READTIME and calendar conversion. It uses BCLOCK device requests through the
restored SETREAD/SETWRITE/DEVIOCALL2 chain, removing NT date services and NT
BIOS-tick conversions. Full target-layout proof: m4-t5-time-verification.json.
The resolver explicitly checks DosDseg references against DOSCODE header +7.

Enabled retained physical GetPath and FastOpen blocks in dir2.asm, included
dpb.inc and restored DATE16. Existing CurrentValidate/ValidateCDS entry paths
are not yet switched; CheckThisDevice also retains its separate NT seam.
Clean isolated build m4-t5-time-getpath-build.json: 31714 bytes, SHA-256
6f05f0ffe5f9926d1394086c08cbac422892aecbb876a797e0dd7e34c768c60f.
Actual-link regression passes for 5430 unique target bytes
(5451 summed slice bytes with overlaps), 77 external
calls, two time-module DosDseg references and SETDPB word3. Report:
m4-t5-time-getpath-verification.json. Segment/patch-misc regression passes.
All kernel and frozen COMMAND source snapshots match; see
m4-t5-time-getpath-integration-audit.json. Next connect CurrentValidate and
ValidateCDS with DOS_CHDIR/shared error handling; full identity/boot remain open.


Current-directory production chain: restored $CURRENT_DIR from the audited
comparative procedure, replacing SVC_DEMQUERYCURRENTDIR/NT_FIX and the NT-only
UCase calls with physical validation. Restored retained OpenNT ValidateCDS
body by removing its early CLC/RET and conditional exclusion. Added bounded
DOS_CHDIR with shared access-denied return. The linked path now reaches
FATRead_CDS, DOS_CHDIR and the restored GetPath/physical directory machinery.

Clean isolated build m4-t5-currentdir-linked-build.json: 32002 bytes, SHA-256
5cc8c662dba687a49905c61570dacc38f5eeeb324541676fd04cd5392664602e.
Actual-link report m4-t5-currentdir-linked-verification.json checks full
$CURRENT_DIR (121), ValidateCDS (190), DOS_CHDIR (69), shared error body (8),
and previous slices: 5818 unique target bytes, 94 named call edges,
3 named branches, explicit header/constant references. Source snapshots
and segment/patch-misc regressions pass. Audit: m4-t5-currentdir-linked-audit.json.

Explicit exception outside those byte-corresponding slices: NOTDIRPATH's
shared error jump has verified destination NODEACCERRJ but is 2-byte EB in
the bounded module versus target 3-byte E9 at 336Dh. It is not byte-identical;
full dircall layout must restore this encoding naturally. No padding or target
binary substitution was used. The existing bounded dircall source header's
adjacent-tail note denotes temporary placement, not original target layout.
Remaining: CheckThisDevice still invokes the NT path service; full directory
operations, shared layout, SFT/INT24 and standalone runtime remain incomplete.


Device-path continuation: CheckThisDevice now implements the target's device
syntax (including leading backslash-dev-backslash) without SVC_DEMCHECKPATH.
Caller audit found NT DX status checks in macro2.asm; removed them and its
extra GetThisDrv error branch, restored CLC success and the physical
ValidateCDS call in DoFile. Both full 69-byte slices match with named calls.
Verification: m4-t5-devicepath-verification.json --devicepath, covering
5956 unique target bytes and 104 calls; initialization regression passes.

Owner explicitly requires original Microsoft structure, formatting, comments
and parameter conventions. This is now recorded in rules/CODING.md. Restyled
bounded dircall.asm and rom.asm headers/assembly, restored comparative routine
parameter comments, and removed the obsolete NT TransPath warning. Clean
style build m4-t5-devicepath-style-build.json has identical binary and map to
the verified build: 31986 bytes, SHA-256
471c4dc9c1569e2c207e543b5bfb4d84589e3ca09fe619a354a1a97f7d3f1bcb.
Audit m4-t5-devicepath-integration-audit.json confirms current kernel and
COMMAND snapshots. Style changes did not alter machine code.

Next physical directory API gaps: path.asm still invokes DEMSETCURRENTDIR,
DEMCREATEDIR and DEMDELETEDIR. Complete their original shared dircall module
structure rather than retaining bounded layout indefinitely. NOTDIRPATH's
short/near difference, broader NT/SFT/INT24 recovery and whole-file/runtime
acceptance remain outstanding. No full TransPath recovery is claimed.


Physical CHDIR continuation: restored the comparative procedure in path.asm,
retaining Microsoft formatting, comments and register conventions. It calls
DOS_ChDir to check existence, restores joined CDS handling and local cluster
currency, and removes SVC_DEMSETCURRENTDIR. MKDIR/RMDIR still invoke NT services.

Clean isolated build m4-t5-chdir-build.json: 31986 bytes, SHA-256
b632e0c807568f3ecb7d78933e05dc077870c4fa601b1c436d4df4ac34ae45d1.
Verification command adds --chdir to --init --setdpb --devicepath. The actual
123-byte procedure is checked as a 121-byte target-corresponding body plus
its 2-byte shared success transfer. Target has a 3-byte direct success jump;
current transfer goes through $CURRENT_DIR's SYS_RET_OK trampoline. Error
transfer similarly skips target RMDIR's intermediate shared jumps. Both
complete jump chains are decoded and must reach named SYS_RET_OK/SYS_RET_ERR.
These are explicit layout differences, not whole-procedure byte identity.

m4-t5-chdir-verification.json covers 6077 unique target slice bytes and
110 named calls; prior NOTDIRPATH short/near difference remains explicit.
Initialization regression and kernel/COMMAND snapshots pass. Audit:
m4-t5-chdir-integration-audit.json. Next restore physical MKDIR/RMDIR and the
original shared module ordering, then remaining filesystem/INT24 and runtime.


Full dircall module recovery: dos/dircall.full.recovery.asm follows the original
comparative module structure and comments, with critical macros replaced by
explicit restored EcritDisk/LcritDisk invocations. All 521 bytes at target
[31F6h,33FFh) match after enumerated OMF symbol resolution. Reproduce with:
python tools/verify_storage_candidate.py --module dircall
Report m4-t5-dircall-verification.json. Original ordering naturally produces
NOTDIRPATH E9 91 FE at 336Dh, resolving the bounded candidate's encoding issue
in the comparison only; formal dircall.asm is not replaced yet.

Comparison requires complete DOS 6 sf.inc for RenBuf.sf_mft. It is copied
only into the owned comparison stage, with hash in comparison_headers;
production/shared SFT definitions are unchanged. Six external names remain
absent from the accepted link: SET_MKND_ERR (create), MAKENODE/NEWDIR/SETDOTENT
(mknode), RELEASE (rom), FastOpen_Delete (delete). Other named symbols being
linked does not establish full runtime behavior. See
m4-t5-dircall-closure-audit.json for the finite dependency inventory.

Kernel/COMMAND input snapshots remain intact. Next recover these physical
helpers and audit SFT fields before integrating the full module and switching
MKDIR/RMDIR. Latest accepted kernel remains m4-t5-chdir-build.json; full binary
identity and runtime still unproved.


RELEASE/GETEOF continuation: target [5068h,50A7h), 63 bytes including a shared
preceding RET, differs from comparative DOS 6's RELEASE_flush tail. DOS 5
returns on UNPACK/PACK failure, free/end cluster, and final EOF without that
later FLUSHBUF sequence. Restored original retc/retz macro style and retained
procedure/register comments; no synthetic padding. Candidate proof:
m4-t5-release-verification.json. Integrated RELEASE/RELBLKS/GETEOF into rom.asm.

Clean isolated build m4-t5-release-build.json: 32050 bytes, SHA-256
6c5e6502abf995517646f2a205f465500a0b20a511bede5505a552c3cc693b38.
Actual-link regression passes for 6140 unique target slice bytes and
115 named calls; the new slice checks five UNPACK/PACK/IsEOF calls.
Initialization regression and kernel/COMMAND snapshot checks pass. Reports:
m4-t5-release-linked-verification.json, m4-t5-release-segreinit-regression.json,
m4-t5-release-integration-audit.json. Current preceding shared RET belongs to
FIGREC; restore original full rom layout as intervening routines return.

Full dircall now has five missing named helpers: SET_MKND_ERR, MAKENODE,
NEWDIR, SETDOTENT, FastOpen_Delete. SFT recovery, original module layout,
remaining NT operations and runtime acceptance are still outstanding.


Full node-maker candidate: mknode.recovery.asm preserves the comparative
Microsoft module/procedure/comment layout. It restores the EcritDisk and
LcritDisk calls omitted by NT critSFT macros; target 4BFEh and 4C11h call
1356h and 1376h. The entire 941-byte module [4A3Ah,4DE7h), including BUILDDIR,
NEWDIR, SETDOTENT, MAKENODE and its entry/SFT helpers, matches at target layout.
Reproduce: python tools/verify_storage_candidate.py --module mknode
Proof m4-t5-mknode-verification.json. No original OpenNT mknode.asm was found;
DOS 6 is the explicitly recorded comparative source, not assumed original DOS 5.

Integration audit m4-t5-mknode-closure-audit.json identifies four absent names:
ALLOCATE, FastOpen_Update, ShareEnter, ShareEnd. Present symbols are not runtime
proof. SFT audit also shows NT removed sf_firclus and cluster/directory/name/
UID/MFT fields and added sf_NTHandle, changing subsequent offsets. Candidate
uses complete comparative sf.inc only in its owned comparison stage; formal
kernel headers and inputs remain untouched. A coherent physical SFT transition
is required before production integration, not a mixed ABI or dummy fields.

All accepted kernel/COMMAND snapshots still match. Next restore allocation,
FastOpen update and sharing helpers, then integrate the original full modules
with audited SFT users. Latest accepted kernel remains m4-t5-release-build.json;
whole-file identity and standalone runtime remain incomplete.


Allocation/FastOpen continuation: ALLOCATE/RESTFATBYT candidate matches all
179 bytes [4FB6h,5069h), including preceding FIGREC RET. Removed comparative
DOS 6 callmagic/MAGICDRV patch and its helper: target DOS 5 has no compression
allocation hook. Physical sf_firclus/sf_lstclus writes match with comparison-only
full sf.inc. Proof: m4-t5-allocate-verification.json. Integration awaits SFT.

FastOpen_Delete/Rename/Update/Fast_Dispatch tail is 62 bytes [27BBh,27F9h),
exact at target layout and now production-linked in newly created delete.asm.
No previous delete.asm existed; exclusive creation preserved all existing code.
Full delete module remains to restore. Clean isolated m4-t5-fastopen-build.json:
32114 bytes, SHA-256
414022fc709d9a71ceb7e19e1f69f024ba0e41b645f93ea20988b1f8956f93df.
Actual-link and segment initialization regressions pass; kernel/COMMAND input
snapshots match. Evidence: m4-t5-fastopen-linked-verification.json,
m4-t5-fastopen-segreinit-regression.json, m4-t5-allocate-fastopen-audit.json.

Next: sharing helpers, SET_MKND_ERR and coherent physical SFT migration for
full mknode/dircall integration. Existing layout differences and full runtime
acceptance remain open. FastOpen far dispatch is statically matched, not a
proof that a resident cache driver has executed successfully.


Sharing/error-map candidates: complete comparative share.asm is 82 bytes at
[7558h,75AAh), with Share_Check, Share_Violation, ShareEnd and ShareEnter.
All bytes match using full physical sf.inc only in the comparison stage.
HardErr and Idle external targets are explicitly decoded. Proof:
m4-t5-share-verification.json. SET_MKND_ERR plus its eight-byte CRTERRTAB is
15 bytes [2BD9h,2BE8h), exact with the code-relative table operand resolved
from source; m4-t5-create-error-verification.json. Commands use
verify_storage_candidate.py --module share / --module create-error.
These remain candidates until physical SFT integration, not runtime proof.

Reproducible SFT transition inventory: python tools/audit_sft_transition.py.
It freezes m4-t5-fastopen-build inputs and native MASM structure listings.
NT sf_entry is 33 bytes; physical is 59. Field offset changes are enumerated
in m4-t5-sft-transition-audit.json. There are 59 lexical NT-specific field/
flag uses including header definitions across seven .asm modules plus sf.inc;
conditional activity is not inferred from lexical presence. Default sftabl
uses FILLSPACE=5*(59-sizeof sf_entry): NT padding is 130 bytes, physical zero.
Thus its total reserved area can remain stable while entry stride changes.

Next perform a kernel-only physical SFT transition with NT-handle users and
host paths restored coherently, then integrate already proven mknode/dircall/
share/allocation code. Do not append dummy NTHandle fields or reinterpret its
old offset as a physical field. Accepted kernel and COMMAND snapshots remain
intact; latest build remains m4-t5-fastopen-build.json. Whole layout, original
module completion and runtime acceptance remain open.


Device open/close restoration: DEV_OPEN_SFT through DEV_CLOSE_SFT matches
all 129 bytes [475Eh,47DFh) at target layout, using unchanged common SFT
flags/devptr offsets. Restored the OpenNT-removed block-device branch from
comparative DOS 6: fshare > 1 gate, DPB unit/drive and driver address; restored
dpb.inc dependency. Production diff is confined to this include and branch.
Original Microsoft comments and register conventions are retained.

Clean isolated build m4-t5-openclose-build.json: 32130 bytes, SHA-256
171e1d72b0276a36450a0cc00f1db1d8a4d473402068ad5de4bf6d443c347295.
Actual-link regression covers 6331 unique target bytes and 120 named calls,
including five calls in the new slice; initialization regression passes.
Kernel and frozen COMMAND source snapshots match. Proofs and reviewed diff:
m4-t5-dev-openclose-verification.json, m4-t5-openclose-linked-verification.json,
m4-t5-openclose-segreinit-regression.json, m4-t5-openclose-integration-audit.json.

IOFUNC still uses sf_NTHandle and NT read/write/pipe services; CHARHARD's
call destination is checked but its full implementation is not thereby proven.
Next recover IOFUNC and physical file/SFT paths coherently, then integrate
mknode/dircall/allocation/sharing. Whole-file identity and runtime remain open.


IOFUNC reconstruction: complete comparative DOS 6 IOFUNC plus its two tables
matches all 360 bytes [45F6h,475Eh) at the target layout. Candidate
 dos/dev.iofunc.recovery.asm retains original procedure/parameter comments.
Only standalone-assembly adaptation is CALL DEVIOCALL -> invoke DEVIOCALL;
full physical sf.inc is comparison-only. Evidence:
m4-t5-dev-iofunc-verification.json; reproduce with
python tools/verify_storage_candidate.py --module dev-iofunc.

Integration prerequisites are now verified by tools/audit_iofunc_transition.py
and m4-t5-iofunc-transition-audit.json. Active native disk.lst contains B4 06
at module offset 0304h followed by IOFUNC: this NT cooked string output caller
must be restored with the DOS 5 callee's 0..5 command table. DOS_READ/DOS_WRITE
names exist but physical file branches are absent. DISKREAD, DISKWRITE,
SETUP and DOS_COMMIT are all absent from the accepted link map; DSKREAD and
DSKWRITE are sector wrappers, not substitutes for the file transfer entries.
Candidate sf_position is 15h, production NT is 13h. No mixed ABI was installed.

Next restore full disk.asm and disk2.asm file-transfer dependencies alongside
physical SFT users, then integrate IOFUNC and existing node/allocation/sharing
candidates. Latest production build remains m4-t5-openclose-build.json;
kernel and COMMAND snapshots match. Full identity/runtime remain incomplete.


Full file-I/O module candidates: disk.full.recovery.asm covers all 1206 bytes
[33FFh,38B5h); disk2.full.recovery.asm covers all 737 bytes [38B5h,3B96h).
Both match at target layout. disk.asm uses comparative DOS 6 source with
EnterCrit/LeaveCrit critDisk restored as explicit EcritDisk/LcritDisk calls;
disk2.asm is byte-identical source to the pinned comparative DOS 6 module.
Original procedure, register and comment conventions remain intact.

One explicit data-layout departure: disk.asm's polled-console IsWin386 test
at target 347Dh addresses DOSDATA:1030h, versus accepted production 100Eh.
The candidate resolver records this comparison-only symbol placement; no
production header, data layout or address constant was patched. It is not an
actual-link exactness claim. The two candidates require full physical sf.inc
only in their comparison stages. Native retry-count M065 code matches target
without removal. Evidence: m4-t5-disk-full-verification.json,
m4-t5-disk2-full-verification.json; commands verify_storage_candidate.py
--module disk-full / --module disk2-full.

m4-t5-disk-full-closure-audit.json freezes source/proof hashes, current absent
external names and integration order. Correct module ownership: DISKWRITE,
DIV32 and SHR32 belong to disk3.asm; DOS_COMMIT is in close.asm. Next recover
those and rom.asm FNDCLUS/BUFRD/NEXTSEC/OPTIMIZE plus locking, then perform
coherent kernel-only physical SFT migration and whole disk/dev integration.
Do not retain duplicate bounded diskread entries when full disk.asm is linked.
Current production remains m4-t5-openclose-build.json; both production and
COMMAND snapshots match. Full identity and runtime acceptance remain open.


Full disk3/rom recovery: disk3.full.recovery.asm matches 810 bytes
[3B96h,3EC0h), including DISKWRITE, buffer purge, DIV32 and SHR32. DOS 5
calls shared DWRITE at 3D08h; the comparative DOS 6 compressed-volume
DWRITE_LUP/DWRITE_DISK_FULL additions are removed. SET_ACC_ERRW is restored
after the SETCLUS transfer, at 3D58h, as required by all target branches.
The DS/DMAADD and ALLOWED setup is retained. Proof:
m4-t5-disk3-full-verification.json.

rom.full.recovery.asm matches all 704 bytes [4DE7h,50A7h), including FNDCLUS,
SKPCLP, BUFSEC, BUFRD, BUFWRT, NEXTSEC, OPTIMIZE, FIGREC, ALLOCATE,
RESTFATBYT, RELEASE/RELBLKS and GETEOF. Previously evidenced DOS 5 changes
(remove MAGICDRV allocator hook, omit DOS 6 release FLUSHBUF tail) now hold
in original complete module ordering; shared return layout matches naturally.
Proof: m4-t5-rom-full-verification.json. Both use physical SFT only in the
comparison stage, retain Microsoft source/comment/register style, and remain
candidates. Reproduce via verify_storage_candidate.py --module disk3-full /
--module rom-full. No standalone runtime claim.

Reproducible tools/audit_storage_closure.py freezes 12 storage candidates and
123 named code edges, decodes native OMF public offsets and checks each
candidate-to-candidate target address. Only DOS_COMMIT, LOCK_CHECK and
LOCK_VIOLATION lack both a candidate provider and an accepted linked symbol.
Evidence: m4-t5-storage-closure-audit.json. This is a code-name graph, not
proof of existing callees, indirect calls, data ABI or transitive runtime
closure. Next recover those close/locking entries, then migrate physical SFT
users coherently and integrate whole modules, removing duplicated bounded
fragments. IsWin386 production placement also remains to resolve.

Latest production remains m4-t5-openclose-build.json; kernel and COMMAND
snapshots match. Full binary identity, standalone boot and deployment remain
outstanding; M4 T5 S2 and the complete project goal remain active.


Complete locking/close candidates: lock.full.recovery.asm matches 178 bytes
[74A6h,7558h), including $LockOper, LOCK_CHECK, LOCK_VIOLATION and CheckShare.
close.full.recovery.asm matches 428 bytes [304Ah,31F6h), including DOS_CLOSE,
FREE_SFT, DirFromSFT, DOS_COMMIT and SetSFTTimes. Close restores all critDisk
calls, including the double entry in commit. Proofs: m4-t5-lock-full-verification.json
and m4-t5-close-full-verification.json. Close remains physical-SFT candidate.

Full lock.asm is now production-linked: removes NT handle extraction and
SVC_DEMLOCKOPER, restores network INT 2Fh / SHARE dispatch, retry and HardErr
paths. It uses only unchanged SFT flags, so no mixed-layout field access was
introduced. Source equals the pinned comparative Microsoft module; full target
match supports reconstruction, not a claim of original DOS 5 source provenance.

Clean isolated m4-t5-lock-build.json: 32258 bytes, SHA-256
51cf4390b9212bf198bf2430a4d7004644303b7b0ed08a81e51a6aa8e0deab01.
Actual-link regression covers 6509 unique target bytes and 123 named calls;
lock additionally verifies two return jumps and CheckShare's DosDseg operand.
Initialization regression passes. m4-t5-lock-integration-audit.json records
reviewed production diff; only dos/lock.asm changed since openclose build.

Storage graph now has 14 candidates and 141 named code edges; no named code
provider is absent from both candidates and accepted map. Native public offsets
are checked, but map presence is not callee correctness, runtime, indirect-call
coverage or ABI compatibility. Production and COMMAND snapshots pass. Next
perform kernel-only physical SFT migration with remaining NT users restored,
then integrate full disk/dev/rom/close/mknode/dircall/share modules together.
IsWin386 placement, whole binary equality and standalone runtime remain open.


Physical SFT migration probe: tools/probe_physical_sft.py creates an owned
native-only stage from m4-t5-lock-build, combines target-verified full storage
candidates, removes duplicate diskread from its module list and adds full
close/mknode/disk3/share plus the creation error mapper. It overlays comparative
DOS 6 abort/fcbio/fcbio2/handle/file solely as UNVERIFIED investigation inputs,
not accepted reconstructions. No production sources or shared COMMAND headers
are modified. Latest stage: build/physical-sft-probe-w4i4ug52.

All 51 modules now assemble with a 59-byte physical sf_entry. Initial stage
physical-sft-probe-2kdarjfr found three real migration surfaces: zero FILLSPACE
DUP is rejected by native MASM; physical FCB fields require full cpmfcb.inc;
console SFT initialization needs sf_firclus plus name/extension setup. These
are restored only in the probe, with source hashes and classification recorded
in m4-t5-physical-sft-probe.json. Startup changes and five comparative SFT users
still require target-byte evidence. Assembly compatibility is not integration,
link, data-layout or runtime acceptance.

Native OMF declaration audit m4-t5-physical-sft-symbol-audit.json finds duplicate
CHECK_VIRT_OPEN (NT msctrlc and physical mknode) and unprovided declarations:
DOS_DELETE, DOS_RENAME, GET_FILE_INFO, SET_FILE_ATTRIBUTE, SET_EXT_MODE,
OFFSETMAGICPATCH. The last is an unused comparative ROM declaration after
removing the compression hook; distinguish actual fixups before assigning a
link failure. Next resolve those physical pathname dependencies and NT stub
ownership, target-verify the five SFT user modules/startup, then link the probe
and promote only evidence-backed changes. Current production remains
m4-t5-lock-build.json; kernel and COMMAND input snapshots still match.


Pathname dependencies: complete finfo.full.recovery.asm matches 260 bytes
[2A36h,2B3Ah), delete.full.recovery.asm matches 480 bytes [2619h,27F9h),
and rename.full.recovery.asm matches 573 bytes [27F9h,2A36h). Each preserves
comparative Microsoft module structure/comments/register conventions, with
NT-no-op critDisk macros restored to explicit EcritDisk/LcritDisk calls.
Proofs: m4-t5-finfo-full-verification.json, m4-t5-delete-full-verification.json,
m4-t5-rename-full-verification.json. Full delete includes REN_DEL_Check and
FastOpen routines; it replaces, not supplements, the earlier bounded tail.

The physical-SFT probe now assembles 53 modules successfully, including these
three full candidates, at build/physical-sft-probe-aa1_pxwn. Production remains
m4-t5-lock-build.json. Five comparative SFT-user modules and startup changes
are still investigation inputs requiring target evidence, not promoted source.
Snapshot checks preserve kernel and COMMAND. Summary:
m4-t5-pathname-storage-audit.json; reproduce probe_physical_sft.py and
verify_storage_candidate.py --module finfo-full / delete-full / rename-full.

Named-code graph universe expands to 16 candidates/185 edges, replacing
fastopen with full delete. Newly exposed absent providers: DOS_SEARCH_FIRST,
RENAME_NEXT, SET_MEDIA_ID. SET_EXT_MODE remains a separate comparative file
probe import, not yet part of this candidate graph. Next restore full create
and physical internal search dependencies, resolve duplicate CHECK_VIRT_OPEN
ownership, then verify SFT users/startup and actual link. Prior physical-sft
symbol audit refers to its earlier recorded stage; no claim it covers the new
53-module composition. No whole-file identity/runtime acceptance yet.


Create/open/search closure: complete create.full.recovery.asm matches 300 bytes
[2B50h,2C7Ch), open.full.recovery.asm matches 373 bytes [2C7Ch,2DF1h), and
isearch.full.recovery.asm matches 395 bytes [2E52h,2FDDh). Full create supplies
Set_Media_ID/Set_EXT_mode and replaces the bounded error mapper in the probe.
Open supplies SET_SFT_MODE; internal search supplies DOS_SEARCH_FIRST/NEXT and
RENAME_NEXT. Original Microsoft conventions are retained, critDisk calls
restored. Proofs: m4-t5-create-full-verification.json,
m4-t5-open-full-verification.json, m4-t5-isearch-full-verification.json.
Named-code graph now spans 18 candidates/209 edges with no absent providers;
this is not whole-runtime closure.

54-module physical-SFT probe now ASSEMBLES AND LINKS on the private desktop.
Latest owned stage: build/physical-sft-probe-roq3haya. The probe removes NT
msctrlc's duplicate CHECK_VIRT_OPEN, retaining its call to the full mknode owner.
Actual LINK first rejected unused OffsetMagicPatch declaration in rom; remove
that stale i_need after eliminating the compression hook. ROM remains exact
at all 704 target bytes after reassembly. Native OMF declaration presence can
therefore matter even without executable operand use. Prior graph/reference
proof hashes are historical; the refreshed graph uses the new ROM proof.

Reproduce: python tools/probe_physical_sft.py, then
python tools/link_physical_sft_probe.py (private isolated desktop).
Evidence: m4-t5-physical-sft-probe.json and m4-t5-physical-sft-link-probe.json.
Final host exit 0, PASS, no unresolved externals; LINK reports no-stack and
no-start-address warnings expected for this intermediate DOS kernel EXE.
An initial launcher attempt used a non-8.3 BAT filename and timed out with
host exit 124, no link run. Its owned process was terminal before retry with
PROBELNK.BAT; m4-t5-physical-sft-link-launch-failure.json retains that result.
The actual unresolved-symbol attempt is retained separately in
m4-t5-physical-sft-link-unresolved.json.

This is a scratch link, not a promoted MSDOS.SYS: relocation/stripping, target
verification of comparative abort/fcbio/fcbio2/handle/file and SFT startup,
linked-byte regression, physical data placement, and runtime remain required.
Production stays m4-t5-lock-build.json and COMMAND stays unchanged; snapshots
checked by refreshed storage audit. Next target-verify the five SFT users and
startup before promoting the coherent physical migration.


Physical-SFT consumer validation: complete abort.full.recovery.asm matches
109 bytes [2FDDh,304Ah) using physical sf_entry (PID/UID offsets and 59-byte
stride). This is the unchanged pinned comparative Microsoft module. It
replaces NT host-handle close with the target DOS process/FCB reference cleanup
and network/SHARE notifications. Evidence: m4-t5-abort-full-verification.json.

Console SFT initialization candidate msinit.sft.recovery.asm matches all
51 bytes [7A60h,7A93h), including the previously missing sf_firclus zero and
name/extension copy. Procedure body is taken from the comparative initializer,
with historical comments/register usage retained. Evidence:
m4-t5-init-sft-verification.json. This validates only the console SFT block,
not all initialization or data layout.

Actual-link verification: python tools/verify_probe_sft_startup.py verifies
frozen MZ/map/listing hashes and maps native listing offsets into probe.exe's
load image. The 51-byte initializer is RAW EXACT; the full 109-byte DOS_ABORT
matches after two explicitly decoded linked calls to $CLOSE and SFFromSFN.
Evidence: m4-t5-sft-init-abort-linked-verification.json. Existing scratch probe
stage physical-sft-probe-roq3haya was inspected, not rebuilt; its historical
report still describes abort as an investigation input, now superseded by
these specific proofs. Probe recipe uses the byte-identical verified abort
candidate on future runs. No runtime claim.

Storage graph expands to 19 candidates/211 named edges, still no missing
provider. Four comparative consumers remain target-unverified: fcbio, fcbio2,
handle and file. Next validate those and other initialization/data changes,
then perform full linked regressions and promote coherent SFT migration.
Production remains m4-t5-lock-build.json; kernel/COMMAND snapshots pass.
Whole-file equality and standalone runtime remain incomplete.


Handle consumer validation: handle.full.recovery.asm matches complete 640 bytes
[68FBh,6B7Bh), covering close/commit, extended handle table, read/write, seek,
file times, duplicate handles and CheckOwner. Physical sf.inc is comparison-only.
Restore EnterCrit/LeaveCrit critSFT as EcritDisk/LcritDisk (target 6AFFh/6B1Ch).
The earlier unverified DOS 6 probe lost these six bytes through NT macros;
replacing it with this candidate corrects actual emitted code. IsWin386 has
an explicitly recorded target placement 1030h versus production 100Eh at
operand 6B62h, consistent with the disk candidate. Proof:
m4-t5-handle-full-verification.json; --module handle-full.

Physical probe recipe now consumes verified abort/handle sources, leaving
fcbio/fcbio2/file as comparative inputs. All 54 modules reassemble and link in
private isolation: build/physical-sft-probe-xcx0k53o. No production promotion.
Actual entire linked handle module verified by tools/verify_probe_candidate.py
--module handle-full: 640 bytes and 48 OMF-named relocations, zero remaining
differences. Candidate source hash must equal assembled probe source; linked
MZ/map and candidate resolved-byte hashes are checked. Data/code relocations
are explicit, including IsWin386 difference and indirect DOS_READ/DOS_WRITE
addresses. Proof: m4-t5-handle-full-probe-linked-verification.json.

SFT startup/abort linked checks rerun against this new probe and pass: 51-byte
initializer raw exact; 109-byte abort call-adjusted correspondence. Storage
graph now has 20 candidates/226 named edges, no absent provider. Existing
link-probe scope wording about five unverified callers reflects the original
probe template; current count is THREE as established by these later proofs.
Next verify FCB pair and file module, then full linked storage regression,
physical layout and remaining NT runtime seams before coherent promotion.
Current accepted production remains m4-t5-lock-build.json; whole-file target
identity, standalone boot and deployment remain outstanding.


Pathname SFT consumer: file.full.recovery.asm matches complete 969 bytes
[70DDh,74A6h), including open/create, chmod, unlink, rename, temporary/new-file
creation and extended open. Restore critSFT macros to explicit EcritDisk and
LcritDisk at 70E8h/70EEh. Native NT macros had omitted these six bytes in the
previous comparative probe. Preserve Microsoft module/procedure comments and
register conventions. Three MOV CX code-pointer witnesses at 70E4h,71B5h,
72A0h name DOS_OPEN/DOS_CREATE/DOS_CREATE_NEW; the candidate resolver validates
opcode and target address separately from E8/E9 call/jump witnesses.
Evidence: m4-t5-file-full-verification.json; --module file-full.

Probe now uses verified file candidate; only fcbio/fcbio2 remain comparative
unverified consumers. All 54 modules reassemble/link successfully on private
desktop in build/physical-sft-probe-1cdxzp1u. Complete actual-link file proof
checks 969 bytes and 119 OMF named relocations with zero remaining differences:
m4-t5-file-full-probe-linked-verification.json; reproduce via
verify_probe_candidate.py --module file-full. Same run's handle proof passes
640 bytes/48 fixups; initializer remains raw-exact at 51 bytes, abort passes
109-byte call-adjusted proof. Latest linked reports replace prior probe views.

Storage graph has 21 candidates and 249 named edges, no missing providers.
Production remains m4-t5-lock-build.json, COMMAND unchanged; snapshot audit
passes. Next validate complete FCB modules, then actual-linked full storage
regression, physical data layout and remaining host seams before promoting
coherent physical-SFT migration. No whole-file or runtime acceptance yet.


FCB consumer validation: full fcbio (1224 bytes,[1829h,1CF1h)) and fcbio2
(778 bytes,[1CF1h,1FFBh)) candidates match target-layout assembly. Both
.recovery.asm files are byte-identical to their DOS 6 comparative sources,
retaining Microsoft structure, comments and register conventions for physical
implementation recovery in the NTDOS-derived kernel. Physical sf.inc and
cpmfcb.inc remain comparison-only. LocalSFT is explicitly 103Bh in accepted
production versus target 105Dh (11 FCBIO operands and two FCBIO2 operands).
FCBIO's CS-relative DosDseg loads are checked: DS at 1A28h, ES at 1B02h/1CD3h.
No production data-layout adjustment was made.

Reproduce with tools/verify_storage_candidate.py --module fcbio-full or
fcbio2-full, followed by tools/verify_probe_candidate.py with the same
arguments. Actual complete linked modules in physical-sft-probe-1cdxzp1u
pass with 95 and 49 named OMF relocations and zero remaining differences.
Staged source hashes match the candidates; no relink was needed. Future
probe recipe now selects verified candidates. Retained assembly reports
still describe their historical comparative input paths.

Storage graph: 23 candidates, 284 named edges, no missing named providers.
Production (115 inputs) and COMMAND (113 inputs) snapshots pass. M4 T5 S2
remains active; accepted production remains m4-t5-lock-build.json. Next:
full linked storage regression, physical data placement (LocalSFT/IsWin386)
and remaining NT host seams before coherent promotion. Whole-file identity,
standalone runtime and deployment acceptance remain outstanding.


DOSTAB layout investigation resolves the shared 34-byte displacement:
NT moved the 17-word EXEC work area from DOSTAB to LMSTUB (the latter's
comment records that migration). dos/dostab.layout.recovery.asm restores
the comparative DOS 6 declarations verbatim at the historical position and
changes the EXEC instance-table span from 24 to target-proven 34 bytes.
No arbitrary padding or binary substitution is used.

Native assembly proof: tools/verify_dostab_layout.py;
m4-t5-dostab-layout-verification.json. Complete initialized tail
[0FE2h,1061h) is 127 bytes exact after bounded internal DOSDATA OMF fixups.
The preceding 34-byte uninitialized allocation has verified symbol offsets,
not an initialized-byte/linker/runtime claim. EXEC starts 0FC0h, Win386_Info
0FE2h, IsWin386 1030h and LocalSFT 105Dh. The source candidate is the existing
NT-derived DOSTAB plus the reference declaration block and the one span edit.
Scratch-only LMSTUB removes duplicate declarations to permit assembly.

Do not promote this candidate alone: NT MSPROC's GetBinaryType path can
read Exec_Header_Len_NE=62 bytes at Exec_Signature. In restored layout that
would overwrite 36 bytes of Win386 data. The remaining NT extended-header
buffer is deliberately not claimed coherent in the data-only probe. Restore
the DOS 5 EXEC header-loading path before coherent layout integration; full
linked storage regression and other host seams remain open. Accepted kernel
and COMMAND snapshots still pass unchanged. M4 T5 S2 stays active; no runtime,
whole-file identity or deployment acceptance. Earlier delayed sessions have
completed; native assembly exited zero, no live verification job remains.


EXEC header/read chain recovery: dos/msproc.full.recovery.asm is a complete
comparative DOS 6 module with three critical macros changed to explicit
EcritMem/LcritMem invokes because NT macros omit those calls. Preserve the
original structure/comments/register conventions. It is an investigation
candidate, NOT a fully target-verified or promoted MSPROC replacement.

Native proof tools/verify_exec_header.py verifies two complete source-object
slices: header loading/signature classification [5E26h,5E5Ch), 54 bytes;
ExecRead plus exec_dealloc/exec_alloc/ChangeOwners/ChangeOwner
[62BFh,6306h), 71 bytes. All 125 bytes match target with 17 named OMF fixups.
The latter includes actual critical calls at 62D1h/62E2h and $READ at 62C6h.
Proof: m4-t5-exec-header-verification.json, with source/reference/tool/header
hashes, listing labels, OMF relocations and byte hashes. External callee
addresses are not runtime validation. No target bytes are copied to source.

The source-generated header reads 26 bytes at 0FC8h, ending exactly at 0FE2h
(the restored Win386_Info boundary), unlike NT's 62-byte GetBinaryType read.
Thus the bounded DOS 5 read path is established, but NT preclassification,
other EXEC code and host transitions still require coherent replacement.
Next verify the entire MSPROC module and its dependencies before integrating
DOSTAB plus physical SFT. Production remains m4-t5-lock-build.json; accepted
kernel and COMMAND input snapshots pass. M4 T5 S2 stays active, no whole-file,
standalone runtime or deployment acceptance.


Complete MSPROC candidate: [5D2Ah,63F2h), 1736 bytes now matches target
with 156 explicit OMF fixups at pinned symbol placements. Reproduce:
python tools/verify_msproc_full.py. Evidence m4-t5-msproc-full-verification.json
and m4-t5-msproc-target-bindings.json. Source preserves historical style.
Beyond the three restored memory critical calls, remove the DOS 6-only
Rational386PatchPtr indirect call (five bytes absent in target) and restore
COM allocation check CMP AX,100h (target 60B7h); DOS 6 uses 200h, while the
existing NTDOS source independently retains 100h. Whole source remains a
comparative physical implementation candidate for the NT-derived kernel.
The earlier 125-byte header/ownership proof passes with the updated source.

Bindings are explicitly pinned source-name/target-operand attributions, not
independent proof of production ABI. Every use must resolve consistently;
all internal jumps/calls, non-relocation bytes and target length match.
Nineteen data symbols differ from accepted production: fourteen EXEC fields,
DriverLoad/BiosDataPtr, fixexepatch/DosHasHMA and Disa20_Xfer. EXEC and Windows
prefix have independent DOSTAB proof; the later patch/HMA/transfer placement
requires further restoration. External callees are addresses, not runtime
validation. The older 23-candidate storage graph does not yet include MSPROC.

Next integrate MSPROC and DOSTAB together in the disposable physical-SFT
probe, remove the obsolete duplicate LMSTUB EXEC allocation/NT extension,
and verify actual linkage and data layout before any production promotion.
Production and COMMAND snapshots remain unchanged; M4 T5 S2 active. Full
MSDOS.SYS identity, standalone runtime and deployment are not accepted.


MSPROC/DOSTAB physical-probe integration now passes in
build/physical-sft-probe-_e0pgjth: all 54 modules assemble and the private
isolated-desktop DOSBox LINK completes successfully. The probe overlays both
candidates and removes the full obsolete EXEC allocation/NE extension from
staged LMSTUB. Accepted production remains untouched. A first link exposed
an unused Rational386PatchPtr EXTRN; removing that declaration preserves all
candidate bytes and resolves the real linker error. Retained failure:
m4-t5-msproc-link-unused-external.json. Full MSPROC proof rerun passes.

Actual-link proof: tools/verify_probe_exec_layout.py, report
m4-t5-exec-layout-probe-linked-verification.json. Entire MSPROC (1736 bytes,
156 named fixups) corresponds with zero remaining differences; DOSTAB's
127-byte initialized tail is raw exact. EXEC allocation and Windows/LocalSFT
symbol offsets match target. Of the 19 former MSPROC data-placement differences,
only three remain: fixexepatch target1212h/linked11FCh, DosHasHMA target1211h/
linked11FBh, Disa20_Xfer target1115h/linked1117h. Do not hide those offsets
behind the relocation-correspondence result.

Same linked probe regressions pass: FCBIO 1224 bytes/95 fixups, FCBIO2
778/49, handle 640/48, file 969/119; SFT initializer 51 bytes raw exact,
abort 109 bytes with named call adjustments. DOSTAB standalone verifier now
also supports probe input with the NT EXEC allocation already removed.
Production and COMMAND snapshot checks pass unchanged. Next restore remaining
A20/HMA/patch data and runtime seams, broaden linked storage regression, then
promote only a coherent candidate. M4 T5 S2 active; no whole-kernel identity,
standalone runtime or deployment acceptance.


Physical low-memory stub restoration: inc/lmstub.physical.recovery.asm keeps
the NT-derived module and restores comparative physical sections: native
IRET/CLI/STI, removal of SVC_DEMENTRYDOSAPP, unified flag-preserving EnsureA20ON,
and Windows 2.x OldInstanceJunk at its earlier location with 34-byte EXEC span.
No padding is added. The staged probe still removes obsolete NT EXEC storage.
Other NT data after the bounded restored region remains unaccepted.

All 54 modules assemble/link in private isolation at
build/physical-sft-probe-_di49yv4. tools/verify_probe_lmstub.py proves the
entire linked DOSDATA range [108Ah,122Ah), 416 bytes RAW EXACT, including
interrupt stubs, A20 transfers and enable/disable paths, old Windows table,
HMA flag, patch slots, RatBugCode and reserve through Mark3. Proof:
m4-t5-lmstub-probe-linked-verification.json. No relocations are masked.
DOSINTTABLE code pointers preceding the range and the NT tail are excluded.

Disa20_Xfer=1115h, DosHasHMA=1211h and fixexepatch=1212h now match target.
Actual linked MSPROC proof rerun has zero remaining data-placement differences
(all 19 prior ones resolved), still 1736 bytes/156 named relocation checks.
DOSTAB tail remains 127 bytes raw exact. Current linked regressions pass for
FCBIO, FCBIO2, handle, file, 51-byte SFT initialization and 109-byte abort.
Kernel/COMMAND production snapshots remain unchanged. Next broaden actual
linked storage coverage and restore remaining initialization/host seams before
promoting coherent physical kernel sources. M4 T5 S2 active; whole-file
identity, standalone runtime and deployment are not accepted.


Actual-link physical storage suite completed for a finite declared universe:
23 units (20 complete modules and three composite DEV slices), 12800 unique
non-overlapping target bytes and 12800 unique linked bytes, 1381 named OMF
fixups. Every unit passes on physical-sft-probe-_di49yv4 with zero remaining
differences after the declared relocations. This closes only that finite
verification universe, not the whole kernel or runtime. Evidence:
m4-t5-physical-storage-linked-suite.json; reproduce with
python tools/verify_probe_storage_suite.py.

verify_probe_candidate.py now derives each module/slice base from ALL native
OMF code PUBLICs and requires consistent linked positions; source/object/map
hash checks remain enforced. Composite DEV source is reconstructed from the
same production tail plus IOFUNC candidate recipe and compared to the frozen
assembled source. Suite checks source proof hashes, one shared link-report
hash and absence of overlapping target/linked intervals. Existing graph
snapshot checks still protect production/COMMAND sources. New evidence covers
full disk/disk2/disk3, rom, mknode, dircall, share, create, delete, close,
finfo, rename, open, isearch, abort, handle, file, fcbio, fcbio2, lock and
DEV IOFUNC/openclose/I/O slices. The MSPROC and low-memory proofs remain
separate and are not double-counted in the 12800-byte total.

Next inspect the remaining unverified kernel/initialization and NT host seams,
then expand physical-kernel integration and byte-layout convergence. Production
remains m4-t5-lock-build.json; no bootable MSDOS.SYS or whole-file identity is
claimed. M4 T5 S2 remains active; IO.SYS and final deployment remain open.


Emitted host-call inventory and SEARCH recovery: tools/audit_probe_host_calls.py
checks every linked module's OMF LEDATA, emitted listing and actual linked
bytes for C4 C4 BOP encodings. Baseline m4-t5-host-calls-before-search.json
records 20 confirmed sites in ten modules, not merely textual macro mentions.
This inventory does not cover all indirect/other host dependencies.

DOS6-comparative search.full.recovery.asm is byte-identical to its reference
and preserves original procedure comments/register conventions. Complete
[1FFBh,21CCh), 465-byte module passes target-layout proof, including FCB and
pathname FindFirst/FindNext, PackName and GET_FAST_SEARCH. Eight external
call/jump target attributions are explicit; no data-placement overrides.
Evidence m4-t5-search-full-verification.json. Probe now uses this candidate
instead of NT host FindFirst/FindNext paths.

All 54 modules assemble and link on the private isolated desktop at
build/physical-sft-probe-9kaqvbeg. Actual SEARCH proof checks 465 bytes and
68 named fixups with zero remaining differences. The frozen storage suite
expands from 23 to 24 units (21 full modules plus three DEV slices): 13265
unique bytes and 1449 fixups all pass. Source graph expands with SEARCH;
production and COMMAND snapshots remain unchanged.

Current m4-t5-probe-host-calls.json confirms 16 emitted BOP sites in nine
modules; all four SEARCH BOPs are removed. Remaining modules: cpmio, getset,
ioctl, macro, misc, mscode, msctrlc, msdisp and path. Actual MSPROC/DOSTAB,
416-byte low-memory region and SFT startup/abort regressions pass against
this same link. Next recover remaining path/search-adjacent host seams and
continue initialization/whole-kernel convergence. Production remains
m4-t5-lock-build.json; M4 T5 S2 active. No runtime or final binary acceptance.


Complete PATH recovery: path.full.recovery.asm restores the comparative
physical current-directory, RMDIR, CHDIR, MKDIR and path-length routines.
Three EnterCrit/LeaveCrit macros become explicit EcritDisk/LcritDisk invokes
because the NT macros omit them. Preserve Microsoft structure/comments and
register conventions. Complete target [21CCh,233Ah), 366 bytes matches with
no data override. Two MOV SI pointers at 227Bh/22FDh are separately opcode-
checked against DOS_RMDIR=333Bh and DOS_MKDIR=31F6h; CS DosDseg access is
also checked. Proof m4-t5-path-full-verification.json.

All 54 modules assemble and link in private isolation at
build/physical-sft-probe-6tdpabi6. Complete actual-link PATH proof passes
366 bytes/43 named fixups. The finite storage suite expands to 25 units
(22 full modules plus three DEV slices): 13631 unique bytes and 1492 fixups,
all passing without target/linked interval overlaps. Kernel/COMMAND source
snapshots remain unchanged. Current host-call inventory confirms 14 BOP
sites in eight modules, down from 16: both PATH host calls are gone.
Remaining modules are cpmio, getset, ioctl, macro, misc, mscode, msctrlc,
msdisp; emitted BOP count is not proof of all host dependencies removed.

Actual MSPROC/DOSTAB, 416-byte LMSTUB and SFT startup/abort regressions pass
on this same linked probe. Next recover remaining device/drive metadata and
other host seams, then converge initialization and full binary layout.
Production remains m4-t5-lock-build.json; M4 T5 S2 active. No whole-file,
standalone runtime or final deployment acceptance.


Complete IOCTL physical recovery: ioctl.full.recovery.asm is byte-identical
to the DOS 6 comparative module, preserving original tables, comments and
register conventions. Physical sf.inc is used for the candidate. Complete
range [233Ah,2619h), 735 bytes, includes the 36-byte dispatch table preceding
$IOCTL at 235Eh. All bytes match at target layout with explicit callee bindings
(including GetThisDrv's external-frame fixups) and no data-placement override.
Evidence m4-t5-ioctl-full-verification.json.

Probe replaces NT IOCTL with this candidate. All 54 modules assemble and link
on private desktop at build/physical-sft-probe-9rgw96_c. Actual-link IOCTL
proof passes 735 bytes/103 named fixups. Finite storage suite now covers
26 units (23 full modules and three DEV slices), 14366 unique bytes and
1595 fixups, all passing. Both SVC_DEMIOCTL BOP sites are absent in emitted
linked code; current inventory is 12 sites in seven modules: cpmio, getset,
macro, misc, mscode, msctrlc and msdisp. This is not a full host-dependency
or runtime closure claim.

Actual MSPROC/DOSTAB, raw LMSTUB and SFT startup/abort regressions pass on
the same link. Accepted production/COMMAND snapshots remain unchanged.
Next recover remaining metadata/drive and dispatch/control host paths and
converge initialization and binary layout. M4 T5 S2 remains active; production
is still m4-t5-lock-build.json. Whole-file equality, standalone runtime and
final deployment remain outstanding.
