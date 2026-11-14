# M6 T25 S1 P92, files 267–287

267 inc/ms_data.asm, accepted_modified. The complete effective v6.22 diff
contains target zero padding and three saved directory scan records. Replaced
the reconstruction note with a description of the records. Original NMAKE
reassembled MSDATA and linked the kernel at t25-msdata-12676-27989. Fresh IO.SYS
and inherited MSDOS.SYS and COMMAND.COM matched frozen targets. All 293 inputs
matched the stage. See file267-build.txt and file267-make.txt.

| Sequence | File | Result |
| --- | --- | --- |
| 268–269 | mult.inc, oemconf.inc | Exact |
| 270 | origin.inc | Necessary. BYTSTART uses the 950 kernel-header origin. |
| 271 | parse.asm | Necessary. Preserved MASM-version-dependent LEA encodings, two short jumps and the overridable comparison macro used by parser callers. |
| 272 | pdb.inc | Exact |
| 273 | psdata.inc | Necessary. Preserved the SYSINIT large-buffer condition and caller override. |
| 274–277 | rombios.inc, sf.inc, smifssym.inc, syscall.inc | Exact |
| 278 | sysmsg.inc | Necessary. The transient class value and saved resource segment are part of the 950 message layout. |
| 279–282 | sysvar.inc, umb.inc, vector.inc, version.inc | Exact |
| 283 | versiona.inc | Necessary. Version 7.00 differs from the effective 6.22 overlay. |
| 284–286 | win386.inc, wpatch.inc, xmm.inc | Exact |
| 287 | yesno.asm | Necessary. The four zero-initialized fields in the 950 locale table replace generated message data. |

Each exact file passed FC /B against its effective supplier in v6.2/inc.
Prefix 287/293. Modified 117, exact 90, necessary unchanged 43, no same-name
reference unchanged 37. Next 288 lang/usa/messages/biosmsg.inc.
