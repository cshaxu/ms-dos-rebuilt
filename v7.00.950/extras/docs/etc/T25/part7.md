# T25 S1: files 55 through 65

Files 55-62 have no same-name effective v6.22 reference. Their presence is
required by the 950 configuration program. Audited each routine and its
distinct firmware protocol; retained the existing file and segment structure.
Config menu calls ConfigGetCapabilities; PnPProbeTable in cfginit.asm selects
the fallback probes. This is ordered hardware detection, not duplicate
implementations of one entry point. No independent older-version baseline
was introduced to fill the missing references.

55. bios/pnpcaps.asm: remove duplicated/generated interface prose; document
    the two cleared FAR outputs, PnP service and fallback table traversal.
    Replace eleven address-derived local labels with operation names.
    Retain result dispatch, fallback ordering and all exits.
56. bios/pnpcheck.asm: document FAR header argument, AX rejection result and
    actual DS-from-SS restoration. Name signature/return branches by meaning.
    Preserve header-size gate, entry jump adjustment and both signature tests.
57. bios/pnpcpq.asm: document Compaq ROM/model/port probe and AX results;
    replace six address labels with meaningful local names. Preserve model
    comparisons, port 1C65h and exact result paths.
58. bios/pnpfind.asm: document paragraph ROM scan, checksum and rejection
    call, DX:AX result and DS restoration. Replace eight address labels and
    remove unrelated registry comment. Preserve the empty _DATA segment,
    checksum flow and original paragraph scan limit.
59. bios/pnpibm.asm: document model-selected BIOS/adapter probe and return;
    replace eight address labels and remove unrelated registry comment.
    Preserve BIOS/submodel tests, I/O delays and interrupt-state sequence.
60. bios/pnplf.asm: document signature/version/configuration queries and
    four return classes; replace four address labels and unrelated registry
    comment. Preserve FAR firmware calls and exact version tests.
61. bios/pnpti.asm: document firmware signature, capability flags and state
    query/AX results; replace five address labels and unrelated registry
    comment. Preserve register saves, service selectors and conditional paths.
62. bios/pnptosh.asm: replace process-oriented header with actual interface
    and return contract. Retain model switch, public/table labels and raw
    instruction encodings. Tested replacing ten E9 0000 I/O delays with
    explicit JMP NEAR PTR to the next labels; original MASM instead emitted
    EB 01 90. Rejected and reverted that change before proceeding. This
    compiler evidence justifies the existing DB/DW representation; no new
    macro, alternate path or special build rule was added. Final object exact.
63. bios/power.asm: byte-identical to effective v6.22; no edit/rebuild.
64. bios/power.inc: byte-identical to effective v6.22; no edit/rebuild.
65. bios/ptime.asm: byte-identical to effective v6.22; no edit/rebuild.

Each modified file was compiled with production config.mak and MASM /Mx /t
/W1 before the next edit. file55-build.txt through file62-build.txt show
byte-identical objects, all 293 source inputs verified against each stage,
and inherited three images directly compared with the own frozen 950 targets.
This is affected-object verification, not a claim of fresh configuration
linking/packing. Identical objects preserve the previously validated images.
The rejected Toshiba encoding check is file62-jmp-rejected.txt; final PASS
is file62-build.txt. Full automatic build remains required at audit closure.

Counts through 65: modified 20, exact 11, necessary unchanged 5,
no-reference unchanged 29. One tool change remains separately counted.
Latest verified stage: extras/build/t25-pnptosh-28579-3394.
Next: 66 bios/rapiopen.asm.
