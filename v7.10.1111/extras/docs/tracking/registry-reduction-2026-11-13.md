# T20 S4 P1 - Registry source reduction

Owner request: reduce actual implementation differences against v7.00.950,
preserving Microsoft module/procedure style and exact v7.10.1111 outputs.
Formatting-only substitutions are excluded from this packet.

## Implemented changes

One production source file changed: `bios/regread.asm`.

| Procedure | Change |
| --- | --- |
| RegKeyIndexToOffset | Replace two DB/DD instruction encodings with ADD EAX,DWORD PTR immediate. |
| RegWalkKeyRecords | Replace one DB/DD instruction encoding with ADD EAX,DWORD PTR immediate. |
| RegLoadKeyCache | Replace DB 66h / ADD AX,20h / DW 0 with ADD EAX,DWORD PTR 20h. |

Four instructions now use normal MASM syntax. Five source lines removed;
no new procedure, macro, conditional path, file or build-tool modification.
The explicit DWORD PTR preserves the required full-width immediate encoding.
This is encoding-expression cleanup, not an algorithm merger or a claim that
the registry implementation has become identical to 950.

## Comparison limits

The 950 RegNameSum accepts a terminated string; the current RegNameChecksum
uses an explicit count. The 950 RegAllocate retries by releasing reserved
memory; the current routine retries after cache maintenance and file save.
RegCompareN and RegCompareName also differ in argument layout and machine
instructions. These bodies were not replaced solely on semantic resemblance.

The explicit operand-size prefixes in regstart, regopen, regfind and regread
were inspected, together with configio. MASM 5.10A emits ES/operand-size
prefixes as 26 66 for normal DWORD ES operands, while these target sites use
66 26. They remain unchanged; no new macro or tool patch hides this constraint.

## Verification

Production entry: `extras/build.cmd <nul`.
Clean build: `extras/build/cmd-14133-21559`.
The build returned zero. All three full outputs passed FC /B and SHA256 and
were published to `extras/assets`; before/after input snapshots also matched.
Final result is retained in that stage's `result.txt`, `outputs.sha256`,
`inputs-compare.log` and individual output compare logs.

Core inventory remains 291 current files: 174 byte-identical to 950,
116 modified and one added; three baseline files are absent.
This packet changes one source file; zero files newly become identical to 950.
The broader registry reuse/reduction audit remains open.
