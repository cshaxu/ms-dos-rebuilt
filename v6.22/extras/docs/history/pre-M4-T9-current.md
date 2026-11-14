# Current state: MS-DOS 6.22 core reconstruction

The source overlay builds IO.SYS, MSDOS.SYS, and COMMAND.COM byte-for-byte equal to the extracted MS-DOS 6.22 boot-image files. See [final build evidence](../etc/final-build-evidence.json) and [target baseline](../etc/target-baseline.json).

The source inventory contains 220 files: 7 modified relative to 6.21 and 213 inherited without a v6.22 change. Inheritance is a baseline status, not a claim that every original 6.22 source file has been independently recovered. The complete list and baseline hashes are in [file-ledger.json](../etc/file-ledger.json). The reconstructed DriveSpace portions and their inferred identifiers represent a source-level reconstruction; byte identity verifies the output, not the original source wording.
