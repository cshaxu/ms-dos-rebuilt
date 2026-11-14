# Current function and symbol tracking

Verified stage: `extras/build/cmd-4039-24987`, clean build on 2026-11-13.
All three complete generated outputs match the frozen 1111 targets byte for
byte. The inventory generator performs this comparison itself before reading
MAP/LST files or writing a new inventory. An older mismatching build was
rejected with `Full image comparison failed`.

| Output | Linked unit | Public names | Distinct segment:offset pairs | Explicit public procedures |
| --- | --- | ---: | ---: | ---: |
| IO.SYS | MSBIO | 766 | 744 | 241 |
| IO.SYS | KERNEL | 897 | 835 | 198 |
| IO.SYS | CONFIG | 332 | 318 | 131 |
| COMMAND.COM | COMMAND | 1311 | 1271 | 204 |

IO.SYS therefore has 1995 public-name rows and 570 explicitly declared public
procedure entries in these three linked units. COMMAND has 1311 and 204,
respectively. MSDOS.SYS is nine bytes of configuration text and has no function
table. The loader and precompiled CRT members do not all supply assembler
procedure declarations, so this is not a count of every executable routine.

The original 1111 distribution has no complete symbol table. Its original
function count remains unknown. Public names can identify data, labels or
aliases; even distinct segment:offset pairs are not a function denominator.
The procedure column requires a MASM 5 or MASM 6 listing declaration marked
Global/Public and a matching current linker public in the appropriate unit.
Private procedures and label-only routines are not included in that column.
Procedure aliases may represent the same underlying routine.

`symbol-inventory-current.csv` records each name, linker address, declaration
kind, source listing and declared procedure length. `whole_image_exact` means
that the containing output was fully byte-compared; it does not mean the name
is an original Microsoft symbol or that each target function was independently
identified. The inventory does not assign unverified target offsets to packed
CONFIG procedures.

Reproduce from the version root, with a current verified build directory:

```bat
gcc -O2 -Wall -Wextra -Werror extras\tools\tracking\symbol_inventory.c -o extras\build\symbol_inventory.exe
extras\build\symbol_inventory.exe extras\build\cmd-4039-24987 extras\baselines\targets extras\docs\tracking\symbol-inventory-current.csv
```

Source snapshots, linker maps, assembler listings, comparison logs and final
hashes are retained in that stage; see `full-build-2026-11-13.md`.
The older `verified-functions.csv` and `symbol-inventory.csv` are historical
partial investigations. Their 461-function snapshot and candidate-coverage
percentages are superseded for current progress reporting and must not be
combined with the above counts. Whole-image identity is verified; the completed
task-wide source-reuse and build-policy audit is in `../T20-CLOSURE.md`.
