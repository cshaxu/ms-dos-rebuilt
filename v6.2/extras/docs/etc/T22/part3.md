# T22 S1: files 40 through 49

Only original v6.0 source was used for source comparison. Existing reconstruction
records supply historical target-offset evidence, not another reference version.

40. command.skl: eight added records provide batch confirmation, COPY overwrite
    answers/padding and three COPY help lines. Preserve original :def catalog
    syntax and numeric ordering. No unnecessary difference found.
41-44. command1.asm, command2.asm, comseg.asm, comsw.asm: exact DOS6 source.
45. copy.asm: restore the original VerVal declaration as its own line; new
    imports follow it. Restore the original Not_SlashV label and comment at the
    existing switch-processing convergence point, replacing reconstructed Done
    and redirecting its two local branches. No code path or instruction changed.
    Retain COPYCMD lookup, /Y and /-Y handling, overwrite confirmation, necessary
    longer branches and state updates. Existing CompName, SearchNext, BuildDest,
    SysDispMsg and Std_PrintF are reused; no second copy implementation exists.
    The DOS6 file has no equivalent overwrite-confirmation or COPYCMD procedure
    to substitute while retaining these target bytes. Do not abstract away the
    target's repeated DOS calls or alter branch layout for superficial brevity.
46. copypr1.asm: exact DOS6 source.
47. copypr2.asm: sole MOV-to-OR change preserves existing ASCII mode when AL is
    merged, matching target. Same instruction position and original comment;
    no stylistic divergence. Historical mapping: file-review-119-copypr2.json.
48. cparse.asm: sole SWCOUNT 6-to-8 change required by two added COPY switches.
    Original equate form/comment retained. Historical target mapping:
    file-review-120-cparse.json. No other version is used as source authority.
49. cratio.asm: exact DOS6 source.

Verification for file 45: original-tool full build cmd-3212-2638; separate
per-file build before advancing beyond it. All three outputs compare to v6.20
frozen targets. Post-review hashes recorded in reviewed.csv; entry hashes and
fixed order remain in inventory.csv. See file45-build-result.txt.
COPY.OBJ also compares byte-identical to the preceding cmd-2556-4896 object.
