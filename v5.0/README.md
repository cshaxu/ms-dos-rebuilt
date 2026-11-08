# MS-DOS 5 source reconstruction

Project documentation starts at [docs/README.md](extras/docs/README.md). The goal is
a source package whose IO.SYS, MSDOS.SYS and COMMAND.COM builds match the
specified MS-DOS 5.00 image byte for byte. A fresh integrated build matches
retained target extracts, and the three files have been deployed. The owner accepts the retained three-file target baseline without remounting
the original image. SoftPC runtime validation is not an acceptance requirement; see
[current state](extras/docs/states/CURRENT.md).

The source layout follows the DOS 6 tree: `bios/` contains IO.SYS sources,
`dos/` contains MSDOS.SYS sources, `cmd/command/` contains COMMAND.COM
sources, and `inc/` contains shared includes. `messages/` holds message
sources. Project tests are under `extras/tests/`, build tools under `extras/tools/`, and
generated files under the Git-ignored `extras/build/` directory.
Earlier investigation sources are preserved in [research/dos/](extras/research/dos/README.md).
The [build and comparison guide](extras/docs/etc/build-and-compare.md) identifies
the current entry point and the retained target evidence.
