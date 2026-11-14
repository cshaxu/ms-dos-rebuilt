# Growth continuation of the compaction/index test

Use the shared extract.c with its final `grow` argument:

    extract regread.asm regstr.asm configio.asm grow-prefix.asm grow-suffix.asm cptest.asm grow

Run with compact.cmd in the existing isolated build stage, as described in
README.md. This includes the actual RegGrowDataBlock, RegDirtyDataBlock,
RegPackDataBlock, RegIndexBlock, RegCopyBytes and RegMoveMemory routines.
Only ConfigRealloc is controlled, returning the same preallocated buffer or
failing as requested. Moving allocations are not covered by this fixture.

Check no allocation when existing free space suffices; rejection when the
required extent would exceed F000h; allocation failure with the old block
size retained; successful growth from A0h to 1000h with compaction, correct
FA0h free tail, cache size, record payloads, WORD offsets and boundary guards.
Pre-change source assembles/links but fails; current source passes.

The policy correspondence is RegGrowDataCache in historical disassembly
evidence regread.asm:6673-6765 (free-space check, page rounding, F000h bound,
0Eh failure, compaction before free-tail extension, no second index rebuild).
It is evidence for adapting the first path, not a second implementation to
link. Current file/cache structures and full routine bytes still differ.
