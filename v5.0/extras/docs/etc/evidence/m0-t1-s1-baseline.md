# M0 T1 S1 — target and scoped reference baseline

Date: 2026-11-06. Evidence type A means directly observed in these inputs, not verified original provenance. The [manifest](m0-t1-reference-manifest.tsv) freezes 845 files in the 16 explicitly named scopes in `tools/reference_manifest.py`; its SHA-256 is `5e73a01c734a3af25f7dda2cead1b631fc87375bd4799f8f76a96a805762588f`. It covers BIOS, DOS, COMMAND and specified shared include/message directories, not every possible transitive build dependency. Re-run `python tools/reference_manifest.py <new-output.tsv>` and compare file hashes. The manifest identifies the actual files, independently of a Git revision. It does not establish that they are authentic, complete, or redistributable.

## Target inspection

`python tools/target_fat12.py <image>` reads the source without writing it; `--extract-new <new-directory>` writes only to a newly created directory. Target image SHA-256 and target file values are in CURRENT. FAT12 BPB: 512 bytes/sector, 1 sector/cluster, one reserved sector, two 9-sector FATs, 224 root entries, data offset 16896. Both FAT copies match. The three target chains contain 66, 74, 94 clusters, respectively; all are within the supplied bytes and do not overlap each other. An independent contiguous-slice SHA-256 computation reproduced all three hashes. This validates these target files, not the entire filesystem or image authenticity.

The supplied image ends at 258048 bytes, BPB declares 1474560, leaving 1216512 bytes absent. An independent FAT scan found no allocated cluster starting beyond the supplied length. That does not establish original missing bytes or integrity of other files. Zero padding is a test hypothesis, never a reconstruction of original media. Preserve the original image.

## Reference inventory and module leads

OpenNT primary scopes contain BIOS 30, DOS 62, COMMAND 54, includes 76, headers 33, messages 20 files. DOS 6 comparison scopes contain BIOS 51, DOS 79, COMMAND 70, includes 90. DOS 4 comparison scopes contain BIOS 39, DOS 86, COMMAND 43, includes 90, headers 20, messages 2. These are file counts, not validated module completeness. DOS 6 `messages` is absent. Other build scripts, libraries, tools and generated message resources are outside this frozen scope and need a dependency audit in M1.

Direct link-list comparison: OpenNT DOS lists 38 objects and DOS 6 lists 57; DOS 6 lists FAT, BUF, CREATE and DELETE which are absent from the OpenNT list. This is a lead, not proof that every corresponding implementation was deleted or that DOS 6 is identical to DOS 5. OpenNT COMMAND lists 34 objects, DOS 6 lists 35, with `cratio` present only in the latter list. Matching names do not prove matching code. Next investigation should map one COMMAND routine through source, generated objects and target offsets; build dependencies must be resolved first. The target's detailed language, OEM and authentic release origin remain unverified. OpenNT and DOS 6 redistribution permissions remain unresolved; DOS 4's local LICENSE is separately applicable to that source, not the other inputs.

## Verification

On 2026-11-06 ran the target inspector, extracted all three files into a temporary newly-created directory, and re-hashed each output. Deliberately damaged signature, one FAT copy, and truncated allocated data were rejected. Independently repeated the 845-file reference inventory; both manifest hashes matched. The temporary extraction and repeated manifest were removed. These checks do not demonstrate a build or VM boot. A scoped source inventory is not a transitive dependency inventory, and no SoftPC configuration or deployment was changed.
