# MS-DOS 7.10.1111 reconstruction

M6 T20 is active. This is a complete source tree seeded from audited v7.00.950,
not an overlay. DOS 7.10.1111 executable restoration is not yet complete.

Build entry: `extras\build.cmd`. It prints progress, pauses for review, and
publishes to `extras/assets` only when all three outputs match the pinned Dell
OSR2 boot-disk targets. The initial 950 source seed does not meet that test.

See [plan](extras/docs/design/PLAN.md) and [current status](extras/docs/states/CURRENT.md).
