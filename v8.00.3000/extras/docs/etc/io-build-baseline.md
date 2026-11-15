# T29 S2 IO.SYS comparison baseline

Run `v8.00.3000\extras\build.cmd io-baseline` from a checkout with the frozen IO.SYS target in `v8.00.3000\extras\baselines\targets`. The command builds the effective v7.10.2222 IO source at `0e557eb928f84339d1718c82e15fbfe163526aa8`, using the pinned v7.10.1998 tree and the 2222 overlay from that commit. It runs the inherited assembler, linker and packaging steps, checks the 2222 output hash and decodes the 3000 target into a separate payload file. COMMAND remains the default build invocation.

Stage `io-17513-19154` built the reference from source and exited 0. Its IO.SYS was independently compared byte by byte with the verified 2222 copy. Its decoded payload independently matches the earlier read-only decode. The before and after input snapshots match. A focused configuration link with explicit DOS 8.3 output names reproduced both CONFIG-R.EXE and CONFIG-R.MAP. All 242 staged baseline paths in bios, dos, inc and lang match the corresponding 2222 source byte for byte.

| Stage output | Bytes | SHA-256 |
| --- | ---: | --- |
| `out/IO.SYS` | 222390 | `2db8f238742c374f264ead1c44f87d69af42c24688a3a80f7d9657bc952d5d20` |
| `out/3000-payload.bin` | 278016 | `0d6ebe0add967e12d2974c636636bc2b2da00602e26bdafb2312fea118abf3bb` |
| `bios/CONFIG-R.EXE` | 33781 | `37e847cb84143e9de44d36214f7918dff6ea7b211a27400149339a915efc924a` |

## Address coordinates

| Reference component | Link map | Comparison bytes |
| --- | --- | --- |
| Loader | `bios/MSLOAD.MAP` | `bios/MSLOAD.EXE` after the 512-byte MZ header. The final IO container uses linked offsets 512 through 2047. Compare that range in packed-file coordinates for the 3000 loader. |
| BIOS and SYSINIT | `bios/MSBIO.MAP` | `bios/MSBIO.BIN` at linked offset 0, relocated to segment 70h by the historical build. The 2222 packaged range is [2048, 72751). |
| DOS kernel | `dos/MSDOS.MAP` | `dos/MSDOS.BIN` at linked offset 0. The 2222 container stores the trimmed `dos/MSDOS.SYS` at offset 77,392. |
| Configuration manager | `bios/CONFIG-R.MAP` | `bios/CONFIG-R.EXE` after the 1,024-byte MZ header. The baseline packages the separately EXEPACK-linked `bios/CONFIG.EXE` at IO offset 189,440. |

All tabular offsets are zero-based decimal. Reference intervals are half-open. [Object ranges](io-object-ranges.tsv) maps segment offsets to original object and source names. It cross-checks each recoverable object base against linker publics and uses response-file order and OMF alignment for the remaining identified ranges. Rows with absolute address spaces, merged padding or memory-only extents have empty file offsets. CRT names come from the pinned library objects.

[Target anchors](io-target-anchors.tsv) maps directly equal byte ranges to 3000 packed-file or decoded-payload offsets. It uses 32-byte anchors unique within the comparison source set, extends by direct byte comparison, and splits matches at object boundaries. The results are a lower bound. Address operands and identical runs shorter than the anchor threshold can leave gaps.

| Reference component | Exact bytes in 3000 | 2222 objects with anchors |
| --- | ---: | ---: |
| Loader | 618 | 1 |
| BIOS and SYSINIT | 30911 | 23 |
| DOS kernel | 24036 | 59 |
| Configuration manager | 9123 | 16 |

For example, payload offset 73,525 has a 4,106-byte exact match at linked BIOS offset 21,438 in `msbio1.obj`. Payload offset 139,921 has a 983-byte match at raw configuration offset 22,463 in `regread.obj`. These are exact subranges. The complete object extents in the 3000 payload remain to be mapped where the boundaries are unclear.

## 3000 landmarks and next evidence

- Packed offsets [0, 2048) contain the outer header and loader. CM starts at 2,048. The six DS blocks and terminal offsets are recorded in the reproducible `cm-layout.tsv` output. The aligned trailer occupies [113888, 116736).
- The decoded image contains the XMS device header at 1,104, BIOS/SYSINIT and DOS kernel anchors, and configuration/registry anchors. The XMS object boundaries and provider extents for SMARTDRV, EMS and IFSHLP remain open. Existing [Astro component references](decoded-comparison.md) apply when recovering those capabilities.
- `IOSYSMSG` markers at payload offsets 30,522 and 118,295 carry length words 600 and 5,865. The following `MPAD` runs end at 31,108 and 123,981. A 320 × 400 BMP occupies [147552, 276630).
- S3 uses the frozen decoded payload for encoder comparison. The full 3000 IO.SYS acceptance gate belongs to the final integration S.
