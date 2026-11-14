# M6 T25 S1 P53: files 146-147

146. dos/cpmio.asm -- accepted_modified. Full effective-reference diff reviewed.
Move ConsoleStatePtr's external declaration from executable flow into the
existing DOSCODE declaration section. Restore no-echo input paragraph columns,
SS-relative variable spelling, printer/date/scan comments and packet-save notes
where the inherited explanation still applies. Restore template-backspace
explanations at the corresponding branches.

Retain console-state setup and mode selection, 168Fh multiplex coordination,
input cancellation, fast-console interrupt-frame call, explicit CMP encodings
and branch placement. Do not reintroduce the old removed interim-character
comparison merely to reduce text differences: it changes instructions in that
conditional build. This validation covers the accepted USA target, not every
historical DBCS configuration. Existing conditional structure remains intact.

Original NMAKE/MASM freshly compiled CPMIO and linked the kernel byte-identical
to the accepted kernel. Fresh IO.SYS repack matches the frozen target. Both
unaffected inherited images also compare exact. All 293 source inputs match.
Stage extras/build/t25-cpmio-27503-24180; file146-build.txt, file146-make.txt.

147. dos/cpmio2.asm -- accepted_necessary. Full diff consists of four AL mode
initializations before STATCHK: output polling uses zero and input/status uses
one. msctrlc.asm STATCHK passes that mode into DSKSTATCHK; its saved input AL
selects whether the console state word is restored after the device status
call. These are required calling-contract changes, not redundant moves.
No source edit or redundant build for this file.

Prefix 147/293: modified 73, exact 21, necessary unchanged 17, no same-name
reference unchanged 36. Separate modified tool one. Next: 148 dos/create.asm.
Final full build and completion audit remain pending.
