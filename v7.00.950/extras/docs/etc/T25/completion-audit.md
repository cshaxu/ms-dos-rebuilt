# M6 T25 S1 completion audit

The v7.00.950 source quality audit is complete. The frozen sequence contains
293 files across bios, cmd, dos, inc and lang. The final repository path set
matches that scope. The closeout probe checked every raw DIR ordinal against
dir-raw.txt, all current source hashes against reviewed.csv, and all 225
effective supplier hashes against reference.csv. The inventory and reviewed
manifest agree on every disposition.

| Disposition | Files |
| --- | ---: |
| Modified and verified | 117 |
| Byte-identical to effective v6.22 | 90 |
| Necessary differences retained | 47 |
| No same-name supplier, retained after review | 39 |
| Pending | 0 |

The sequential packets and their build records describe the source changes,
the retained differences and the affected compilation checks. The separate
ioimage.c tool correction from P1 makes map symbol lookup case-insensitive.
It is outside the 293-file count.

The clean production run used extras/build.cmd at audit source commit
11665c1. The new stage was extras/build/cmd-13107-4986. The build compiled
BIOS, kernel, COMMAND, messages, configuration and registry, and exited 0.
The source snapshots before and after build compared byte for byte. All 293
current source inputs matched the staged copies. FC /B passed both before
publication and in the independent comparison of published assets with the
frozen targets. Build output stays in the ignored build directory.

| Output | Bytes | SHA-256 |
| --- | ---: | --- |
| IO.SYS | 223148 | 477eb53a2b3b81cefe58bcad409c682044e4ee4bf35dad678f80e1c5afbf35a5 |
| MSDOS.SYS | 6 | d28c3a421236bb61081f706193f51f32b9f8b957598d94b6b3b143ae52b1ea03 |
| COMMAND.COM | 92870 | a74c700063cd6b1c91523952bfc80e9393c125d39ada0164d48b5098089fcef3 |

Evidence is in final-build.txt, final-manifest.txt, final-outputs.sha256 and
the numbered audit packets. The LFN interface cross-check is recorded in
lfn-xp-contracts.md. This closure covers the frozen quality audit and target
reproduction. Exhaustive XP LFN runtime and boundary-case validation and
historical provenance are separate from the byte proof.
