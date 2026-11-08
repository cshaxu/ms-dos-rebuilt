# Project goal

Reconstruct a research source package for the three MS-DOS 5.00 system files contained in the owner's supplied boot image. Use OpenNT NTIO, NTDOS and COMMAND as the primary source baseline; use MS-DOS 6 and 4 and the target binaries as comparative evidence. Organize source files and directories consistently with or close to the DOS 6 tree. Mark reconstructed material as reconstruction, never recovered original DOS 5 source.

Completion requires a documented, reproducible build from the source package and recorded dependencies that produces IO.SYS, MSDOS.SYS and COMMAND.COM each byte-for-byte identical to the target image, confirmed by exact comparison, length and SHA-256. Prebuilt target bytes, embedding the target binary as data, or patching a generated output with opaque target-byte blobs do not count as source reconstruction. Preserve meaningful source representation and report generated resources and toolchain dependencies. Byte identity alone does not establish historical source identity.

Per owner direction, SoftPC boot and runtime tests are not required for acceptance when the three source-built files match the original image byte for byte. Deployment destination is `O:\DOS`. Do not modify the supplied image. Record provenance and permissions; access does not establish redistribution rights. Project work is local unless separately authorized for publication.

The owner has directed the project to continue using the three already retained
system files as the target baseline; remounting the original image is not a
prerequisite. Subsequent source changes must preserve their byte identity.

The parent project's A direct evidence, B strong inference, C tentative and D unknown labels apply per claim. Unknown work remains explicit. Exact identity is the objective, not a promise that available materials are sufficient.
