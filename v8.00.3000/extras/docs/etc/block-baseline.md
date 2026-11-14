# v7.10.2222 to v8.00.3000 initial binary comparison

The baseline products were checked against the v7.10.2222 manifest. The target files were extracted along the FAT12 chains of the image described in the [target manifest](target-baseline.json). Offsets below are zero-based byte offsets. A block starts from a 32-byte anchor unique in the baseline, then expands by direct byte comparison. The target spans are disjoint. Counts are localization evidence.

| Component | 2222 bytes | 3000 bytes | Observed reuse |
| --- | ---: | ---: | --- |
| `IO.SYS` | 222390 | 116736 | 559 exact bytes in 10 disjoint target spans |
| `MSDOS.SYS` | 4 | 4 | Whole file |
| `COMMAND.COM` | 93890 | 93040 | 60066 exact bytes in 230 disjoint target spans |

Largest COMMAND blocks:

| 2222 offset | 3000 offset | Exact bytes |
| ---: | ---: | ---: |
| 69728 | 68879 | 17116 |
| 4012 | 4074 | 9122 |
| 18848 | 18864 | 3559 |
| 89640 | 88790 | 2400 |
| 87238 | 86388 | 2395 |

The target IO.SYS contains a CM header at 0800h and another aligned CM candidate at 1BCE0h. Exact anchors in the packed file are confined to the first 2 KiB. Extract the uncompressed payload and identify its linked blocks before estimating BIOS or kernel changes. Verify the recovered packaging path by comparing a re-encoded complete image with the floppy target.

The auxiliary MSDOS8.ISO in the local collection contains a repack toolkit and a rebuilt floppy. Its IO.SYS and COMMAND.COM hashes differ from the OAK floppy, so the OAK floppy remains the identity target.
