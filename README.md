# MS-DOS Rebuilt

**Nine DOS releases, rebuilt from source to match the original startup files byte for byte.**

Follow the PC boot core from standalone MS-DOS 5.00 to the DOS 8.00 startup environment in Windows Me. The project reconstructs `IO.SYS`, `MSDOS.SYS`, and `COMMAND.COM`. Each release has a reference floppy, a historical build toolchain, and a record of the complete binary comparison.

## Explore the releases

| Source guide | Reference floppy | What to explore |
| --- | --- | --- |
| [5.00](v5.0/README.md) | MS-DOS 5.00 | A standalone DOS kernel rebuilt with DOS and OpenNT source references |
| [6.20](v6.2/README.md) | MS-DOS 6.20 (US English) | The DOS 6.00-style tree shared by the later 6.x builds |
| [6.21](v6.21/extras/README.md) | MS-DOS 6.21 (US English) | A compact source overlay directly on 6.20 |
| [6.22](v6.22/extras/README.md) | MS-DOS 6.22 (US English) | The final standalone DOS release in this collection |
| [7.00.950](v7.00.950/README.md) | Windows 95 (4.00.950) | The Windows 95 startup core and its long-filename interfaces |
| [7.10.1111](v7.10.1111/README.md) | Windows 95 OSR2 (Dell OEM) | FAT32 startup and disk handling in the 950 lineage |
| [7.10.1998](v7.10.1998/README.md) | Windows 98 First Edition | Startup and registry changes traced from the OSR2 base |
| [7.10.2222](v7.10.2222/extras/README.md) | Windows 98 Second Edition | Seven changed source files on the pinned First Edition tree |
| [8.00.3000](v8.00.3000/extras/README.md) | Windows Me Setup Disk (OAK) | Built-in HIMEM, resume code, and the compressed IO.SYS image |

## Rebuild and compare

Open a release guide for the required tools and media. Run its build entry from the version directory in Windows CMD.

```bat
extras\build.cmd
```

For Windows Me, also run `extras\build.cmd io` to build `IO.SYS` and `MSDOS.SYS`. The no-argument build handles `COMMAND.COM`.

The build expects the configured historical tools and the extracted reference files under `extras/baselines/targets`. Verified files go to `extras/assets`. Build logs, linker maps, and comparison results stay under `extras/build`. Generated files and extracted targets are Git-ignored.

## Read the source

Start in `bios/` for startup and BIOS I/O, `dos/` for the kernel, or `cmd/command/` for the interpreter. The files in a source overlay show where that release changes its base. The version guides identify the inherited source and link to the evidence behind the reconstruction.

Byte identity applies to the specific floppy listed for each release. The build verifies the produced files. Source names, comments, and layout have been recovered using the available source references, linker evidence, and disassembly.
