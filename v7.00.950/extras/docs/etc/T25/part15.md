# T25 sequential audit: files 94 onward

94. cmd/command/comequ.asm -- accepted_necessary, unchanged.
Complete diff contains message class 3, sublist size 13, removal of embedded
argument string buffers, and reversed switch-bit assignments. The first two
match the selected DOS7_TRANSIENT_MSG structures and generated message class.
PARSE2:227-234 derives argbufptr and ArgBufferEnd from ComBufPtr/CmdBufferLength;
TSPC:512-520 instantiates only the argument metadata followed by parser state.
Reintroducing fixed buffers changes target layout and duplicates dynamic storage.
TDATA:566/572 defines ?VBAPW switch order, agreeing with the six low-to-high
bit constants. All other definitions retain the effective-reference form.

95. cmd/command/command.lnk -- accepted_necessary, unchanged.
The sole diff places loadhi.obj before tprintf.obj. The accepted linked map
places LoadHigh at 043D:76E5 and Printf_init at 043D:77E1, matching the verified
950 image. Retain required object placement; response-file syntax and all
other entries already match the effective reference. No edit/rebuild needed.

96. cmd/command/command.skl -- accepted_modified.
Reviewed the complete skeleton and diff. Restored the exact reference comments
and spacing for date messages 1072-1074, plus the separator after 1093.
Retain 950 message order, changed strings/IDs, version identification, LFNFOR,
LOCK/UNLOCK, UNC and pipe diagnostics, directory formatting and help records.
These are target resources, not duplicate code paths; inherited :use references
continue sharing the common message catalog.

Verification: file96-build.txt; extras/build/t25-command-skl-4367-16507.
Original BUILDMSG regenerated messages, original NMAKE command phase passed.
CL1/CL2/CLF/CTL and command.exe/iniclass.exe/resclass.exe compare unchanged.
COMMAND.COM repacked from those binaries and unchanged indexed resource,
then compared exact to its own target. IO.SYS/MSDOS.SYS inherited and exact.
All 293 current sources match the stage. Final full build remains pending.

97. cmd/command/command1.asm -- accepted_modified.
Reviewed every difference and its surrounding resident flow. Replace 0C08h
with (STD_CON_INPUT_FLUSH SHL 8) OR STD_CON_INPUT_NO_ECHO, the existing service
expression used by effective-reference COPY. No new constant or path added.
Retain indirect resident message pointers, CMD/checksum header (INIT computes
and checks ResidentChecksum), resident break state (TCMD2A manipulates it),
Y-switch Ctrl-C handling and PipePtr segment release before inherited cleanup.
The latter releases separately allocated storage and then rejoins existing
PipeFlag/EchoFlag handling; it does not duplicate the legacy flag cleanup.
All unaffected source paragraphs remain inherited.

Verification: file97-build.txt; extras/build/t25-command1-4749-28887.
Original command build and message generation pass; linked command.exe and
message binaries compare unchanged. Fresh COMMAND.COM matches the frozen 950
target; other two inherited images match. All 293 stage inputs match current
source. Final full build remains pending.

Prefix 97/293: modified 37, exact 17, necessary unchanged 9, no same-name
reference unchanged 34. Next: 98 cmd/command/command2.asm.
