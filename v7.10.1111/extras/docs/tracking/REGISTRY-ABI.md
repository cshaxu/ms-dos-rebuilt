# Shared storage ABI required for the integrated migration

Evidence is the selected historical target reconstruction, not newly verified
production bytes. Offsets below are read from producers AND consumers; do not
use the older 950 cache offsets with the target allocation/reclaim policy.

## Target file state

| Offset | Storage | Producer / consumer evidence in historical regread.asm |
| --- | --- | --- |
| 00h | next active file FAR pointer | RegOpenFileTarget 7458-7464; RegForEachFile 5081-5092 |
| 04h | key-cache table FAR pointer | RegInitKeyCache 6097-6100; RegTrimKeyCache 3881-3884 |
| 08h | key-cache entry count WORD | RegInitKeyCache 6101-6102; RegTrimKeyCache 3880,3885 |
| 0Ah | key-cache allocated capacity WORD | RegInitKeyCache 6081,6103 |
| 0Ch | key-storage length DWORD | RegInitKeyCache 6121-6125 |
| 10h | data-cache table FAR pointer | RegInitDataCache 5980-5983; RegTrimDataCache 3964-3967 |
| 14h | data-cache allocated capacity WORD | RegInitDataCache 5984-5985 |
| 16h | embedded CREG header (20h bytes) | RegOpenFileTarget 7383-7393 |
| 26h | data-block count WORD inside CREG header | RegInitDataCache 5963; RegFreeFileTarget 7215,7226 |
| 36h | embedded RGKN header (20h bytes) | RegOpenFileTarget 7413-7423 |
| 56h | file state flags | RegOpenFileTarget 7410; RegDiscardCache 3852-3862; RegUnlockDataCache 5535 |
| 58h | inline NUL-terminated pathname | RegOpenFileTarget 7339,7355-7374 |

The current first path instead allocates a 3Ch-byte signed object, two list
links, separately allocated headers and a separate pathname. File creation,
read, save, release, root/handle access and traversal cannot switch offsets
independently. There must remain only one active file-object representation.

## Target data-cache entry (14h bytes)

| Offset | Storage | Evidence |
| --- | --- | --- |
| 00h | data block FAR pointer | RegAllocDataCache 5284-5285 |
| 04h | 255-WORD index FAR pointer | RegAllocDataCache 5289-5293; RegIndexDataCache 5321-5323 |
| 08h | block byte size WORD | RegInitDataCache 6019-6020 |
| 0Ah | total free bytes WORD | RegInitDataCache 6021-6022; RegTakeDataExtent 6844 |
| 0Ch | next free record number WORD | RegInitDataCache 6023-6024; RegNextDataIndex 6869,6905 |
| 0Eh | backing-file position DWORD | RegInitDataCache 6015-6018 |
| 12h | cache state flags BYTE | RegTrimDataCache 3972-3985; RegUnlockDataCache 5533 |
| 13h | active reference count BYTE | RegTrimDataCache 3976; RegUnlockDataCache 5529 |

In particular, 0Ch is NOT the backing-file DWORD position. The target position
is at 0Eh; a mechanical conversion of the old 12-byte table would corrupt the
next-free record state. The current index pointer is in the block header;
the target owns it in the cache entry. The current block high-size WORD is
not interchangeable with the target free-space WORD at entry+0Ah.

Target key-cache entries are six bytes: FAR block pointer, state byte at +4,
active reference byte at +5 (RegTrimKeyCache 3888-3905).

## Why save/reclaim cannot be activated alone

RegDiscardCache calls key and data trim without saving. RegAllocRetry and
RegReallocRetry subsequently invoke save and another discard pass. That is
safe only under the same ownership and active-reference protocol as the target
load/fetch/unlock routines. Current RegScanDataBlocks retains one caller-supplied
block; it does not implement target cache-entry reference counts. Merely moving
RegSaveFile calls out of RegMaintainCache would not complete that protocol.

The integrated edit must include cache table allocation/initialization,
load/fetch ownership, all matching unlock calls, reclaim conditions, file
teardown and the allocation/save callback sequence. No production instructions
were changed by this audit. This is not an external blocker and requires no
new user approval; it defines the implementation dependency boundary.
