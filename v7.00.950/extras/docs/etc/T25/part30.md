# M6 T25 S1 P30: file 121

121. rucode.asm -- accepted_modified. Reviewed complete effective-v6.22 diff.
Remove duplicate Crlf export and obsolete MsgRetriever disk-path input comment.
Restore inherited message lookup register/table comments; replace ten numeric
DOS service expressions with existing CHMOD/OPEN/LSEEK/WRITE/CLOSE/DISK_RESET.

Keep indexed resources and localized critical-error response pointers, Windows
critical-error/broadcast handling, relocated initialization ownership, and the
validated two-level parse/extended-message pointer lookup. Restoring the old
disk/ROM message reader would introduce an obsolete second path. ExecTopRet's
post-EXEC LoadTop fallback shares existing error/wait and attribute cleanup;
its inline text, disk reset and restart sequence are required target behavior.
Preserve remaining DBCS/ROMDOS conditionals. No layout or encoding changed.

Verification: file121-build.txt; extras/build/t25-rucode-13899-32129.
Original COMMAND build passes. Regenerated messages and linked executables
are unchanged. Fresh COMMAND.COM matches target; inherited IO.SYS/MSDOS.SYS
also match, and all 293 current source inputs match the stage.

Prefix 121/293: modified 52, exact 21, necessary unchanged 12, no same-name
reference unchanged 36. Separate tool modification one. Next: 122 stub.asm.
Final full automatic build remains pending. P30 is delivered separately.
