# M6 T25 S1 P89, files 225–256

Each exact file below passed FC /B against its effective v6.22 supplier
in v6.2/inc. The frozen inventory and reviewed manifest identify each
file and its hash.

| Sequence | Files | Disposition |
| --- | --- | --- |
| 225–226 | bootform.inc, bpb.inc | Exact |
| 227 | buffer.inc | Necessary. DISKBUFFINFO avoids colliding with the separate Buffinfo structure in sysvar.inc. Fields and layout match. |
| 228 | bugtyp.inc | Exact |
| 229 | const2.asm | Necessary. The sole change emits a fixed zero byte in place of location-dependent EVEN padding before DAY. Retained to preserve the target data representation. |
| 230 | copyrigh.inc | Necessary. The 950 identification string differs from the effective v6.22 overlay string and is emitted by BIOS and COMMAND sources. |
| 231–237 | cpmfcb.inc, cputype.inc, curdir.inc, dbcs.sw, devsym.inc, dirent.inc, doscntry.inc | Exact |
| 238 | dosmac.inc | Necessary. The three version guards allow the inherited INVOKE name and guard MASM 5 pass-two constructs. The BIOS makefile uses ML as well as MASM. |
| 239–242 | dosseg.inc, dossym.inc, dpb.inc, dpl.asm | Exact |
| 243 | ds_vers.inc | Necessary. Revision 12 is consumed by BIOS syspre.asm for its revision fields/check. |
| 244–251 | ea.inc, error.inc, exe.inc, fastopen.inc, fastxxxx.inc, filemode.inc, find.inc, highexit.inc | Exact |
| 252 | highload.inc | Necessary. The /L branch omits the standalone incArgc call, preserving the 950 argument-count behavior. |
| 253–256 | highvar.inc, int2a.inc, intnat.inc, ioctl.inc | Exact |

No source files in this part changed. Prefix 256/293. Modified 114,
exact 69, necessary unchanged 36, no same-name reference unchanged 37.
Next 257 inc/lmstub.asm.
