# Registry storage migration boundary

Current image: 233548 bytes; target: 214836. Confirmed IO functions: 461.
This document changes implementation order; it does not claim new alignment.

## Corrected dependency evidence

The production graph contains the old save/load/maintenance cycle. The
separately selected historical target reconstruction contains 84 procedures
and 248 direct-call, tail-call and pushed-procedure-offset sites. Its graph
has 84 singleton SCCs: no cycle is found within that selected graph. Do not
infer a target cycle from the current 950-derived implementation.

The selection deliberately excludes the historical parallel original path.
It is a finite candidate inventory, NOT a complete IO.SYS symbol table and
NOT proof that all historical function identities or bytes are correct.
Unresolved edges are three CRT helpers (__aFuldiv, __aFlshl, __aFulshr) and
two indirect call sites (RegWalkKeyRecords and RegForEachFile). Pushed callback
references are included as conservative dependencies, not as direct calls.
Shared layout dependencies must still be reviewed explicitly.

## First integrated unit: save and reclaim, then allocation

The target graph orders this unit before cache loading, file opening and
public APIs. The correspondences below are implementation responsibilities;
they are not permission to append Target-suffixed parallel functions.

| Target evidence routine | Existing production responsibility | Required disposition |
| --- | --- | --- |
| RegTrimKeyCache | RegMaintainCache / RegReleaseFileBuffers | Add the target key-cache reclamation behavior within the original cache domain; share ownership with release. |
| RegReleaseDataBuffers | RegFlushDataBlock / RegFreeDataBlock | Consolidate release of the block and index under one cache-entry contract. |
| RegTrimDataCache | RegScanDataBlocks | Adapt selection flags and lock count to the target cache entry. |
| RegDiscardCache | RegMaintainCache | Replace the old save/load cycle with the target reclaim traversal. |
| RegForEachFile | RegMaintainCache / RegFlushAll traversal | One file list and one callback traversal; remove superseded traversal once consumers switch. |
| RegKeyOffsetToIndex / RegKeyIndexToOffset | RegLoadKey / RegGrowKeyBlock address calculations | Target version-2 packed key addressing; explicit helper functions are justified by target routines, not a second file model. |
| RegKeyBlockExtent | RegSaveFile key-size calculations | Share the same version flag and packed-key model as loading. |
| RegEncodeKeyRecord | RegSaveFile key serialization | Target version-2 encoding, paired with the loading decoder. |
| RegWalkKeyRecords | RegRebuildNameHashes / key-block walks | Separate traversal from target callback transformations; do not rehash when only encoding is required. |
| RegCopyFileRange | RegSaveFile unchanged-range copying | Preserve common range-copy logic; use the single transfer workspace. |
| RegWriteKeyBlock / RegWriteKeyBlocks | RegSaveFile key writer | Adapt the existing writer, including version-1 and version-2 formats required by the target. |
| RegWriteDataBlocks | RegWriteDataBlock / RegSaveFile | One writer using the target cache metadata and dirty flags. |
| RegCommitDataCache / RegCommitKeyCache | RegSaveFile success cleanup | Clear state only after successful persistence. |
| RegSaveFileState | RegSaveFile | Preserve corresponding open/write/rename/error branches where target evidence supports them. |
| RegAllocRetry / RegReallocRetry | RegAllocate / ConfigRealloc consumers | Switch only after save/reclaim callbacks and their shared objects use the target ABI. |

This unit must not be implemented as unused appended bodies. File-object and
cache-layout producers/consumers must be changed together before activating
the new contract. Existing public entry names remain anchored to the original
source modules. A complete linked image and direct corresponding-region
comparison are required to report integration progress.

## Following units

1. Key/data cache allocation, initialization, load, unlock and indexed fetch,
   using the same file/cache ownership established above.
2. File open/create/free, root binding and lifecycle; switch their callers
   together. Remove superseded ownership code rather than retaining adapters
   indefinitely.
3. Path/handle/query entry integration and final CONFIG placement/bindings.

The current 20 exact CONFIG bodies are already counted inside the 461 IO
functions; they are not additional completed work. Remaining candidate
correspondences need verification before any percentage is meaningful.

## Reproduction

Run registry_graph with registry-target-ranges.txt against the retained
extras/build/registry-reset/current evidence directory. Outputs are
target-registry-calls.csv and target-registry-groups.txt. They are analysis
artifacts only; historical source is not copied into production.

Core files changed by this dependency correction: 0. Newly certified identical
files: 0. No new whole-function binary alignment. No rebuild or publication.
