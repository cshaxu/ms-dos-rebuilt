# MS-DOS 6.20 core reconstruction

Rebuild IO.SYS, MSDOS.SYS and COMMAND.COM from DOS 6.0-based source and match the owner-supplied target bytes. Project governance, tools, baselines and build outputs are under [extras/](extras/); see the [execution plan](extras/docs/reconstruction-plan.md) and [current state](extras/docs/states/CURRENT.md).

The selected USA build has been reproduced from the project source and message inputs: all three outputs match the image-derived targets byte for byte. Run `extras/build.cmd` to build and publish the verified three files to `extras/assets`; see the [build guide](extras/docs/states/BUILD.md) for required pinned tools and target files. Historical source spelling and symbol attribution remain partly reconstructed.
