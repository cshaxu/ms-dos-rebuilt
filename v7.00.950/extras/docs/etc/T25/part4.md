# T25 S1: files 38 through 44

38. mblate.asm: no same-name effective v6.22 reference. Retain CONFIG$ buffer
    allocation, XMS transfer, low-memory copy/restore and the system-file EXEC
    flow in their existing module. EXEC records use actual symbol references.
    WINBOOT.SYS/IO.SYS selection is target fallback behavior, not a separately
    invented implementation. The repeated absolute MCB references document
    32-bit encodings; all buffer modes share the same header and saved state.
39. mrcf.inc: no same-name reference. Audited all 1272 lines: one included
    decoder with eight bit-position states, state-specific offset/length
    decoding, shared long-copy handling and chunk completion/error exits.
    Similar state bodies use different shifts, refills and transitions;
    replacing them with a generic loop would change target code. Two local
    macros describe alternate immediate encodings rather than binary patches.
40. msbio.lnk: retain reference LINK response syntax. Added/reordered objects
    reflect the required 950 layout and separately assembled initialization,
    configuration and graphics code. Reverting order changes segment offsets.
41. msbio.skl: exact effective v6.22 source.
42. msbio1.asm: restore the effective reference's complete bc_cmderr/bc_err_cnt
    source block, including comments and ES assumption; restore expanded
    bin_date_time and month_table declarations from that reference verbatim.
    Restore hardware-vector table comments and unchanged dispatch operand
    spacing. Remove a displaced exit-path comment above the hardware table.
    Retain 950 data order, CONFIG$ device, video/keyboard hooks, A20 protocol,
    character dispatch register layout and initialization structures. No second
    implementation added. NMAKE /a rebuilt BIOS and loader; both binaries are
    unchanged and repacked IO.SYS exactly matches the frozen target.
43. msbio2.asm: restore the unchanged disk-swap broadcast paragraph verbatim
    from effective v6.22, including its one-drive assumption and parameter
    comments. Keep the 950 focus handling, resource messages, dynamic sector
    pointer, CS-relative data and balanced DS preservation. Rebuilt BIOS and
    loader and repacked IO.SYS all remain identical.
44. mschar.asm: restore the three original printer retry-count comments while
    preserving required CS overrides and word-sized printer index. Keep 950
    range checks, near clock calls, flag-word tests and RTC rollover refresh.
    NMAKE /a verification is recorded in file44-build.txt; only accept on PASS.

Counts through 44: modified 8, exact 5, necessary unchanged 3, no-reference
unchanged 28. Next: 45 bios/msdioctl.asm. Tools: ioimage.c is separately counted.
Each changed source was compiled before the next source edit. Files 42-44
rebuilt all BIOS objects and linked loader/BIOS; IO.SYS was freshly repacked.
MSDOS.SYS and COMMAND.COM were unaffected inherited outputs, checked against
their own targets. This does not replace the final whole-project build.
