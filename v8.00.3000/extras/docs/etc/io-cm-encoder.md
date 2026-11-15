# T29 S3 CM/DS encoder and IO container boundaries

Run `v8.00.3000\extras\build.cmd io-baseline`. The baseline decodes the frozen Windows Me OAK IO.SYS, encodes the independently checked 278,016-byte payload with `cmencode`, and compares the resulting stream directly to the original beginning at file offset 2,048. Stage `io-20237-4893` exited 0 with unchanged input snapshots. Its `out/3000-cm.bin` has 111,840 bytes and SHA-256 `2449df70b070839b18fb9f24c45583663f3a1e22687bd0390a59d9f1cf1c3214`.

| Packed file interval | Role | Evidence |
| --- | --- | --- |
| [0, 2048) | MZ header and boot loader | S2 loader anchors, with loader assembly recovery outstanding |
| [2048, 113870) | CM signature and six DS blocks | All bytes reproduced from the decoded payload |
| [113870, 113888) | Three-byte CM terminator and 15 alignment bytes | All bytes reproduced |
| [113888, 113914) | Trailer header and bit-dispatch table | CM signature, entry 001Ah and eight linked state offsets |
| [113914, 116616) | Startup DS decompressor | 16-bit segmented code with eight bit lanes and a far return |
| [116616, 116736) | End padding | 120 zero bytes |

The encoder uses 96-sector chunks. Within each chunk, all earlier positions are searchable up to distance 4414. At each position it chooses the longest match that fits the 512-byte output sector and chooses the nearest position for tied lengths. A match starts at length two, with literals for positions with no match. The dictionary is retained across sectors and reset between CM chunks. A sector ends with a 15-bit marker. The target uses the DS header bytes 44h, 53h, 00h, 01h. The match rule was checked against 75,278 decoded tokens, including 543 sector markers. [Microsoft's MRCF description](https://patents.google.com/patent/US5455577A/en) provides a format reference. The verified match selection version here was derived from the target trace.

A separate 49,443-byte input round-tripped through the C encoder and decoder across a CM chunk boundary and a partial final sector. The reference IO.SYS is opened only for optional comparison. The encoded stream is constructed solely from its payload input. Later integration must source-build the loader and the trailer decompressor and feed the linked 3000 payload into the encoder.
