# M0 T1 S1 baseline audit

The owner-supplied DOS 6.20 image was inspected read-only with the FAT12 inspector; both FAT copies matched and the three target chains were complete and non-overlapping. The complete results, file hashes and geometry are in [target-baseline.json](../etc/target-baseline.json). Independent temporary extractions were compared byte for byte with the project baseline.

The supplied image is 294,912 bytes while its BPB declares 1,474,560 bytes. The missing 1,179,648-byte tail and other files are not established; no image padding, modification, or mount was performed. The project target directory and `extras/build/` are Git-ignored.

S1 meets its scoped criteria. No DOS 6.20 source has been imported, built or declared restored. T1 remains open for S2, which will freeze the reference inventory and ordered file universe.
