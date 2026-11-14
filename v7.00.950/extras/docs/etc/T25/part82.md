# M6 T25 S1 P82, files 196–201

196 dos/msdisp.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Restored the boot-drive and HMA check comments and clarified the
subfunction-5 compare. Preserved the 950 Ctrl+C subfunction dispatch, PSP
fast paths, call-depth tracking, Disk_Full reset and exit flag handling.
Original NMAKE via the P72 probe rebuilt MSDISP and relinked the kernel at
extras/build/t25-msdisp-8908-10632. All 293 inputs matched the stage. Fresh
IO.SYS and inherited MSDOS.SYS and COMMAND.COM matched frozen targets.
See file196-build.txt and file196-make.txt.

197 dos/msdos.cfg, accepted_no_reference. The six-byte source payload
matches frozen MSDOS.SYS byte for byte by FC /B.

198 dos/msdos.lnk, accepted_necessary. The full diff adds 950 split
modules and moves existing entries into target link order. Preserved
that sequence and the effective v6.22 output directives.

199 dos/msdos.skl, 200 dos/msdosme.asm, 201 dos/mshalo.asm, accepted_exact.
Each matched its effective v6.22 supplier in v6.2/dos by FC /B.

Prefix 201/293. Modified 105, exact 31, necessary unchanged 28, no same-name
reference unchanged 37. Next 202 dos/msinit.asm.
