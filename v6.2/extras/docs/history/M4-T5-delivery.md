# M4 T5 delivery record

The v6.2 worktree contains the selected IO.SYS, MSDOS.SYS and COMMAND.COM source trees, required USA message sources, and project metadata under extras. The [ordered ledger](../etc/file-review-ledger.json) has no pending entries.

The [fresh build snapshot](../etc/three-core-comment-snapshot-build.json) records 226 source/build inputs and three byte-identical outputs. The current hashes of all 226 inputs, actual output bytes and image-derived baseline hashes were independently rechecked for this delivery record. [Image audit](../etc/image-build-direct-audit.json) links the baselines to the three complete chains in the supplied, otherwise truncated, image.

Build output and target baselines are ignored by Git. The worktree is delivered in place; no package, deployment, commit, or runtime VM verification was requested. Historical assembly tools, DOSBox, GCC and the original target image/files are external dependencies; see [build guide](../states/BUILD.md). Original 6.20 source wording, names, and the STUB tail's provenance are not asserted. Historical per-round ledger states were not separately retained.
