# T21 file 90: cmd/command/tcode.asm

Restored DOS6 original whitespace, blank-line structure and EOF marker while
preserving every pre-audit instruction/directive. Final complete DOS6 diff has
only five necessary hunks: no SEMIPERMCOM import, MOV SI,-1 rather than the
later /K state, and three IBM rather than IBM_ROM_FIND guards. OpenNT corroborates
the older SINGLECOM and IBM forms. Native CLI/STI and ordinary command execution
match DOS6; OpenNT host prompt, reentry, service and console machinery are absent.
No need to copy or reconstruct that second host execution path.

The current file is otherwise byte-identical text to the DOS6 reference.
Whole-word BOP/NTVDM/VDM/NTIO/dossvc scan found no hits. Original comments,
conditional bodies and procedure structure are preserved, not compressed.

Affected COMMAND build t21-command-26111-26809 passed (full parent
cmd-25422-19888). All 34 COMMAND objects and COMMAND.COM are unchanged.
All three outputs match frozen targets; IO/DOS are inherited verified outputs.
The 243 audit entries match their staged copies except the documented original
BUILDIDX message-index rewrite. Metadata entry 80 is an audit snapshot only.
Fresh evidence: audit-inputs-before/after.log, audit-object-compare.log,
audit-*-compare.log, cmd/command/AUDIT.LOG and result.txt.

Prefix 90/243: 9 modified entries (one metadata), 67 exact, 14 necessary
differences. Next: 91 cmd/command/tdata.asm.
