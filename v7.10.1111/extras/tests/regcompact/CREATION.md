# Creation continuation of the compaction/index integration

    extract regread.asm regstr.asm configio.asm create-prefix.asm create-suffix.asm cptest.asm create

Run through compact.cmd in the existing isolated stage. Uses actual
RegAppendDataBlock, RegNewDataBlock, RegIndexBlock, RegBlockEndOffset,
RegDirtyHeader and RegFreeDataBlock. Allocation/reallocation/free are controlled;
the reallocator returns the same table buffer. Moving-table reallocation and
persistent disk storage are not certified by this fixture.

Verify first allocation failure releases nothing; second allocation failure
releases the first buffer; successful append produces a 1000h block for 60h
required space, FE0h free extent, increments both block counts and clears all
255 WORD index entries. Check buffer guards and two frees on teardown.
The validator stub exists only for the pre-change negative control; current
creation calls the real index builder. Negative control fails, current passes.

Target correspondence: historical regread.asm RegCreateDataBlock, lines
6595-6598 (page sizing), 6637-6659 (free record then index rebuild). The original
RegAllocateRecord caller bounds the required extent at EFE0h before append.
This is an in-place first-path adaptation, not proof of whole-function byte
identity. File/cache metadata still follows the transitional 950 layout.
