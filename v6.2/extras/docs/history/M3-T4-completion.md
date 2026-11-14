# M3 T4 three-component convergence audit

Status: closed for the selected USA configuration and the three complete binary equality criteria. This does not claim original 6.20 symbol names or byte-for-byte identity of the source text.

| Component | Bytes | SHA-256 |
| --- | ---: | --- |
| IO.SYS | 40566 | `a96905f6a7358dbddafbe1128e49e9996e7d416e007801b007573c1f0acf9bbf` |
| MSDOS.SYS | 38138 | `1ff320e7fdb3de707370e18d48d52b724b6f40f86ae7b70469bb130d754a904f` |
| COMMAND.COM | 54619 | `9b1d77119ac6fe4f949f574db1445b2848683c3a5aaa2bb09f52d0b538df3541` |

Each saved output was re-read and compared directly to its full image-derived target. All 226 recorded source and build-input hashes were rechecked against the current tree. The [build snapshot](../etc/three-core-comment-snapshot-build.json) records the fresh isolated stages; the [image audit](../etc/image-build-direct-audit.json) independently connects the retained targets to the three complete chains in the supplied image. The image tail is truncated outside those chains.

T4 S1 is IO.SYS; S2 is MSDOS.SYS; S3 is COMMAND.COM. Each meets the corresponding size and direct byte comparison criterion. The project uses external pinned historical tools. Reconstructed names and the three-byte STUB tail remain explicitly documented as historically uncertain; per the owner, that normal uncertainty does not prevent continuation. No target binary blob is used as build input and no output is patched.

This audit closes T4 only. It does not by itself claim T3 workflow documentation or final M4 acceptance.
