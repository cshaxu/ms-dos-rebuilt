# M6 T25 S1 P37: file 128

128. tcode.asm -- accepted_modified. Reviewed the complete 798-line diff
against effective v6.22. Restore inherited FCB argument/switch instruction
formatting and comments, cooked-buffer copy comment and consistent added
external declarations. No emitted instruction or data changes.

Retain dynamic raw/cooked buffer initialization and WORD lengths, search-handle
cleanup, trace output, LoadTop entry restoration, automatic Windows command,
single-command state, batch position publication and command-state multiplex
checks. The command parser uses shared FCB parsing and ExpandCommandLine;
CheckForCommand only identifies the FOR variable for that shared expansion.
Do not reinstate the removed PSP-tail copy or a second expansion implementation.
Keep the target's FCB ambiguity check and pipeline/IF handling.

BatchStep preserves its different carry contract, localized all/yes/no keys,
Return/Escape and stop-key behavior. Command state notification has one common
multiplex body; clear/query wrappers already share their call/restore tail.
No helper merge is justified that would change target instruction layout.
Original ROM conditional and other inherited control paths remain unchanged.

Verification: file128-build.txt; extras/build/t25-tcode-17491-26128.
Original COMMAND build passes. Messages and linked executables remain exact.
Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS also match.
All 293 source inputs match the verified stage.

Prefix 128/293: modified 58, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 129 tdata.asm.
Final full automatic build remains pending. P37 is delivered separately.
