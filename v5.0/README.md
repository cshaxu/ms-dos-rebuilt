# MS-DOS 5 source reconstruction

Run `extras/build.cmd` from this directory. Success verifies all three compiled files
against frozen DOS 5.00 targets before publishing IO.SYS, MSDOS.SYS and
COMMAND.COM to `extras/assets/`. See the [build guide](extras/docs/etc/build-and-compare.md).

Sources follow the DOS6 tree: `bios/`, `dos/`, `cmd/command/`, `inc/` and
`messages/`. Project additions live in `extras/`; generated work lives in
Git-ignored `extras/build/`. All three current build outputs match the target
byte for byte. Output identity does not establish original source provenance.
See [current state](extras/docs/states/CURRENT.md).
