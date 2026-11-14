# v7.10.1998 to v7.10.2222 binary baseline

Ranges are half-open byte offsets. Anchor displacements localize code changes and are separate from exact block comparisons.

| Component | 1998 | 2222 | Evidence |
| --- | --- | --- | --- |
| IO.SYS loader and outer header | 0–2048 | 0–2048 | 2,048 bytes identical |
| BIOS | 2048–72799 | 2048–72751 | Net 48-byte reduction. Anchors show distinct offsets within the block. |
| Message marker and padding | 72799–77440 | 72751–77392 | 4,641 bytes identical |
| DOS kernel and ending alignment | 77440–122928 | 77392–122880 | 45,488 bytes identical |
| Packed logo | 122928–189057 | 122880–189009 | 66129 bytes identical |
| Configuration and registry | 189440–222390 | 189440–222390 | 32,950 bytes identical |
| MSDOS.SYS | 4 bytes | 4 bytes | Entire file identical |
| COMMAND.COM | 93,880 bytes | 93,890 bytes | Resource and code anchors retain offset through much of the image. The first stable displacement is +9 by old offset 62,640. Later anchors and the version string are at +10. |

The source is an overlay of the frozen 1998 tree. The untouched modules and build tools come from that commit.
