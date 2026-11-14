# Registry migration dependency evidence

Source snapshot: current production v7.10.1111 after P251. This is dependency
analysis, not a new implementation delivery or binary-alignment claim.

`registry_graph.c` scans reg*.asm, rapiopen.asm, rqvalue.asm and configio.asm.
It finds 156 PROC declarations and 477 call/reference sites in 153 strongly
connected components. These counts are source declarations, not the number of
functions in the target IO.SYS. External calls remain explicitly unresolved.
Shared object layouts and indirect callbacks require additional review.

The current storage cycle is:

* RegSaveFile -> RegLoadDataBlock (regread.asm:1295,1357).
* RegLoadDataBlock -> RegMaintainCache (regread.asm:1662).
* RegMaintainCache -> RegSaveFile (regread.asm:1953,2009).

Treat those three functions as one implementation unit, not independently
completed leaves. Its direct upstream consumers include RegCloseKey,
RegFlushKey, RegGetKeyRecord, RegCreatePath, RegGetDataBlock, RegAllocateRecord,
RegNextDataBlock and RegFlushAll. See registry-calls.csv for individual sites.

File creation/read/release also crosses regfind.asm, regread.asm, regstart.asm
and rapiopen.asm. RegInitialize, RegLoadKeyAPI and RegReloadSystem consume the
old read contract; RegUnloadKey, RegReleaseMounts and RegTerminate consume the
old ownership/release contract. Changing object allocation alone is unsafe.

Historical disassembly evidence adds an indirect dependency that a direct-call
graph misses: RegAllocRetry and RegReallocRetry pass RegDiscardCache and
RegSaveFileState to RegForEachFile, which calls a stack-supplied callback.
See registry-reset/current/regread.asm:5089,5115-5132,5159-5180. These historical
names are correspondence evidence only; do not append parallel production
implementations. Confirm each replacement against the frozen target bytes.

Implementation boundary: preserve existing production ownership and names
where appropriate; migrate the save/load/reclaim cycle, allocation callbacks,
file/cache layout producers and consumers coherently. Existing matched leaf
bodies stay unchanged; adapt their bindings only when required. Full linked
comparison remains the acceptance gate. This analysis does not certify that
all shared-data consumers have already been enumerated.

Reproduce from repository root (native C compiler):

    gcc -O2 -Wall -Wextra v7.10.1111/extras/tools/tracking/registry_graph.c -o registry_graph.exe
    registry_graph.exe v7.10.1111/bios registry-calls.csv registry-groups.txt

Put generated executable/reports in extras/build or an owned scratch directory.
The scanner rejects duplicate procedure names rather than resolving ambiguous
historical sources silently. It is not a MASM conditional-assembly evaluator.
Validation fixture confirmed FAR/NEAR calls, cycle grouping, pushed procedure
offsets, excluded local jumps and retained unresolved indirect/external calls.

Core source changes in this analysis: 0. Newly certified identical source files:
0. Existing inventory remains 95 different / 198 identical to 950. Confirmed
whole IO function count remains 461. No rebuild required or assets published.
