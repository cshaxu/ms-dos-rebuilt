# 1111 to Win98 FE binary baseline

| Component | 1111 range or size | FE range or size | Evidence |
| --- | --- | --- | --- |
| IO.SYS | 214836 bytes | 222390 bytes | 109443 matched bytes across 804 ordered runs. |
| Boot loader | offsets 512–2047 | offsets 512–2047 | Entire 1536 bytes match by direct byte comparison. |
| BIOS | 2048–71938 | 2048–72798 | 49081 matched bytes across 357 runs; BIOS grows 860 bytes. |
| Kernel and its ending alignment | start 76128 | 77440–122927 | Kernel start follows BIOS message padding; FE logo bounds its end. |
| Compressed logo | 121520–186903 | 122928–189056 | 16 graphics blocks; FE resource is 66129 bytes. The packed graphics resource carries no executable code. |
| Configuration and registry | 187392–214835 | 189440–222389 | 18249 matched bytes across 163 runs; MZ header changes stack and entry segment. |
| MSDOS.SYS | 9 bytes | 4 bytes | FE contains hex 3B200D0A. |
| COMMAND resources | 64–16991 | 64–16959 | 15939 matched bytes; complete resident resource matches directly. |
| COMMAND linked body | 16992–93811 | 16960–93879 | 54007 matched bytes across 264 runs. |

Ordered runs use unique 32-byte seeds and direct byte comparison. Relocations, short or repeating regions and alignment can fall outside these runs. These are localization measurements.

The loader and resident messages can be reused whole. BIOS, kernel, configuration and COMMAND have dispersed changes, so the working source is a complete 1111-derived tree. The four changed primary messages are 1040, 1480, 1487 and 1932. Initialization class 5 changes message 13 and omits 32.
