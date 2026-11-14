# T22 S1: files 32 through 39

Source reference for this part: original v6.0 only. No cross-version binary
comparison. The two compile runs use existing original DOS tools and compare
outputs only to v6.20 frozen targets.

32. bios/sysconf.asm: retain the CheckDoubleSpace call at erase_dev_do and the
    absence of three size-padding NOPs. The original empty ELSE stays intact.
    Existing file-review-037-sysconf.json records the call bytes E8 64 01 at
    target offset 28049 and final corrected failure-branch placement. The
    present complete source diff has only these necessary instruction changes.
33. bios/sysimes.asm: identical to original DOS6 reference, no change.
34. bios/sysinit1.asm: restore original trailing semicolon on the unchanged
    disable_autoexec call. Retain timer capture, symbolic BootTicks storage,
    query flags and /Y call integration. These are actual data/control-flow
    additions, not alternate implementations. Original declaration and
    conditional structure remains. The new object compares byte-identical to
    the previous accepted cmd-17136-2018 object. Full build cmd-2134-27375
    completed with all three target comparisons MATCH and exit 0.
35. bios/sysinit2.asm: restore 14 DOS6 source lines in the existing shared
    shell-option insertion loop: original comments, spacing and semicolon
    placeholders. No instructions, labels or data changed. Do not restore
    the old JZ comment claiming disable_autoexec was already called: the
    shared insertion path now also serves /Y and checks shell_opt_flags.
    Preserve new timer base/word comparison, alternate F5/F8 codes, clean
    boot flags, omitted menu-exit instruction and shared /D-/Y flow. Existing
    file-review-040-sysinit2.json provides the earlier target mapping; current
    fresh whole-output comparison is the acceptance evidence.
    Build cmd-2556-4896 completed with all three target comparisons MATCH;
    SYSINIT2.OBJ is byte-identical to cmd-2134-27375/SYSINIT2.OBJ.
36. bios/syspre.asm: the entire diff removes two OR instructions setting
    setdevmarkflag before DevSetBreak. Preserve these target-required removals;
    surrounding original DOS6 labels, comments and control structure match.
    Earlier file-review-041-syspre.json maps the resulting 12-byte removal.
37. cmd/command/buildmsg.c: exact DOS6 reference, no edit.
38. cmd/command/comequ.asm: exact DOS6 reference, no edit.
39. cmd/command/command.lnk: exact DOS6 reference, no edit.

Current entry hashes remain in inventory.csv; post-review hashes are in
reviewed.csv. Current source and reference bytes are rechecked before accepting
the prefix. Later hash-classified files are still pending.
