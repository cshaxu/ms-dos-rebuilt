# Registry first-path migration: file and cache group

Reference: `v7.00.950` source; target: frozen `v7.10.1111` IO.SYS. Current
working source remains the production `v7.10.1111` first path. The pre-rollback
`extras/build/registry-reset/current` source is historical disassembly evidence,
not an implementation to append or a source of completion claims.

## Current 950-derived ownership

| Responsibility | Current production entry | Evidence / constraint |
| --- | --- | --- |
| File list and object lifecycle | `bios/regroot.asm:RegFileList`; `bios/regfind.asm:RegFileCreate`, `RegFileUnlink` | -1 empty marker, 3Ch-byte RGSF object and bidirectional links. `RegMaintainCache` walks both directions. |
| Read and initialize | `bios/regread.asm:RegReadFile`; `bios/reginit.asm:RegInitHeader`, `RegInitKeyBlock`, `RegInitDataBlock` | Existing file descriptor and cache offsets are consumed throughout the original path. |
| Save and cache maintenance | `bios/regread.asm:RegSaveFile`, `RegMaintainCache`, `RegScanDataBlocks`, `RegFlushDataBlock` | Existing scan uses a 12-byte entry, a retained pointer, `RegHasPendingState`, and a file-specific write path. |
| Allocation retry | `bios/regread.asm:RegAllocate` | Current DWORD size/options and reserve-block retry differ from target's WORD-sized cache reclamation strategy. |
| File teardown | `bios/regstart.asm:RegReleaseFileBuffers` and `bios/regfind.asm:RegFileUnlink` | Calls originate in registry API, file open and termination paths; migrate producers and consumers together. |

## Target correspondences, not extra production entry points

| Target responsibility | Previously identified target routine | Migration interpretation |
| --- | --- | --- |
| Open/file state creation | `RegOpenFileTarget` | Adapt `RegReadFile` and object creation. Target allocates pathname plus 59h bytes; file state, version flag and null-terminated list differ from 950. |
| File traversal | `RegForEachFile` at `014E:2300` | Adapt the existing list ownership and traversal as a unit; do not retain two independent lists. |
| Reclamation | `RegDiscardCache`, `RegTrimKeyCache`, `RegTrimDataCache`, `RegReleaseDataBuffers` | Split responsibilities of the existing maintenance/scanning/release path only where the target and actual call sites require it. Target key entries are 6 bytes and target data entries 14h bytes. |
| Save | `RegSaveFileState` at `014E:2088` | Adapt `RegSaveFile` and its actual dependencies; do not preserve a parallel save implementation. |
| Allocation | `RegAllocRetry` at `014E:2D80`; `RegReallocRetry` at `014E:2DD6` | Adapt `RegAllocate` and reallocation callers after the file list, reclaim and save callbacks use the target structures. |
| Teardown | `RegFreeFileTarget` | Adapt `RegReleaseFileBuffers` / `RegFileUnlink` and all callers to the same object layout. |

Version 2 requires more than the already-restored header version check. The
target open path sets bit 08h in its file state for version 2. The key-block
extent, key writer, key-header writer, save positioning, key-cache loading,
key-cache initialization and key allocation paths test that bit. In particular,
the key loader and writer take different raw/packed paths for version 2. The
current 950-derived file state and cache consumers do not yet implement that
protocol; version 2 must not be reported as supported end to end.

The earlier removal of `RegDosAlloc`, `RegDosFree` and `RegDosRealloc` was
incorrect: the target contains these routines as part of a 557-byte DOS-service
group, now verified in full against the target and restored. Existing current
consumers still use the 950-derived FAR `ConfigAlloc`, `ConfigFree` and
`ConfigRealloc`. Migrate actual registry consumers and structures to the target
contracts; currently unused target code does not establish a complete call chain.

The target names and addresses above describe previous matching work, not
current symbols or proof that the current code matches. See `T20-S2-P150.json`,
`T20-S2-P154.json`, `T20-S2-P155.json`, and the `registry-reset/current` source.
Earlier appended routines were explicitly removed under the owner's correction.

Current progress: the data-record index within the existing data-block path is
now 255 WORD block-relative offsets, including all three allocation sites and
the original lookup, free, assignment, allocation and resize consumers. The
larger 12-byte file-cache directory and its file-object layout remain 950-derived;
this change does not certify their compatibility with the target's 14h-byte
cache entries. See the `regindex`, `regindexchain` and `regindexstore` tests.

## Required migration boundary

### Path parsing and string ABI

The 950-derived `RegPathPart` copies and folds a component and returns the
next path pointer. It is called once in `RegFindAlias` (`reginit.asm`) and
three times in `regopen.asm`. The target path scanner observed in the
historical target reconstruction (`RegNextPathPart`) instead maintains a
cursor and returns a pointer and length, while target name comparison and
hashing accept explicit lengths. These interfaces are not interchangeable.
Migrate the original parser and its four active callers as one group, together
with the target cursor ownership and error handling; do not introduce a second
parser. As an intermediate step, the existing `RegFindAlias` and `RegSearchPath`
now hash and compare the original component pointer with its explicit length;
their existing parser remains responsible for validation and the shared buffer
is still used elsewhere. The counted `RegNameChecksum` and `RegCompareName`
are now single NEAR implementations with complete target-byte matches. The
FAR `RegNameSum` and `RegCompareN` adapters were removed after their callers
were migrated. The original `RegFindValue` is
now in `_TEXT` and calls `RegCompareName` directly; its four existing callers
use its FAR entry. The original `RegFindAlias` is also in `_TEXT` and calls
both target NEAR name functions directly; its five callers still use its FAR
entry. The original `RegSearchPath` now directly calls both target NEAR name
functions and keeps its FAR entry for the three existing external callers.
The original `RegAddMount`, `RegRebuildNameHashes`, and `RegPrepareSaveFile`
also call the NEAR checksum directly; the hash-rebuild routine hashes its key
record without a shared-buffer copy. The original `RegCreatePath` now directly
calls the NEAR checksum too. The linked-checker C tools verify migrated
bindings; the larger target call graph remains to be integrated.

### Value copy and enumeration boundary

The confirmed target `RegCopyValueTarget` is at `014E:2B84`. A scan for
direct 16-bit relative calls in the target code window `014E:0000..5FFF`
found one candidate, `014E:2D03`, already identified as the query call in
`datachaincheck.c`. This is not proof against indirect, far, or unaligned
references, but it is insufficient evidence that the legacy enumeration API
uses this helper. Do not propagate query-specific behavior to enumeration
without identifying and checking its actual target call chain.

1. Inventory every field use of the current RGSF and cache entries, including
   the public API and initialization/termination callers, before changing offsets.
2. Convert the file-object producers, list head and all walkers as one unit;
   convert cache allocation, lock/pin, discard and teardown consumers to the
   same target layout in that unit. Preserve FAT32 and unrelated work.
3. Integrate save/reclamation and allocation retry using those existing paths;
   delete superseded code only after all consumers have migrated.
4. Assemble affected modules, link the complete IO, compare each completed
   function to its target boundary and resolve every relocated reference. Update
   `FUNCTION-TRACKING.md` and its CSV from the actual linked result.

Until that unit is complete, don't reinterpret `RegFileList` as a zero-terminated
target list, truncate arbitrary old allocation sizes, or link a second path.
The full IO.SYS and COMMAND.COM are still not target-identical.
