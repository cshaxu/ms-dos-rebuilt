# 7.0a completion audit — 2026-11-12

The complete three-core reconstruction is accepted against the owner-provided
Win95 A image. [Fresh full-build evidence](etc/full-build-acceptance-20261112.json)
was independently checked against current files after the build exited zero.

| Requirement | Evidence and disposition |
| --- | --- |
| Complete v6.22-based tree, not an overlay | 358 existing active files, no unregistered source files; source-inventory-current.json and file-ledger.json. 125 modified, 95 unchanged, 138 added. |
| Exact IO.SYS | 223148 bytes, full comparison and SHA-256 agree. |
| Exact MSDOS.SYS | Six-byte configuration generated from text; full comparison agrees. |
| Exact COMMAND.COM | 92870 bytes, full comparison and SHA-256 agree; 35 linked modules, 34 modified and 1 unchanged. |
| Reproducible build | build_all.py executed successfully in all-core-2v_3k75u; all phases passed, including regenerated CRT adaptation. |
| Current source evidence | All recorded source/tool-script/resource hashes rechecked after execution; no change during or since the accepted build. |
| Tool and resource dependencies | build-dependencies-current.json: 15 tool/library/recipe hashes rechecked. Historical CRT and original boot logo explicitly declared. |
| Target stability | Original 1474560-byte image SHA-256 rechecked against target-baseline.json. |
| Project layout | Source directories bios/cmd/dos/inc/lang; metadata, tools, resources and scratch under extras. |
| Generated outputs excluded | git ls-files v7.0a/extras/build returned no paths; check-ignore confirms output exclusion. |
| No NT/BOP additions | Whole-word source scan found no NTVDM/NTDOS/NTIO/BOP markers. |
| Runtime constraints | Build tools use the existing private-desktop launcher; no Computer Use or boot acceptance. |

M0 materialization, M1 mapping, M2 reconstruction and M3 integration are
supported by the retained historical component records and the final complete
build. M4/T4/S1 closes the delivery audit. Historical pending per-file review
labels are preserved as provenance of earlier reviews; they do not mean that
binary recovery is pending. Every active file now has a current delivery hash,
baseline disposition and reference to the accepted build.

The supported result is a source reconstruction producing the exact three
files with the documented historical dependencies. It is not proof of original
Microsoft source text, nor reconstruction of the historical CRT library or
boot-logo compressor. Original non-executable artwork is retained as a resource.
No executable target is copied into the outputs. Compatibility adaptation of
CRT aliases preserves its original code/data records; source-generated OMF
serialization follows registered recipes for the historical linker.

No archive, deployment, commit or publication was requested for this delivery.
The root README gives the supported command and dependency locations.
