# M6 T25 S1 P73, files 179–181

179 dos/ioctl.asm, accepted_modified. Reviewed the full effective v6.22 diff.
Retained per-drive option handling, the removable-media and control-string
state transitions, CDS validation, device attributes and branch encodings.
Removed the unreferenced ioctl_do_string label after the character-device
jump moved to ioctl_control_device. Clarified the handle sentinel and the
drive-call category check.

Original NMAKE ran through the P72 diagnostic probe. IOCTL reassembled and
the kernel linked byte-identically to the prior stage. Fresh IO.SYS and
inherited MSDOS.SYS and COMMAND.COM matched the frozen targets with FC /B.
All 293 source inputs matched stage extras/build/t25-ioctl-4917-16047.
See file179-build.txt and file179-make.txt.

180 dos/isearch.asm, accepted_necessary. The complete reference diff adds
CheckCDSDrive before the local search and branches to the existing installed
redirector dispatch when required. Installed is TRUE in this module.
Kept the existing dispatch and conditional structure.

181 dos/kstrin.asm, accepted_exact. FC /B with effective v6.22 supplier
v6.2/dos/kstrin.asm reported no differences.

Prefix 181/293. Modified 93, exact 27, necessary unchanged 25, no same-name
reference unchanged 36. Separate tool change 1. Next 182 dos/lfn.asm.
