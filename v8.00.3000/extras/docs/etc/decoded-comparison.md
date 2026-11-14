# v8.00.3000 decoded comparison and source baselines

The identity target is the OAK floppy in the [target manifest](target-baseline.json). Core code and existing startup integration start with the effective v7.10.2222 tree. The Astro component baseline is the `v6.0` tree in `ms-dos-archaeology` at `0f7d639c3afe716c1d4f566ee3c1cb5238d04f6c`. Preserve its directories, module boundaries, symbols and assembly conventions where target routines correspond. Adapt the existing callers and drivers in place.

## IO.SYS layout

The target begins its CM stream at file offset `0800h`. A read-only inspection probe decoded six DS chunks, five of 49,152 bytes and one of 32,256 bytes. The decoded payload is 278,016 bytes, SHA-256 `0d6ebe0add967e12d2974c636636bc2b2da00602e26bdafb2312fea118abf3bb`. The decoder consumed the stream through its terminator and reached the aligned CM trailer at `1BCE0h`. The [GRUB4DOS decoder](https://github.com/chenall/grub4dos/blob/0.4.6a/stage2/builtins.c) was used as a format reference during inspection. Build reproduction needs an encoder that matches the target stream.

The decoded payload includes a 320 × 400 BMP of 129,078 bytes at payload offset 147,552. The 2222 logo occupies 66,129 bytes in its packed resource layout. Measure code reuse separately from image representation.

| 2222 linked region | Exact bytes anchored in the decoded target |
| --- | ---: |
| BIOS | 30,526 |
| DOS kernel and alignment | 24,094 |
| Configuration and registry manager | 8,889 |

The 687 nonoverlapping target spans are seeded by 32-byte sequences unique within the 2222 payload and extended by direct comparison. Their 63,509 bytes are a lower bound on exact correspondence. Relocations and shorter unchanged instruction sequences can reduce anchor coverage. The order and placement of blocks changed, including a 4,106-byte BIOS block at 2222 file offset 23,486 and 3000 payload offset 73,525.

## Component source map

| Component | Target evidence | Source baseline and entry points |
| --- | --- | --- |
| HIMEM and XMS | An XMS character device header at payload offset 1,104 contains attribute A000h, strategy and interrupt offsets, and name XMSXXXX0. | Astro `dev/himem/himem.asm` for the header, request dispatch and INT 2Fh, then `himem1.asm`, `himem2.asm`, `himem4.asm` with `himem4a.asm` and `himem4b.asm`, and `himem5.asm` in the original makefile layout. Compare A20, HMA and XMS calls with the 2222 startup code. |
| SMARTDRV | Payload offset 93,019 contains the INT 2Fh call with AX=4A10h and BX=5, followed by the BABEh response check. A startup prompt refers to enabling SMARTDRV. Provider extent remains to be mapped. | Astro `dev/smartdrv/bambi.inc` defines BAMBI_GET_BUFFER_INFO for BX=5. Use `int2f.asm`, `bambinit.asm`, `cacheman.asm`, `cacheini.asm`, `hooks.asm`, `xms.asm` and the original makefile to locate provider code. Keep `doubleb` as the reference for related buffering where it corresponds. |
| EMS and EMM386 | EMMXXXX0 appears in the startup driver-name table alongside QMMXXXX0. A separate QEMM386.SYS string and an INT 67h instruction are present. The embedded EMS provider remains unverified. | Astro `dev/emm386/memm386.asm` for the device header, `emm.asm`, `emminit.asm`, `emmfunct.asm`, `emm40.asm` and `vcpi.asm` for EMS/VCPI. Consult `xms.asm`, `allocmem.asm`, `umbseg.asm` and `dev/monoumb` if target UMB or XMS interactions correspond. |
| IFSHLP | The payload contains the external filename, the IFS$HLP$ device name and a loading message. The name table has a direct 2222 equivalent. A separate provider and its extent remain unverified. | The searched Astro tree yielded no IFSHLP provider source. Map the inherited loader through 2222 `bios/sysinit2.asm` first, including `boot_check_ifshlp` and `boot_driver_table`. |

## COMMAND.COM and MSDOS.SYS

MSDOS.SYS is identical. COMMAND's MZ resource/header span grows from 16,960 to 17,104 bytes; the linked load image shrinks from 76,930 to 75,936 bytes. The 60,066 exact anchored bytes include 15,967 from the old resource/header span, 18,321 from TRANDATA, 4,388 from INIT, 887 from CODERES and 8,807 from TRANCODE. These span counts use the 2222 linker map and are sensitive to relocations. Start with the existing message resources, resident and startup code and transient code, comparing related linked functions before editing.
