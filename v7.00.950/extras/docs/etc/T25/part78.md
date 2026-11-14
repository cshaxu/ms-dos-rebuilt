# M6 T25 S1 P78, files 188–189

188 dos/misc.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Aligned EXTRN and DriveFlags formatting and documented the access and
deferred-write groups. Preserved CDS validation, the CS cache reference,
deferred flush, SFT inheritance checks and target instruction encodings.

189 dos/misc2.asm, accepted_modified. Reviewed the complete effective v6.22
diff. Updated module contents and removed the unused RetryLoop and fSharing
declarations after Idle moved. Aligned the CheckCDSDrive heading and procedure
declaration. Retained drive state handling and the target comparison encoding.

Each module reassembled and linked separately via original NMAKE and the
P72 diagnostic probe. Both stages verified all 293 source inputs and packed
fresh IO.SYS. FC /B passed for all three frozen targets. MSDOS.SYS and
COMMAND.COM were inherited. See file188-build.txt and file189-build.txt,
and their corresponding make logs.

Prefix 189/293. Modified 100, exact 27, necessary unchanged 26, no same-name
reference unchanged 36. Next 190 dos/mknode.asm.
