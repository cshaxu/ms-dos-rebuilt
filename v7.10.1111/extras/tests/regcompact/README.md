# Registry compaction and WORD index integration

Extract complete RegPackDataBlock and RegIndexBlock from regread.asm,
RegCopyBytes from regstr.asm and RegMoveMemory from configio.asm. No storage
or copy stubs are used. The test builds with MASM/LINK on the isolated desktop.

The fixture has three live records, multiple holes and a trailing free extent;
the middle moved record overlaps its old location. Check record payloads,
WORD offsets for IDs 0, 2 and 254, cleared unused slots, the merged free tail
and guards around both the data block and the 255-WORD index.

Compile extract.c with the native C compiler. Arguments:

    extract regread.asm regstr.asm configio.asm prefix.asm suffix.asm cptest.asm

Copy generated cptest.asm to the existing build stage's bios directory and
compact.bat / compact.cmd to the stage root; run compact.cmd there. An optional
eighth command-line token includes the old RegRelocateIndex for the pre-fix
negative control. That control assembles/links but exits FAIL; the corrected
source exits PASS. Do not run this concurrently with another stage build.

This test proves the existing first-path compaction/index integration. It does
not certify the target function bytes or the full registry storage lifecycle.
