# Latest verified build — 2026-11-13

The clean production build `extras/build/cmd-4039-24987` returned zero and
published IO.SYS (214836 bytes), MSDOS.SYS (9 bytes), and COMMAND.COM (93812
bytes), all byte-identical to the frozen 1111 targets. This supersedes the
older size/difference/function-coverage snapshots below.

CRT startup is now assembled from `bios/crtstart.asm`; the extracted startup
object is not linked. The `--dos-startup` module-name special case has been
removed from `extras/tools/crtlib.c` and the build entry. Also removed: the
unused `omforder --layout` mode and its six obsolete recipes. Unlinked
`reginit.asm` was restored to the 950 baseline; the other three unlinked
registry files were already baseline-identical and remain retained.

Current core inventory: 291 files, comprising 174 identical to 950, 116
modified, one added, and three removed from the original 293-file baseline.
The current full build and per-file inventory are recorded in
`../tracking/full-build-2026-11-13.md` and
`../tracking/source-inventory-current.csv`.

The task remains active for its source-reuse/build-policy closure audit;
whole-image identity does not establish original Microsoft source text or
an original target function count. No further binary-recovery percentage is
inferred from the historical partial function inventory below.

---

## Historical records (superseded where inconsistent with the above)

Current P252 continuation (extent): RegTakeFreeSpace compacts the existing block before taking its merged free tail, accepts exact fit and uses the target 22h split threshold. Removed the obsolete per-hole search/previous-link path. Actual take/compact/index/copy functions pass fragmented-space, exact-fit, 21h/22h split and insufficient-space cases; corrected pre-change fixture fails. Added a symbolic RegResizeRecord boundary to regkeys.omf after OMF rejected a loader-fixup split; tool verifies unchanged code/operands. Complete IO relink passes at 233548 bytes, target 214836. All 461 whole-function comparisons and the 186880-byte prefix pass. One core source and one object-layout recipe modified; zero newly exact source files/functions. No assets published.

Owner progress correction: across the recent compaction/growth/creation/extent work, two core files contain five modified functions and one deleted obsolete function. IO shrank only 142 bytes from 233690; 18712 excess bytes remain and exact-function count stayed 461. COMMAND did not advance. Local behavioral tests are not whole-function target identity. Next delivery must address the file/cache ownership and open/save/release dependency group, rather than further isolated helper-policy patches.

Current P252 continuation (creation): RegAppendDataBlock now uses the target page-sizing expression (required bytes + 101Fh) AND F000h. RegNewDataBlock initializes the WORD offset table by calling the existing RegIndexBlock after constructing its free record, replacing the discarded header-validation result. Creation/append/index/release integration passes with actual routines and controlled allocation services; first and second allocation failures are covered, along with all 255 index slots and buffer guards. Pre-change source fails the same fixture. MASM and full IO relink pass at 233594 bytes versus target 214836 (16 bytes larger than the prior build). All 461 recorded whole-function comparisons and the 186880-byte prefix pass; no newly exact target function. One core file modified, zero newly certified identical files; 95 different / 198 identical baseline inventory unchanged. File/cache object migration remains open; no publication.

Current P252 continuation: completed the growth consumer of the compaction/index group. RegGrowDataBlock uses existing free bytes, computes page-rounded occupied bytes plus required free space, enforces F000h and returns 0Eh on failure. Removed its redundant post-growth index reconstruction; compaction already rebuilt block-relative offsets and extending a free tail does not move live records. Tests extract the actual grow/compact/index/copy/dirty routines; only ConfigRealloc is controlled. No-op, limit, allocation-failure and successful-growth cases pass; pre-change source fails. MASM and complete IO relink pass at 233578 bytes against target 214836. All 461 recorded whole-function byte comparisons and the 186880-byte prefix pass. One core file modified, zero newly certified identical files; 95 different / 198 identical baseline inventory unchanged. Whole growth function and complete registry storage are not target-exact; no publication.

Current P252: RegPackDataBlock now rebuilds its WORD block-relative index once after compaction, as the identified 1111 compaction path does. Removed its obsolete DWORD FAR-pointer relocation call and the sole RegRelocateIndex implementation. Actual extracted compaction/index/copy routines pass multiple-hole, overlapping-copy, ID254 and boundary-guard checks; the pre-change routines fail the same test. Full IO relink is 233578 bytes versus target 214836, 112 bytes smaller. The 186880-byte matching prefix and all 461 recorded whole-function comparisons pass; no new target-exact function is claimed. CONFIG public names drop from 403 to 402. One core source modified, zero newly certified identical files; existing inventory remains 95 different and 198 identical to 950. Whole registry file/cache migration remains open; no assets published.

Current P251: RegQueryValueCore now computes the source data pointer in the same segment as its value record, matching the identified 1111 copy routine. Existing query-chain tests pass for binary and string values, insufficient buffer and overlapping copy; offset wrap at 64K is not tested. MASM and full IO relink pass at 233690 bytes versus target 214836; prefix, registry target groups and affected bindings pass. The whole query function and complete call chain are not target-exact. The 461 confirmed IO function count is unchanged. One core file changed; existing inventory 95 different and 198 identical to 950. No assets published. 
 
Current P250: RegInitialize and RegTerminate load DGROUP and restore caller DS, retaining the 950-derived lifecycle code. Extracted production routines pass initialization error and existing-provider cases and empty-state termination with caller DS set to TESTSTACK, controlled stubs and stack checks. MASM and full IO relink pass; IO is 233690 bytes against target 214836. Prefix, registry target groups and affected call bindings pass. These entry points and the registry lifecycle are not target-byte-identical; 461 exact IO functions remain. One core file changed this step; prior inventory 95 different and 198 identical to 950. No outputs published. 
 
Current P249: RegQueryValueEx loads DGROUP, restores caller DS, and no longer forwards through RegVMQueryValueEx. It retains the original query core and parameter validation. The extracted entry test passes with caller DS set to TESTSTACK and a nonzero legacy provider marker, using a controlled core stub. MASM and full IO relink pass; IO is 233686 bytes against target 214836. The 186880-byte prefix, verified registry groups and affected link bindings pass. The query entry and complete call chain are not target-byte-identical; the 461 confirmed function count is unchanged. One core file changed; inventory remains 95 different and 198 identical to 950. No assets published. 
 
Current P248: RegOpenKey and RegCloseKey now load DGROUP on entry and restore the caller DS on exit, following the identified 1111 entry contract. Real extracted-function tests pass with caller DS deliberately set to TESTSTACK, using controlled registry stubs. The affected module assembles and complete IO links at 233718 bytes versus target 214836. Prefix and target registry group comparisons and affected call-binding checks pass. The two entries are not target-byte-identical; 461 exact IO procedure entries remain. One core file changed this step; current inventory 95 different and 198 identical to 950. No outputs published. 
 
Current P247: removed the RegCloseKey VM forwarding branch absent from the identified target entry. Real close and open tests passed with controlled stubs; full IO linked at 233698 bytes. 
 
Current P243: moved the original RegCreatePath to _TEXT, directly calling the byte-matched NEAR name checksum; its existing external callers and cross-segment dependencies use FAR calls and its recursion remains local. Removed the now-unreferenced FAR RegNameSum adapter, so both name algorithms have a single target NEAR implementation and no legacy hash/compare adapters. An isolated actual-function test covers empty and existing paths, nested recursion, read-only rejection, allocation failure and successful key creation with name hash and parent link, using controlled storage stubs. Linked-byte checks verify both FAR callers, 17 FAR dependencies, two recursive calls and the NEAR checksum. Nine other name/path/query/copy/hash/preparation suites and existing target-byte checks pass. Removed the obsolete REGKEYS object cut; IO links at 233768 bytes versus target 214836. Tracking remains 461 exact entries; RegCreatePath itself and full persistence are not target-exact. Two core sources modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P242: moved the original RegPrepareSaveFile to _TEXT for a direct NEAR call to the byte-matched name checksum; its four original initialization dependencies now use FAR calls. An isolated actual-function test links all four real initialization functions and checks successful three-write preparation, name hash, IO-inhibited rejection and create failure with controlled file and allocation stubs. Linked-byte checks verify its FAR caller, four FAR initializers and NEAR checksum. Removed the obsolete REGFINAL object cut; IO links at 233764 bytes versus target 214836, and existing target-byte checks pass. Tracking remains 461 exact entries; save preparation is not target-exact or complete end-to-end storage. One core source modified; inventory 95 different and 198 identical to 950. One caller still uses the FAR checksum adapter. No outputs published.

Current P241: moved the original RegRebuildNameHashes into _TEXT and changed it to hash the key record directly with the byte-matched NEAR RegNameChecksum, removing the old temporary-buffer copy. Its caller and key-dirty dependency now use FAR calls; linked-byte checks verify those calls, two other dependencies and the NEAR checksum binding. An isolated actual-function test passes mixed-case and high-bit names, record-read failure, stack and register checks; its external key/storage operations use controlled stubs. The existing RegReadFile test and earlier target-byte checks pass. Adjusted the REGFILE symbolic object layout at the RegSaveFile boundary without changing code or relocation operands. IO links at 233758 bytes versus target 214836. Tracking remains 461 exact entries; the rebuild routine itself is not target-exact. One core source modified; inventory 95 different and 198 identical to 950. Two callers still use the FAR checksum adapter. No outputs published.

Current P240: moved the original RegAddMount into _TEXT so it calls the byte-matched target RegNameChecksum directly; its existing external caller retains the FAR entry. The actual AddMount/FindAlias DOS integration test passes, and linked-byte checks verify the FAR caller and NEAR checksum bindings as well as earlier migrated calls. IO links at 233790 bytes versus target 214836; prefix, PNP, DOS service group and registry checks pass. Tracking remains 461 exact entries; RegAddMount itself is not target-exact. One core source modified; inventory 95 different and 198 identical to 950. Three callers still use the FAR checksum adapter. No outputs published.

Current P239: moved the original RegSearchPath to _TEXT to call the byte-matched NEAR name checksum and comparison directly. Its three existing external call sites now use the FAR entry, its recursive call remains within the routine, and its key-loading dependencies are FAR. Linked-byte checks cover all caller, dependency and recursion bindings. Removed the now-unreferenced FAR RegCompareN adapter, leaving one comparison implementation; retained RegNameSum for four unmigrated callers. Seven isolated search, alias, value, query, copy, comparison and name suites pass. Adjusted the REGKEYS object layout to remove the obsolete search cut and avoid a moved fixup. IO links at 233792 bytes versus target 214836; prefix, PNP, DOS service group and registry checks pass. Tracking remains 461 exact entries; RegSearchPath itself is not yet target-exact. Two core sources modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P238: moved the original RegFindAlias to _TEXT, directly calling byte-matched NEAR RegNameChecksum and RegCompareName while keeping its FAR interface for the five existing callers. A linked-byte check verifies all five FAR caller operands and both NEAR bindings; seven isolated alias, value, query, search, copy, comparison and name suites pass. Removed the obsolete RegFindAlias symbolic cut from its former REGFINAL layout; the layout tool preserves code and relocation operands. IO links at 233800 bytes versus target 214836; prefix, PNP, DOS service group and registry comparisons pass. Tracking remains 461 exact entries; RegFindAlias itself is not yet target-exact. One core source modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P237: moved the original RegFindValue to _TEXT so it calls the already byte-matched RegCompareName NEAR directly. Its three former same-segment callers now use its FAR entry, as does the existing query caller. A linked-byte check verifies all four FAR call operands and the NEAR comparison binding; seven isolated value, query, search, alias, copy, comparison and name suites pass. Adjusted two symbolic OMF cuts to avoid moved fixups without changing code or operands. IO links at 233820 bytes versus target 214836; prefix, PNP, DOS service group and registry comparisons pass. Tracking remains 461 exact entries; RegFindValue itself is not yet target-exact. One core source modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P236: converted the existing name checksum and comparison bodies into single target-style NEAR implementations in _TEXT; the original FAR RegNameSum and RegCompareN names now only adapt parameters for existing callers. The 84-byte checksum and 111-byte comparison each match the entire corresponding target body exactly, including returns. Seven isolated suites for copy, compare, names, alias, query, search and values pass. Complete IO links at 233816 bytes versus target 214836; prefix, PNP, DOS service group and registry checks pass. Tracking regenerated: 461 exact entries, up from 459. One core source modified; inventory 95 different and 198 identical to 950. The FAR adapters remain until caller segments migrate; no overall image identity or completed call graph is claimed. No outputs published.

Current P235: replaced the temporary overlap algorithm inside the original FAR RegCopyBytes entry with a call to the already recovered target RegMoveMemory for WORD-sized counts. The FAR compatibility entry lives in the shared _TEXT segment and preserves CX and zero AX:DX results; the original DWORD-count loop remains for larger legacy calls. No new move implementation was added. Seven isolated suites covering copy, compare, names, alias, query, search and values pass, with their test links updated to include production configio. Full IO links at 233768 bytes versus target 214836; the target 557-byte DOS service group and existing prefix, PNP and registry checks pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 95 different and 198 identical to 950. The FAR compatibility entry and large-count path remain transitional. No outputs published.

Current P234: preserve CX in the existing RegCopyBytes overlap implementation, retaining the pre-change routine's register behavior. Tests pass for both overlap directions, non-overlap, zero length, different segments, SI, CX and stack preservation; the actual query overlap test passes. IO links at 233784 bytes versus target 214836, and existing prefix, PNP and registry comparisons pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P233: the original RegCopyBytes now copies backwards for overlapping same-segment ranges with WORD-sized counts, matching the target RegMoveMemory behavior used by value queries; the existing general forward path remains for other counts. A real query-core/value/copy integration test reproduces overlap corruption with the previous routine and passes with this change; separate tests pass same-segment overlap in both directions, zero length, different segments, SI and stack preservation. Complete IO links at 233784 bytes versus target 214836; prefix, PNP, registry, search, alias and value checks pass. This is a behavioral migration, not a claim that the FAR helper is target-byte-identical or that differing segment aliases are handled. Tracking regenerated: 459 exact entries. One core source modified; inventory 95 different and 198 identical to 950. No outputs published.

Current P232: an isolated DOS integration test links actual RegQueryValueCore, RegFindValue, RegCompareN and RegCopyBytes, with controlled handle, path and key-record stubs. Buffer-too-small status and required length, binary data, string termination, missing name, length-only query and missing default value all pass. This does not prove real storage integration or target-byte identity. No core source changed; inventory 95 different and 198 identical to 950. Latest IO remains 233736 bytes versus target 214836; 459 exact functions tracked. No outputs published.

Current P231: removed premature type-output clearing in the original RegQueryValueCore; the target validates the handle before writing that output. An isolated actual-function test with a controlled invalid-handle stub verifies that both type and size remain unchanged, with the old code failing the same test. Query API and value tests pass; complete IO links at 233736 bytes versus target 214836, and prefix, PNP and registry checks pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 95 different and 198 identical to 950. Query-core success and complete registry storage integration remain open. No outputs published.

Current P230: the existing RegQueryValueEx local-provider branch returns 0057h before calling the query core when a data buffer is supplied without a length pointer, matching the target's invalid-parameter rule. Isolated tests cover this rejection, permitted combinations, stack balance and unchanged VM provider dispatch with controlled core/provider stubs. Complete IO links at 233752 bytes versus target 214836; prefix, PNP, registry and value/search/alias checks pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 94 different and 199 identical to 950. The target's whole query call chain and binary identity remain open. No outputs published.

Current P229: original RegFindValue now scans a non-null name with the target's REPNE SCASB sequence and preserves DI, replacing its former FAR string-length call. The actual function passes null, empty, mixed-case, non-ASCII, multi-value, absent-value, stack and DI tests. IO links at 233720 bytes versus target 214836; prefix, PNP, registry and search/alias checks pass. The existing FAR function and file-cache layout are transitional and are not counted as target-exact. Tracking regenerated: 459 exact entries. One core source modified; inventory 93 different and 200 identical to 950. No outputs published.

Current P228: original RegFindValue traverses value entries with 16-bit offsets in the record segment, as in the target lookup routine, rather than carrying offsets into a separate segment. Tests exercise three values with different names, a nonzero value-data length, mixed case, default/null names, high-bit bytes, absent values and stack balance. This adopts the target single-segment record assumption; the larger file-cache migration and complete target function remain open. IO links at 233722 bytes versus target 214836; prefix, PNP, registry and search/alias checks pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 93 different and 200 identical to 950. No outputs published.

Current P227: the original RegFindValue now matches a zero-length default name irrespective of value type, as in the target's RegFindValueTarget loop. The historical target routine was previously compared against all 227 target bytes with its relocations checked; the current FAR routine is not claimed byte-identical. Actual-function DOS tests pass default values of type 1 and 4, empty and null names, mixed case, missing name and high-bit characters. IO relinks at 233754 bytes versus target 214836; prefix, PNP, registry and search/alias checks pass. Tracking remains 459 exact entries. One core source modified; inventory 93 different and 200 identical to 950. No outputs published.

Current P226: original RegFindValue compares the original name directly with the stored value using the existing counted case-insensitive RegCompareN, eliminating the old uppercase buffer copy. This follows the target value lookup data flow without adding an implementation. The actual function with production RegStringLength and RegCompareN passes mixed-case name, default empty or null name, missing name, high-bit byte, no values, stack balance and unchanged shared-buffer checks in isolated DOS. Complete IO relinks at 233770 bytes versus target 214836, 18 bytes smaller; prefix, PNP, registry and search/alias regressions pass. Tracking regenerated: 459 exact entries. One core source modified; inventory 93 different and 200 identical to 950. Overall registry integration and three-image identity remain open. No outputs published.

Current P225: extracted the production RegSearchPath into an isolated DOS test and linked the actual RegPathPart, RegNameSum and RegCompareN. Single and nested mixed-case paths, missing key, invalid control byte, high-bit character, status and stack balance pass. The test uses controlled RegLoadKey and RegGetKeyRecord stubs; it does not prove full registry persistence, target identity or a complete storage call chain. No core source changed; inventory 93 different and 200 identical to 950. The last IO remains 233788 bytes against target 214836, with 459 exact tracked entries.

Current P224: original RegFindAlias and RegSearchPath now pass their original path component and known length directly to RegNameSum and RegCompareN, following the target's counted-input data flow. RegPathPart still validates and populates its existing buffer for other consumers, so path migration is not complete. Adjusted the existing symbolic object-record boundary to avoid splitting a fixup. Full IO relinks at 233788 bytes; existing prefix, PNP and registry byte checks pass. Isolated DOS tests pass the actual RegFindAlias and RegAddMount chain, including mixed case and invalid paths, and standalone compare stack checks. RegSearchPath end-to-end was not independently exercised this step. Tracking regenerated: 459 exact entries. Two core sources modified; inventory 93 different and 200 identical to 950. No outputs published.

Current P223: ran the complete extras/build.cmd from a fresh source snapshot in build/cmd-19361-28534. BIOS, kernel, COMMAND and CONFIG compile and link successfully, input snapshots agree, and MSDOS.SYS exactly matches its target. IO.SYS (233788 vs 214836 bytes) and COMMAND.COM (92870 vs 93812 bytes) fail their complete byte comparisons, so the build exits 1 without publication. Both fresh outputs match the previous incremental outputs byte for byte. Prefix, PNP and registry checks pass; regenerated function tracking remains 459 exact procedure entries. No core source changed; inventory 93 different and 200 identical to 950.

Current P222: correct P221: the three removed allocator routines are present in the target, so restore them rather than interpreting current lack of callers as evidence of a duplicate to delete. Full IO relinks at 233788 bytes; the complete 557-byte registry DOS-service group matches target offset 192756 including its internal call operands. Its 16 listing-defined entries are tracked as exact function bytes at their target offsets, raising the verified entry count from 443 to 459; target call-graph integration remains open. Existing prefix, PNP and registry checks pass. One core file restored; inventory 93 different and 200 identical to 950. No outputs published.

Historical P221 (corrected by P222): removed three temporarily unreferenced allocator routines and linked 233660 bytes. The removal was wrong because their complete service group is present in the target. The previous 443-function tracking count did not include that group.

Current P220: expanded function tracking to private kernel procedures using listing boundaries, at least two consistent public anchors per module and segment, the verified embedded kernel payload and complete target-byte comparison. One additional distinct function, ROM callmagic at target offset 111165 length 7, passes, for 443 exact function entries. This is a conservative lower bound, not a target-function total or completion percentage. No core source changed; inventory remains 93 different and 200 identical to 950. Latest IO remains 233788 bytes versus target 214836. No outputs published.

Current P219: the original RegCompareN and its three callers now use the target's counted argument order and callee cleanup while retaining the existing FAR interface. The symbolic object layout boundary was adjusted to avoid splitting a moved relocation; code and relocation operands remain unchanged by the layout tool. Full IO link succeeds at 233788 bytes versus target 214836. RegCompareN has 104 matching bytes of 111; six stack offsets and the FAR return differ from the target NEAR convention. Isolated DOS comparisons check case, ordering, high-bit bytes, zero count, register preservation and stack balance; real alias and mount calls also pass. Existing prefix, PNP and registry checks pass; tracking was regenerated: 442 exact functions, one relocation-matched, and two FAR-ABI differences. Three core sources changed this step; current core inventory 93 different and 200 identical to 950. Full registry cache, version 2 and final image identity remain open. No outputs published.

Current P218: original RegNameSum now takes a WORD count and a FAR name with callee cleanup; all six existing callers in reginit regopen and regread pass already-known lengths. The old duplicate null scan was removed. Four modules compile, use original OMF layouts and link IO at 233788 bytes versus target 214836. Linked RegNameSum has 80 matching literal bytes out of 84, with three verified FAR frame offsets and the FAR return opcode differing from target NEAR; it is tracked as ABI-different rather than exact. DOS tests cover original algorithm equivalence for all nonzero byte values, explicit zero count and embedded NUL, stack balance, and actual mount creation plus alias lookup. Full registry cache and version 2 remain open. Four core sources changed; inventory 93 different and 200 identical. 442 exact IO functions and one relocation-matched remain. No outputs published. 
 
Current P217: isolated DOS file-open test now links the production RegReadFile, RegValidateHeader, RegValidateKeyBlock and RegChecksum together. Valid and invalid signature, version, checksum, short reads, seek failures and cleanup pass with controlled allocation and IO stubs. The data-block read test now links actual RegLoadDataBlock, RegValidateDataBlock and RegIndexBlock together and passes valid record WORD indexing, buffer boundary, invalid header or record and IO error cleanup. These tests do not establish complete registry persistence or target identity. No core source changed. Inventory 93 different and 200 identical to 950; latest IO 233806 bytes against target 214836. 
 
Current P216: replaced the original RegIndexBlock record walk with the target-style single-segment WORD-length walk and WORD offset indexing while retaining the original FAR interface and success convention for existing consumers. No second implementation was added. Existing 12-byte cache layout and callers remain transitional, so target function byte identity is not claimed. Both modules assemble and original-layout full IO link passes at 233806 bytes versus target 214836. Isolated tests pass multi-record, empty block, zero, oversized and high-word lengths, maximum legal and invalid IDs, free entries, index clearing and bounds, and actual lookup assignment and release chain. Prior core PNP checksum and header comparisons pass. One core source changed; inventory 93 different and 200 identical. Function tracking 442 exact IO entries plus one relocation-matched. No outputs published. 
 
Current P215: migrated the existing data-record index from 255 FAR pointers to 255 WORD block-relative offsets in regread and regopen, changing all three index allocation sites and the six lookup, free, allocation, assignment and resize consumers. RegIndexBlock clears the WORD index before rebuilding it. Existing 12-byte file-cache entries and version-2 file state remain transitional. Both modules assemble, original OMF layouts and full IO link pass at 233918 bytes versus target 214836. Isolated tests pass for multi-record indexing and boundaries, actual lookup and empty entries, allocation ID scan, free and repeated free, and extracted allocation and resize index writes. Read error regression and earlier core checks pass. Two core sources changed; inventory 93 different and 200 identical. Tracking remains 442 exact IO entries plus one relocation-matched. No outputs published. 
 
Current P214: original RegIndexBlock rejects malformed records rather than invoking INT 3 and repairing the data block, matching the target rejection policy. RegLoadDataBlock now returns 03F1h and frees both buffers when indexing fails rather than continuing with a corrupt index. The old four-byte index and far interface remain transitional, so no complete target-function match is claimed. Isolated tests extracted the production routines and passed valid and free records, zero and oversized lengths, invalid record numbers, and read-side index failure cleanup. Regread assembles and IO links at 233918 bytes versus target 214836. Existing core PNP checksum and header checks pass. One core source changed; inventory 92 different and 201 identical. Function tracking 442 exact IO entries plus one relocation-matched. No outputs published. 
 
Current P213: isolated DOS harness extracted the current complete RegReadFile and passed success, all three short-read locations, seek carry and wrong low or high position, invalid CREG or RGKN validator results, invalid RGDB signature or high size word, and open failure. It checks status, call counts, cleanup, SI and stack. External allocation, validation and DOS operations were controlled stubs, so this does not establish end-to-end registry persistence or byte identity. No core source changed; inventory 92 different and 201 identical. Latest linked IO remains 234304 bytes versus target 214836. 
 
Current P212: original RegReadFile cache-directory initialization now checks seek carry and exact DWORD position, returns 03F8h for seek or short-read failures, rejects data-block headers whose size high word is nonzero, and removes four obsolete INT 3 diagnostic calls on allocation or read errors. Existing transitional file-layout code remains. The actual seek branch extracted from production passed isolated DOS tests for correct seek, carry failure, wrong low and high words, stack balance and create-mode bypass; full RegReadFile behavior remains unverified. Regread assembles and IO links at 234304 bytes against target 214836. Existing core PNP checksum and header checks pass. One core source changed; inventory 92 different and 201 identical. Function tracking: 442 exact IO entries and one relocation-matched. No outputs published. 
 
Current P211: original RegLoadDataBlock now returns 03F1h for invalid data headers and removes four legacy RegInvalidBlock INT 3 calls from invalid index, open failure, malformed block and error cleanup paths, following the target direct-error behavior. Other legacy block-layout checks remain transitional. Isolated DOS harness extracted the current function and passed valid reads, invalid indices and headers, seek errors, wrong positions and read failures; it fails if the old breakpoint is called and checks resource cleanup. Regread assembles and IO links at 234296 bytes against target 214836. Existing core PNP checksum and header checks pass. One core source changed, none returned to 950 identity. Inventory 92 different and 201 identical; tracking 442 exact IO functions and one relocation-matched. No outputs published. 
 
Current P210: original RegLoadDataBlock checks carry and verifies the returned DWORD position after ConfigSeek; either failure uses the existing 03F8h error and resource cleanup path before any read. DOS harness extracted the actual function and passed correct position, failed seek, wrong low word and wrong high word with buffer cleanup, stack balance and SI DI preservation. The target cache layout and full registry integration remain open. Regread assembles and IO links at 234320 bytes against target 214836. Existing core PNP checksum and header comparisons pass. One core source changed, none returned to baseline identity. Inventory 92 different and 201 identical; tracking 442 exact IO functions plus one relocation-matched. No outputs published. 
 
Current P209: original RegWriteDataBlock now clears the checksum-validity flag before seeking, rejects seek carry errors and rejects returned offsets that differ from the requested DWORD position, following target RegDosSeek behavior. It returns 03F8h without writing on either failure. An isolated DOS harness extracted the actual current function and passed successful and failed writes, validation rejection, IO inhibition, failed seek and wrong-position seek using controlled stubs. The complete data-cache layout and end-to-end registry persistence remain open. Regread assembles and IO links at 234288 bytes versus target 214836. Prior core PNP checksum and header checks pass. One core source changed, none returned to 950 identity. Inventory 92 different and 201 identical; tracking 442 exact IO functions plus one relocation-matched. No outputs published. 
 
Current P208: executed the current RegWriteDataBlock body extracted directly from production source in an isolated DOS harness with controlled validation seek and write stubs. Tests pass for checksum-validity bit before successful and failed writes, post-success flags, error 03F8h on write failure, seek count, error 03F1h on invalid block and 00A7h when IO is inhibited. This is a local behavior test, not end-to-end registry persistence or target binary identity. No core source changed; inventory 92 different and 201 identical. Latest IO remains 234256 bytes against target 214836. 
 
Current P207: original RegWriteDataBlock clears the checksum-validity bit before writing, as the target cached-data writer does, and no longer performs a side-effect-free post-write validator call. Existing cache entry layout and other dirty-flag cleanup remain transitional; no complete writer match is claimed. Regread assembles and IO links at 234256 bytes versus target 214836. Core PNP checksum and header checks pass; version 2 file and cache paths remain incomplete. One core source changed, none returned to 950 identity. Inventory 92 different and 201 identical; tracking 442 exact and one relocation-matched. No outputs published. 
 
Current P206: removed now side-effect-free validation calls from the original RegDirtyHeader RegDirtyKeyBlock and RegDirtyDataBlock after confirming their active callers do not consume the validator results. Existing dirty and checksum-validity flag updates remain. This is transitional cleanup of the 950 path, not a claim that target cache layout is complete. Regread assembles and IO links at 234256 bytes versus target 214836. Prior core PNP checksum and header checks pass. One core source changed, none returned to baseline identity. Inventory 92 different and 201 identical; tracking 442 exact IO functions and one relocation-matched. No outputs published. 
 
Current P205: removed redundant second key-header validation from the original RegReadFile success path and removed its legacy diagnostic on invalid key-header signature. The first signature check and existing error state remain. Target opens a key header with a single signature check and direct invalid return. Regread assembles and IO links at 234272 bytes versus target 214836. Existing core PNP checksum and header comparisons pass. One core source changed, none returned to baseline identity. Inventory 92 different and 201 identical; tracking 442 exact and one relocation-matched. No outputs published. 
 
Current P204: removed two old RegInvalidBlock diagnostic calls from the original RegReadFile header-invalid and read-error branches. The 1111 target open path returns errors directly on these paths; existing 950 status and resource cleanup remain. Regread assembles and IO links at 234290 bytes against target 214836. Prior core PNP checksum and header checks pass. Function tracking: 442 exact IO procedure entries, one relocation-matched and 48 COMMAND unique-byte candidates awaiting correspondence. One core source changed; none returned to 950 identity. Inventory 92 different and 201 identical. No outputs published. 
 
Current P203: removed the second RegValidateHeader call from the existing RegReadFile success path after the header has already passed validation and its flags are cleared. The 1111 target open path validates once and proceeds after clearing those flags. Regread assembles and IO links at 234310 bytes versus target 214836; unchanged size reflects link alignment and is not identity. Core PNP checksum and header checks pass. Function tracking remains 442 exact and one relocation-matched. One core source changed; none returned to baseline identity. Inventory 92 different and 201 identical. No outputs published. 
 
Current P202: removed temporary RegCheckPolicy save set and restore from the original RegReadFile and RegLoadDataBlock after their validators were converted to 1111 behavior. RegSetCheckPolicy and its storage remain. Regread assembles and IO links at 234310 bytes against target 214836. Existing direct core PNP checksum and header checks pass. Current function tracking has 442 exact procedure entries and one relocation-matched. This step modifies one core source; none returned to baseline identity. Inventory 92 different and 201 identical. No outputs published. 
 
Current P201: the original RegValidateKeyBlock now validates the RGKN signature without clearing the old checksum flag or issuing the old diagnostic. The target checks this signature inline in its file-open path, so this FAR helper and its callers remain transitional and are not claimed as a matched target function. Regread assembles and IO links at 234342 bytes versus target 214836. Existing core, PNP, checksum, data-header and relocated header checks pass. One core source changed; none returned to 950 identity. Inventory 92 different and 201 identical. Function tracking remains 119 exact and one relocation-matched. No outputs published. 
 
Current P200: original RegValidateHeader and five internal callers now use the 1111 NEAR callee-cleanup convention; RegInitHeader no longer calls validation for the header it has just initialized and returns the same success value. The linked 72-byte validator has 70 literal target bytes and two distinct relative call bytes verified to reach the matching RegChecksum on both sides. Regread and reginit assemble and full IO links at 234360 bytes against target 214836. Prior direct checks pass. This step modifies two core files, none returned to baseline identity; inventory 92 different, 201 identical. Function tracking: 119 whole functions exact and one additional relocation-matched. No publication. 
 
Current P199: converted original RegValidateDataBlock and all eight regread callers to the 1111 NEAR callee-cleanup interface. Its full 39 linked bytes match target IO at 212022. Registry cache layout and other call chains remain open. Module assembly and IO link pass at 234394 bytes versus target 214836. The earlier core span, PNP and 66-byte checksum comparisons pass. One core source changed this step; none became baseline-identical. Inventory 91 different, 202 identical. No outputs published. 
 
Current P198: changed the original RegValidateDataBlock to the 1111 RGDB signature and zero high-word length validation; the previous policy-dependent checksum mutation and its two checksum calls are removed. This confirms the target validator rejects lengths above 65535; old registry cache layout and remaining callers still require conversion. The original FAR interface is retained pending that work. Module assembly and IO link pass at 234410 bytes versus target 214836. The prior 186880-byte core, PNP and exact 66-byte checksum checks pass. This step modifies one core file, none returned to 950 identity. Inventory 91 different, 202 identical. No outputs published. 
 
Current P197: converted the existing RegChecksum and all three current regread callers together to the 1111 NEAR WORD-count callee-cleanup convention. Its 66 linked bytes exactly match target IO at 212280. The legacy data-block validators still need 1111 data-structure and length-constraint conversion; do not claim full registry completion. Module assembly and IO link pass at 234492 bytes versus target 214836. The previously matched core span and PNP checks still pass. This step changes one core file, none returned to 950 identity. Inventory 91 different, 202 identical. No publication. 
 
Current P196: adapted the original RegValidateHeader in bios/regread.asm to the 1111 signature, version and optional checksum behavior. It no longer changes the header based on the old policy. The original FAR caller interface and RegChecksum remain in use; the target NEAR interface and complete registry call-chain conversion remain open. The module assembles and IO links at 234526 bytes versus target 214836. The 186880-byte core span matches, and the 2380-byte PNP block matches outside 140 separately validated address bytes. This step changes one core file; none became baseline-identical. Inventory: 91 different, 202 identical. No outputs published. 
 
Current P195: RegValidateHeader in bios/regread.asm now accepts registry header versions 1 and 2 on the original 950 path, matching the target version gate. The original checksum policy and calling convention still require 1111 conversion. The module assembles and IO links at 234608 bytes; target IO is 214836 bytes and differs. The 186880-byte core span still matches, and the 2380-byte configuration PNP block matches outside 140 separately validated address bytes. This step changes one core file, with none returned to 950 identity. Inventory: 91 different, 202 identical. No outputs published. 
 
# DOS 7.10.1111 reconstruction

## Owner correction — remove duplicate paths

The owner directed removal of duplicate registry paths while retaining FAT32 and all other non-duplicate work. Restore the 950 implementations first, then implement 1111 changes in those original paths. The former appended registry implementations in regfind.asm, regread.asm and regstr.asm were removed; cfgmain.asm and cfgmenu.asm use the original registry API. rqvalue.asm is the only RegQueryValueEx definition and is built and linked. Preserve the verified non-duplicate configio services, cpath correction, regroot data and CRT arithmetic helpers. Build cmd-20864-14811 compiled and linked all components; MSDOS.SYS matches, IO.SYS (234736 vs 214836 bytes) and COMMAND.COM (92870 vs 93812 bytes) do not. No assets were published. Current 293-file inventory: 87 differ from 950, 206 are identical. Historical P1–P186 registry proofs describe pre-rollback code and must not be treated as current implementation evidence. Continue by implementing target changes in the original 950 modules without a second implementation.

Current P193: adapted the original RegCompareN in bios/regstr.asm to the 1111 counted comparison, retaining the current FAR caller interface. The complete configuration links; IO is 234592 bytes. Of 108 bytes before the return, 106 match and two are verified parameter offsets; the FAR versus NEAR return remains different. DOS boundary tests, RegNameSum regression and P188–P190 configuration checks pass. Current core inventory: 90 different and 203 identical to 950. See ../etc/T20-S2-P193.json.\n\nCurrent P192: adapted the existing RegNameSum computation in bios/regstr.asm to the 1111 counted checksum loop while retaining its original FAR, zero-terminated interface. The module assembles and the complete configuration links; linked IO is 234656 bytes. The five-byte entry and 73-byte counted body match the frozen target, while the counting setup and return convention differ. The isolated DOS harness compared the original and adapted routine across 255 nonzero single bytes and empty, mixed-case, high-bit and long inputs. Provider/consumer conversion and final IO/COMMAND identity remain open. Current 293-file inventory: 90 different, 203 identical to 950. See ../etc/T20-S2-P192.json.

Current P188: restored the eighth 1111 configuration argument GetDevParmsIoctl in the original cfginit table and raised the original cfgmain parser limit to eight. Affected modules assemble, complete configuration links, and 237 procedure bytes plus 448 table/string bytes match the target outside independently verified address fields. Current registry providers are still the 950 first path and are not certified for 1111. IO is 234640 bytes and is not target-exact. Current core inventory: 89 different, 204 identical to 950; this part modifies two source files and restores zero to baseline identity. See ../etc/T20-S2-P188.json.

Registry data cleanup: removed the unused second-path roots, cache and path cursor from bios/regroot.asm while preserving the 1111 case changes in the existing path strings. Whole configuration relink succeeded; IO is now 234604 bytes. Direct comparison confirms the 186880-byte IO span at file offsets 512 through 187391 remains exact. Full IO and COMMAND equality remain open; registry first-path adaptation is next. This change modifies one core source; none became 950-identical. Counts remain 87 different, 206 identical.

## M6 T20 S2 Packet

Field | Required record
--- | ---
Identifier Mode | Continuation; T20 allocated after T19; planned T15 is superseded by T20
Admission And Approval | Owner explicitly admitted T20 and subsequently instructed S2 to start execution
Objective | Run the complete current source build first; use linked maps and target binary differences to restore target-matching code, retaining dependency-aware edit order
Non-goals | No overlay dependency on v7.00.950 at build time; no new implementation where reference code applies; no VM boot acceptance
Reference Baseline | Audited v7.00.950 source and its inherited toolchain; frozen7.10.1111 target image only. No other version references.
Candidate Proposal | S1 baseline and targets; S2 dependency-ordered difference restoration; S3 clean exact three-output acceptance
Files And ABI Surface | Full bios/dos/inc/cmd/lang tree; build tools/resources under extras; ABI/layout changes only when target evidence requires them
Applicable Rules | rules/EXECUTION.md, CODING.md, DOCUMENT.md; CMD/BAT/C only; no Computer Use or D:/temp writes
Verification | Complete-build artifacts and maps drive S2 difference localization; skip already proven matching blocks; use local probes only when the integrated difference cannot be localized; retain pinned target SHA256 and final all-three exact comparison
Expected Markers | Explicit dependency graph and ordered units; per-file dispositions; affected byte comparison evidence; no unsupported progress claims
Asset Needs | O:/assets/w9xbd/Microsoft Windows 95 OSR2 - Boot Disk (Dell OEM) (3.5-1.44mb)/disk01.img
Reporting Requirements | Completed files: modified vs unchanged; new-file necessity; block-grounded binary progress; source identity is not target completion
Stop Conditions | Unknown dependency or mismatching output stays unresolved without preventing diagnostic full builds; do not publish partial/mismatched output
Exit Criteria | Source differences resolved in dependency order and integrated; no unresolved dependency or layout mismatch; ready for independent S3 full build
Original Owner Request | Admit a new T specifically to implement v7.10.1111
Similar-Issue Sweep | Shared includes, layout-derived offsets, message/resource movement, repeated implementations and unnecessary fragments

Status: active S2 P181. Fixed incremental helper to apply the same cfgmain/cfgline/cfgmenu OMF fixup ordering as the clean build. Direct FC confirms current clean and incremental IO files are byte-identical at247328 bytes; registry group and cfg main binding checks pass. Target comparison remains failed for IO and COMMAND; MSDOS9 bytes exact. Core modified94, baseline-identical199; in-progress68. This part changes0 core files, certifies0 whole unchanged files; only disposable incremental helper changed. rqvalue source remains pending file-level consolidation; remaining legacy registry sections still link. See etc/T20-S2-P181.json. COMMAND92870 vs target93812 remains open; no publication.

Owner correction P182: minimize source diff against v7.00.950 while retaining exact v7.10.1111 output. Work through corresponding original routines one file at a time and adapt their existing code, structure and names where target evidence allows. A disposable wholesale registry-trimming experiment linked, but is not an acceptable source-fidelity solution and was not applied. Staging and working IO restored and FC matched the P180 clean build. See etc/T20-S2-P182.json for initial routine mapping. This part changes0 core files and certifies0 whole unchanged files.

P183 source-diff evidence: regread, regstr and regfind retain all950 lines while appending3894,143 and1630 lines respectively. This confirms a second implementation was added; reduce it by adapting original routines, not merely by dropping the old linked segments. Original RegChecksum accepts DWORD length and handles segment wrap, while target RegBlockChecksum accepts WORD length and does not; migrate active validation callers together before consolidating. See etc/T20-S2-P183.json. This part changes0 core files and certifies0 whole unchanged files.

P184: the original ConfigReadProfileName body is retained and its complete200 linked bytes match target outside22 independently verified data/FAR symbol bytes. Preserve this body; final addresses and whole-file acceptance remain open. See etc/T20-S2-P184.json. This part changes0 core files and certifies0 whole unchanged files.

P185: restored original RegQueryValueEx symbol and cfg call sites while retaining target query implementation; cfgline.asm is byte-identical to950 baseline again. Final relink passes and IO is directly identical to P180 clean full-build IO,247328 bytes. Registry and cfg bindings rechecked. This part changes4 core files;1 returns to baseline identity,0 whole files newly certified for target. Core modified93, baseline-identical200; in-progress68. Old rqvalue source remains unlinked pending consolidation. See etc/T20-S2-P185.json.

P186: compared original rqvalue.asm RegQueryValueEx and target entry. Their public FAR parameter layout is compatible, but original dispatch through RegVMEntry/RegQueryValueCore differs from target direct handle and cache path. Consolidate into original module with its dependent providers rather than retain duplicate public definitions; do not reintroduce unused legacy wrappers. See etc/T20-S2-P186.json. This part changes0 core files and certifies0 whole unchanged files.

Next execution unit: batch remaining registry cache/file providers with root-path/API consumers in dependency order, then replace superseded legacy paths and relink the complete configuration/IO image. Do not deliver each small helper separately. Registry growth is staging, not final convergence; report remaining legacy paths and linked size as well as corresponding-block equality. Reuse the P147 complete-build baseline and skip the exact core unless affected. No new clean build is warranted solely by this method change.

P147 clean-build baseline: all three products and maps refreshed in extras/build/cmd-17188-26244; input snapshots matched; final target gate failed for IO and COMMAND. IO interval[512,187392),186880 bytes, directly compared exact. Do not revisit this core without affected dependencies. Missing ML.err diagnostic catalog remains a toolchain issue, and SwapTail purpose/original name remain unknown.

Owner-directed execution adjustment: use complete linked artifacts as the primary work unit. First refresh all three products and maps; then repair the configuration/registry dependency group in its existing files, relink the whole configuration program and IO image, and compare its full extent. Skip the proven IO core and eight REGIO service bodies unless their inputs/bindings change. Do not serialize progress into a sequence of tiny probes or documentation-only audits. COMMAND localization uses the refreshed output. After this clean baseline, use affected assembly plus full relinking, not repeated clean builds. Report changed source files separately from newly certified unchanged files; anchor coverage is not completion.
Global task registry remains in v7.00.950/extras/docs/etc/dos7-task-queue.json.

Execution order after P146: CPATH whole329 bytes restored;304 equal,25 FAR operand bytes pending final layout. Correct P145 inference: ConfigOpen provider is unchanged, only CPATH omitted a DWORD argument. Eight required REGIO service bodies total515 bytes EXACT; skip their restoration. configio/cfgmem still contain baseline routines absent from this target section and used by old registry; remove only after registry provider consumers are restored. Next restore registry dependency group, then CFGMAIN API sequence/link order. Config full build passes; payload46508 vs target27444. IO core remains previously proven exact, header awaits config extent; COMMAND afterward. This part modifies1 ASM, certifies0 whole unchanged files; total modified84, baseline-identical209, in-progress58. See T20-S2-P146.json. SwapTail purpose remains unknown. Use only950 baseline plus1111 target; three complete files must match.
Skip whole parse11-byte and misc2126-byte bodies; all misc internal controls, data operands and branches match.48 external address bytes remain for final linkage. Previous partial misc pending-body notes are superseded by P137.
Skip whole getset1351-byte body;45 external code/data address bytes remain, including the existing five-byte UCASE/FILE_UCASE/DBCS layout gap.
Skip whole lock116-byte and lockio84-byte bodies; retain final placement/binding verification.
Skip whole macro2 1015-byte and file968-byte bodies; external code-address bindings remain for final link verification.
Skip whole macro471-byte body;10 external call/jump address bytes remain for final link verification.
Skip whole handle763-byte body;31 external code-address bytes remain for final link verification.
Skip whole alloc757 and srvcall326 instruction bodies; preserve final address/layout validation.
Skip whole msproc2138-byte body;38 code-address operands remain for final link verification.
Skip FCB412-byte instruction/table body; external GetVisDrv, CharType and FILE_UCASE_TAB address operands remain. Five-byte UCASE layout gap still unresolved.
Skip whole disk998-byte body;31 external code address bytes remain for final link verification.
Skip whole abort107 and dup22 instruction bodies; retain external bindings for final link acceptance.
Skip whole IOCTL1057-byte module;81 code-address bytes remain for final link verification.
Skip whole path374-byte body;35 external code address bytes remain for final link verification.
Skip whole search430-byte body; retain18 external operand bytes for final link verification.
UCASE/SWAP_END five-byte difference is unresolved; do not invent padding or stall whole-module restoration on it.
Batch coherent source changes before relinking; no standalone probes unless a concrete unresolved encoding question blocks the integrated build.
MARK2 overlap is resolved; skip its proved80-byte data region.
Skip exact patch_misc_segments59-byte body; remaining msinit initialization is open.
Skip whole misc2 307-byte body. Skip whole
isearch368 body and continue full-image layout convergence. Skip whole rename635
and finfo229 bodies. The delete helper tail is now removed; skip the proved475-byte
delete/access-check body. Skip the close433-byte body
and share129-byte body;
only CHARHARD/HARDERR operand bytes remain. Skip the open399-byte body and create316-byte body;
only symbol operands remain. Whole dircall644-byte body matches apart from
external call/jump operands; skip it. This supersedes earlier CHDIR/RMDIR proofs.
Whole mknode1200-byte body matches apart from external calls; skip it.
The P107 proof supersedes the overlapping P106 prefix. Skip whole dinfo651-byte body and
DOS_RMDIR265-byte body; their residual differences are external bindings.
ValidateCDS and DOS_ChDir bodies match; skip them. Whole dir.asm958 bytes and
dir2.asm1073 bytes now match apart from symbol
addresses; skip their bodies. Complete diskio/disk2/disk3/rom/FAT/buffer/device/cache
bodies have matching instructions; skip repeated body audits.
Resolve remaining upstream providers and shared data/cache placement;
external disk-call bindings and shared-data layout remain tracked.
Re-link the whole kernel after
each coherent group. Skip matching buffer/FAT instruction bodies.
Keep COMMAND's complete linked result in the same build baseline; do not switch
components to avoid an unresolved kernel dependency. Skip proven equal bodies.
Local standalone probes require an explicit unresolved encoding/tool question.
Do not report heuristic byte anchors as source recovery percentages.

Latest source continuation: S2 P106 restores directory allocation and dot-entry
providers in existing mknode.asm. Contiguous348 bytes leaves10 external call bytes.
Evidence ../etc/T20-S2-P106.json. Main MakeNode flow remains before caller work.

Previous source continuation: S2 P105 completes DISK_INFO and integrates DOS_RMDIR
high-word/root/release/writeback path. Whole651-byte dinfo and265-byte deletion
proofs retained in ../etc/T20-S2-P105.json. Creation dependency group is next.

Previous source continuation: S2 P104 restores missing FSInfo and primary/backup
boot-information writeback in existing dinfo.asm before directory deletion caller.
Whole361 bytes leaves only12 external call bytes. Evidence ../etc/T20-S2-P104.json.
No new implementation file; provider consumers remain to restore.

Previous source continuation: S2 P103 removes unreferenced target-absent FastOpen
tail296 bytes and consolidates whole dir2.asm1073-byte proof, leaving29 external
call bytes. Evidence ../etc/T20-S2-P103.json supersedes partial dir2 proofs.
Skip this module's body; remaining directory callers and bindings are next.

Previous source continuation: S2 P102 restores ValidateCDS and DOS_ChDir DWORD
currency handling with original tools/full link. Evidence ../etc/T20-S2-P102.json.
Remaining differences are external calls and NOTDIRPATH binding. Original ML
condition-width and Leave-macro differences resolved in source, not binary patches.

Previous source continuation: S2 P101 restores ROOTPATH/FINDPATH DWORD directory
currency, high-cluster arguments and buffer-sector preservation. Contiguous626
bytes through MatchAttributes leave7 external call bytes. Evidence
../etc/T20-S2-P101.json supersedes overlapping P100 prefix. Skip proved body;
remaining device/CDS tail is next.

Previous source continuation: S2 P100 completes dir.asm traversal and restores
dir2 GetPath32-bit CDS/search interface. Evidence ../etc/T20-S2-P100.json.
Whole958-byte dir module proof supersedes overlapping P99. Prefix210 bytes
of dir2 also matches except7 address bytes. Remaining path consumers are next.

Previous source continuation: S2 P99 restores FAT32 directory search/root setup
and six-byte SFT directory position records in existing dir.asm. Complete564-byte
group has only37 symbol-address bytes different after full link. Evidence
../etc/T20-S2-P99.json. Provider dependencies precede dir2 caller changes.

Previous source continuation: S2 P98 restores device DWORD stack operations and
DMA assignment order, with full kernel relink. Entire806-byte device module
has41 different address bytes; unchanged399-byte cache body has only42 cache
address bytes different. Evidence ../etc/T20-S2-P98.json. Resolve providers
instead of rewriting these matching bodies. No whole-image acceptance.

Previous source continuation: S2 P97 restores full disk3 main writing path and
removes unreferenced arithmetic helpers absent from target. Entire1145-byte
module matches except12 external address bytes. Evidence ../etc/T20-S2-P97.json
supersedes partial P96 proof. Skip matching bodies; layout and bindings remain.

Previous source continuation: S2 P96 restores complete WRTEOF/RELFILE/KILLFIL
length-setting branch with32-bit allocation/release interfaces.296-byte region
matches except11 call/branch address bytes outside scope. Evidence
../etc/T20-S2-P96.json. Continue main write/expansion and shared error paths;
do not accept whole disk3 or remove still-referenced arithmetic helpers yet.

Previous source continuation: S2 P95 restores disk2 file-read32-bit interface,
high-word state and SFT updates. Whole690-byte module comparison leaves40
external operand bytes, with identical internal layout. Evidence
../etc/T20-S2-P95.json. Disk3 writing caller group is next.

Previous source continuation: S2 P94 restores entire allocation/rollback middle
and RESTFATBYT, completing rom.asm internal layout and instructions. Full1429
bytes leaves only DeferredFlush address; integrated3934-byte rom/FAT/buffer group
leaves54 external operand bytes. Evidence ../etc/T20-S2-P94.json supersedes
partial rom comparisons. Skip matched bodies; caller integration remains open.

Previous source continuation: S2 P93 restores BUFWRT/NEXTSEC/OPTIMIZE together.
Their389-byte output matches except8 external call bytes. Consolidated726-byte
rom prefix through FIGREC matches except16 external call bytes, superseding
overlapping earlier counts. Evidence ../etc/T20-S2-P93.json. Allocation middle
is next; do not repeat proved prefix/tail audits.

Previous source continuation: S2 P92 restores complete FNDCLUS/SKPCLP/BUFSEC
group in existing rom.asm.211-byte comparison leaves seven external call bytes.
32-bit caller adaptations in disk2/disk3 are required and remain open; do not
claim integrated runtime correctness. Evidence ../etc/T20-S2-P92.json.

Previous source continuation: S2 P91 restores complete RELEASE/RELBLKS/GETEOF
tail in existing rom.asm.172-byte comparison leaves only DeferredFlush address
different. No new files; no rebuild for final comment-only interface description.
Evidence ../etc/T20-S2-P91.json. Allocation and preceding file-I/O helpers remain.

Previous source continuation: S2 P90 defines target high-word providers at AEE,
AF0,AF2, verifies FIGREC before restoring DirRead. Entire diskio module392 bytes
now has378 equal/14 external address bytes; FIGREC67 bytes exact. Evidence
../etc/T20-S2-P90.json. Remaining rom paths and shared data are not accepted.

Previous source continuation: S2 P89 restores complete FAT sector read/retry
flow in existing diskio.asm. Whole154-byte flow matches except HARDERRRW address.
Existing disk2 DskRead/DWRITE/DSKWRITE88-byte body also matches except external
calls, so no gratuitous rewrite. DirRead's high-word provider and remaining
file-I/O consumers stay open. Evidence ../etc/T20-S2-P89.json.

Previous source continuation: S2 P88 restores active FAT selection, 32-bit mirror
stride and BufWrite sector carry in existing buf.asm; original ML recipe added
to dos/makefile. Whole763-byte module comparison leaves only18 bytes in external
bindings, with no masking. Evidence ../etc/T20-S2-P88.json. Both linked operands
and final image placement remain open; no whole-file target acceptance yet.

Previous source continuation: S2 P86 restores FAT32 IsEOF and failed-BPB buffer
invalidation, then compares complete fat.asm output at actual module boundaries.
Full1742 bytes:1704 equal/38 different in external call/cache operands. Internal
layout matches; provider binding and image placement remain open. Full kernel
build passes. Evidence ../etc/T20-S2-P86.json supersedes partial FAT coverage
totals; do not add overlapping earlier regions. This part modifies1 file, adds0;
cumulative43, identical250; reviewed64 remains26 modified/38 unchanged.

Previous continuation: S2 P85 restores FSInfo read/validation/import and HMA buffer
transfer using existing DREAD. Complete kernel build passes. Full250-byte flow
through buffer completion compares248 equal/2 different bytes: only DREAD call
operand remains. Evidence ../etc/T20-S2-P85.json. Enclosing FAT module/layout
still needs comparison and provider restoration. This part modifies1 file, adds0;
cumulative43, identical250; reviewed64 remains26 modified/38 unchanged.

Previous continuation: S2 P84 restores first-FAT bootstrap geometry, extended BPB
preparation and32-bit FAT buffer stride in existing fat.asm. Complete kernel build
passes;41-byte BPB preparation and45-byte buffer tail compare exactly. FSInfo
read/validation/import remains absent between these regions and is next.
Evidence ../etc/T20-S2-P84.json. This part modifies1 file, adds0; cumulative43,
identical250; reviewed64 remains26 modified/38 unchanged. No whole FAT acceptance.

Previous continuation: S2 P83 restores DWORD CDS invalidation, FATERR free-count
handling and first-access/dirty-bit separation. Complete kernel build passes.
Continuous313-byte media-entry/error/status region compares303 equal/10 different
bytes, all differences in five external call operands. Evidence ../etc/T20-S2-P83.json.
Next restore changed-media/BPB/buffer continuation. This part modifies1 file,
adds0; cumulative43, identical250; reviewed64 remains26 modified/38 unchanged.
No full FAT module acceptance or publication.

Previous continuation: S2 P82 restores FAT32 PACK in existing fat.asm. Complete
kernel link passes. Contiguous UNPACK/PACK/MAPCLUSTER729 bytes compare711 equal,
18 different: nine external call/cache address words. Internal layout and calls
match target. PACK itself239 bytes has10 differing bytes, included in that total.
Evidence ../etc/T20-S2-P82.json. Next restore FAT media/allocation consumers and
provider bindings. This part modifies1 file, adds0; cumulative43, identical250;
reviewed64 remains26 modified/38 unchanged. No whole-module acceptance/publication.

Previous continuation: S2 P81 restores complete MAPCLUSTER in existing fat.asm.
Full kernel build passes. Entire251-byte procedure compares247 equal/4 different
bytes; the four bytes are two GETBUFFRB call operands. FAT12 split-sector logic,
FAT16/FAT32 addressing and high-sector propagation match without exclusions.
Evidence ../etc/T20-S2-P81.json. Next restore PACK and remaining FAT consumers.
This part modifies1 file, adds0; cumulative43, baseline-identical250; reviewed64
remains26 modified/38 unchanged. Full image still differs; no publication.

Previous continuation: S2 P80 restores FAT32 UNPACK in existing fat.asm and seven
high-word data dependencies at0AE0..0AEC. Original ML/full kernel build passes.
Full239-byte UNPACK comparison:234 equal/5 differing bytes, solely within three
address operands (CL0FATENTRY, MAPCLUSTER, FATAL). All233 other bytes match.
Evidence ../etc/T20-S2-P80.json. Next restore MAPCLUSTER/PACK and remaining FAT
consumers; no complete fat.asm acceptance. This part modifies3 files, adds0;
cumulative43, baseline-identical250 (212 unreviewed), in-progress17. Reviewed64
remains26 modified/38 unchanged. No publication.

Previous continuation: S2 P79 restores DWORD ExitHold pop, PDB LSS, DWORD
CL0FATENTRY and direct DeferredFlush conditional transfer. Complete kernel
build passes. Entire1380-byte msctrlc region now compares at corresponding
layout:1319 equal/61 different bytes. Exit restoration14 bytes are exact.
Remaining call/address operands and FAT32 CL0FATENTRY consumers are open.
Evidence ../etc/T20-S2-P79.json. This part modifies1 file, adds0; cumulative42,
baseline-identical251; reviewed64 remains26 modified/38 unchanged. No publication.

Previous continuation: S2 P78 restores shared high-register recovery and both
INT23/INT24 LSS transitions within msctrlc.asm. Complete kernel rebuild/link
passes; direct comparisons prove67/9/9 bytes exact at linked procedure boundaries.
No new file; existing msdisp saves and stack symbols supply all dependencies.
Evidence ../etc/T20-S2-P78.json. This part modifies1 core file; cumulative42,
baseline-identical251; reviewed64 remains26 modified/38 unchanged. Full msctrlc
and whole-image placement remain open. Next compare the enclosing linked module
to identify remaining substantive changes and external bindings.

Previous continuation: S2 P77 restores high-sector carry and FAT32 error-area/free
count handling in existing msctrlc.asm. Target-matching177-byte region precedes
FATALC; the remaining INT24 path is not yet accepted. Shared invocation/jump
macros now handle ML procedure declarations without changing MASM5 branches.
Complete kernel/BIOS builds pass; BIOS75616-byte direct comparison still passes.
Evidence ../etc/T20-S2-P77.json. This part modifies3 core files, adds0; cumulative
modified42, baseline-identical251. Reviewed64 remains26 modified/38 unchanged.

Previous continuation: S2 P76 restores the complete SETUP disk-I/O preparation
procedure in diskset.asm with32-bit arithmetic and FAT32 cluster validation.
Original ML/full kernel link/repack pass. All158 procedure bytes match target
at map-corresponding addresses7A67/8349; no excluded operands. HARDERR binding
and preceding module lengths remain open, so diskset stays in progress.
Evidence ../etc/T20-S2-P76.json. This part modifies2 core files, adds0; cumulative
modified41, baseline-identical252 (214 unreviewed), in-progress15. Reviewed64
remains modified26/unchanged38. No assets published. The P75 region proof below
belongs to its retained snapshot; later provider movement changes call operands.

Previous continuation: S2 P75 restores RW32_CONVERT and Windows startup checks in
dos/mscode.asm. Complete kernel rebuild/link and repack pass. Direct linked
comparisons prove65-byte RW32_CONVERT,46-byte startup check and51-byte control
service exact, without address exclusions. Across the enclosing1168-byte region,
1137 bytes match and31 differ; this is local coverage, not whole-image progress.
Evidence ../etc/T20-S2-P75.json. This part modifies1 core file, adds0; cumulative
counts unchanged. Next resolve external disk/provider and DOSDATA operands rather
than re-audit the matching procedure bodies.

Previous continuation: S2 P74 restores absolute-write free-count invalidation and
protected-write error handling, removes obsolete Fastxxx_Purge call, and uses original
Microsoft ML via makefile with an EXTERNDEF branch in the shared INVOKE macro.
Full kernel/BIOS rebuilds pass. Write179/setup52 bytes match; BIOS75616-byte
region remains exact. GETBP now461D matches target. Evidence ../etc/T20-S2-P74.json.
This part modifies3 core files; total modified40, baseline-identical253
(215 unreviewed), in-progress14. Reviewed64 = modified26 + unchanged38: dosmac
changes category following actual tool adaptation. No new core files/publication.

Previous continuation: S2 P73 restores absolute-I/O mode-aware setup, legacy FAT32
rejection, conditional stack switching and near/far return paths in mscode.
Original kernel build passes;103 bytes in three linked regions match target.
ABSDRD449D/ABSDWRT454B match target. Write-specific free-count invalidation,
error-field binding and external disk calls remain open. Evidence:
../etc/T20-S2-P73.json. This part modifies1 file; total modified38, reviewed64
(modified25/unchanged39), no new core files or publication.

Previous continuation: S2 P72 restores18-byte LFN directory-state records and their
scan/swap/restore/copy/search consumers. Remove unused FastSeek declarations;
TEMP_DOSLOC, three records, absolute-I/O flag and high cluster words now match
target addresses0AA3..0ADE. Three linked regions104/103/26 bytes match exactly.
Remaining state after0AE0 and FastOpen layout still need restoration; modules
remain in progress. Evidence ../etc/T20-S2-P72.json. This part modifies3 files;
total modified38, baseline-identical255 (216 unreviewed), in-progress13;
reviewed64 remains modified25/unchanged39. No new core files or publication.

### Owner execution-method correction — full build first

The owner explicitly replaced serial small-probe work with complete-build-first,
binary-difference-driven restoration. Run the existing extras/build.cmd on the
current full source tree; retain its maps/listings and failed-stage logs. Fix
actual build blockers first, then locate linked differences by source module.
Reuse already established matches without re-auditing or re-probing them. A
remaining external binding does not prevent a diagnostic integration build.
Keep the existing source ledger and BIOS SCC; do not claim an unfinished member
complete. Publication still requires all three exact outputs. Source baseline
remains v7.00.950 only. Historical compiler/library assets are tooling, not a
license to consult another source baseline.

The 63 absent msbio1 Bios_Code bytes are now source-attributed: ORG 30h leaves
48 bytes, ORG 40h leaves 10 bytes, and off_d0 reserves 5 uninitialized bytes for
the runtime CP/M CALL 5 entry. These are not missing source instructions; their
final linked contents remain an integration check. Core counts remain modified
15, reviewed unchanged 40. No source change or local probe rebuild in this step.



### S2 P1 — first dependency-free units

1. dos/msdos.cfg: target nine-byte configuration restored; FC /B and SHA256 match.
2. inc/versiona.inc: minor_version=10; MASM 5.10A/LINK/RELOC probe emits 07 0A, directly equal to target IO.SYS field at 76137; expected_version=0A07. No consumer files edited or global build claimed.

Read actual make/link recipes and scanned all 293 core files: 1079 textual INCLUDE edges, no textual INCLUDE SCCs, nine special include sites (generated messages, dynamic macro parameters and inactive ROMDOS-only command.loc). These do not yet resolve the complete semantic/link graph. The 111 possible transitive version consumers are recorded for later object regeneration. Only independently proven leaf units were admitted; no unresolved consumer was edited.

Evidence: ../etc/T20-S2-P1.json; dependency frontier: ../etc/S2-dependency-frontier.json. The directory build retains its all-three comparison publication gate; no assets were published.

### S2 P2 — standalone loader restored

Execution unit 3, inventory file 53: bios/msload.asm. The active DOS7_CONFIG branch has no INCLUDE or external-symbol dependencies; shared BPB definitions are not prerequisites for this selected branch. Preserved the module and inactive original-code branch; added no source file. Restored FAT32 cluster handling, extended disk reads, BPB expansion and four-sector loading.

Original ML with the formal makefile defines and /Zm, followed by LINK, produces a 1536-byte loader span exactly equal to target IO.SYS offsets 512..2047 (FC /B exit 0). SHA256: 7a5ef4ac1121f4b0039e9de0aca00bde8352843cef926e6ab5e037e9b9ea297c. No binary patching. LINK's no-stack warning is expected for this boot loader. Evidence: ../etc/T20-S2-P2.json.

Corrected layout: 1111 BIOS starts at 2048, not the 950 offset 1536. Earlier BIOS matching percentages using the old start are not valid restoration metrics. Full IO.SYS/COMMAND.COM remain incomplete.

### S2 P3 — linked loader extent used by container

extras/tools/ioimage.c now derives the loader length from its validated MZ image; sector alignment and terminal MS signature are checked. Both allocation/layout arithmetic and copy length use this value. No version branch or target-byte substitution was introduced.

Compiled with GCC C89 and warnings enabled. Repacking the existing 950 linked inputs reproduces its entire 223148-byte IO.SYS exactly. A layout-only fixture using the newly compiled 1111 loader and the same 950 remaining inputs preserves all 1536 loader bytes and places the full unchanged BIOS at 2048, verified by FC /B. This mixed-version fixture is not a 1111 acceptance result and was not published. Evidence: ../etc/T20-S2-P3.json.

Counts: core processed 3 (modified 3, unchanged 0); tools processed 1 (modified 1, unchanged 0). No new source files. Next establish the BIOS dependency unit: msbio1 includes version/biosseg/devsym/msequ/bpb/bootform/msbds/oemconf and links to init/int_2f providers. Do not patch consumer fields before resolving these dependencies.

### S2 P4 — FAT32 BPB and BDS structures

Dependency-first units 4 and 5: inc/bpb.inc then inc/msbds.inc. The shared BPB now has the 28-byte FAT32 extension after its unchanged 25-byte common prefix, replacing the legacy six-byte tail. The BDS grows from100 to150 bytes: actual BPB gains28 bytes and recommended BPB gains22. Its recommended BPB now carries target initial values instead of zero fill; root-entry and total-sector defaults match the target.

MASM5.10A/LINK/RELOC probes pass size/offset assertions and complete byte comparisons: BPB53 bytes at target23692 and BDS150 bytes at23686. BDS SHA256: 3b304fd0651d07233e45fcb22da0fa4ea7b5918ef59538eee712970ee38c0488. Existing flat structure style retained, no new source file. Evidence: ../etc/T20-S2-P4.json.

Current counts: core modified5, unchanged0; tool modified1. Four boot-drive templates in msbio1 remain pending. A real msbio1/msinit symbol cycle is confirmed (init in one direction, hdrv_pat/dosdatasg in the other); resolve the full linked component and other header prerequisites before editing consumer code. No full-image build or publication claimed.

### S2 P5 — actual linker dependencies and BIOS messages

The final audited 950 P39 objects expose1509 resolved symbol edges, zero missing providers, and an18-module cyclic BIOS component. Earlier native-all-source objects predate the source mergers and were rejected for graph construction. See ../etc/S2-bios-link-components.json. Source include dependencies still apply; the object graph alone is not whole-source completion.

Units6/7 restore lang/usa/messages/biosmsg.inc and bios/biosmsg.asm in that order. Added the sixth incompatible-startup-version message and its offset; resource header/size/end values and MPAD reservation now match1111. Original MASM/LINK/RELOC produces1186 bytes exactly matching target offset20976, including header, all messages, trailer and reserve. SHA256:4d128c2b9990dd68f65ab796ea273709bdfe826a0813c9c7cb5b467c8be69bdc. Evidence: ../etc/T20-S2-P5.json.

P5 counts: core modified7, unchanged0; tool modified1; no new source files. The four boot-drive templates were deliberately not edited ahead of their component's providers. Provider ordering was corrected in P6 below. No full-image build or publication claimed.

### S2 P6 — unchanged self-contained providers

Units8/9: drivechk.asm and logpart.asm remain byte-identical to accepted950 source. Complete emitted modules (335 and432 bytes) match target at67294 and65572 after resolving each of17 and8 internal address words. All other301 and416 bytes are exact, including relative calls/jumps. Matching is unique; an incorrect segment-base control fails. No source modification or unnecessary recompile. This is full-module relocation-aware verification, not raw whole-image equality.

Unit10: msend.asm is unchanged and contains only three zero-length paragraph-aligned segment declarations and endpoint labels. No code/data or external dependency. Final linked label values remain an integration check. Evidence: ../etc/T20-S2-P6.json.

Corrected dependency order: ststate, sysimes, then the18-module BIOS component, then pathsrc. Although pathsrc is a singleton, it imports config_envlen/config_wrkseg from sysconf inside the component and is not an upstream provider. Current counts: processed10, modified7, unchanged3; tools modified1. Full three-output acceptance remains pending.

### S2 P7 — SYSINIT state values

Units11/12: oemconf.inc and exe.inc are byte-identical to DOS6 and retained. Their default values and EXEC0 layout pass validation in the state module. Unit13: ststate.asm changes only temp_buffer_size4014h to4018h and sysinit_reserve_size114Ch to1286h. Target initialization at file5089 directly loads CX=1286h before storing sysinit_reserve_count; this agrees with the kernel/BIOS file-boundary calculation.

Original MASM/LINK/RELOC with a verification-only segment placement fixture produces the full272-byte state block exactly equal to target offset27499, including all relocated pointers. SHA256:3d41cfbec436abb07ef5f5c7697bc2656132fa96d2bc74caef3bebda8ade1fe5. This proves state data at the known target placement; it does not prove the full BIOS layout. Four following zero bytes belong to sysinit1 MagicBackdoor, not additional state fields. Evidence: ../etc/T20-S2-P7.json.

Current counts: processed13, modified8, unchanged5; tools modified1. No new source files. Next sysimes and its message include prerequisites; remaining BIOS cycles and full-image integration are pending.

### S2 P8 — SYSINIT message order

Units14/15 retain version.inc and biosseg.inc exactly as accepted950. Both have no INCLUDE/EXTRN; the selected non-ROM message context passes original-tool assembly. This does not certify their other consumers. Unit16 moves the existing386/A20 messages and matching index entries to the start of sysimsg.inc; text and semantic labels remain unchanged. Unit17 retains sysimes.asm, whose header derives the resource dimensions.

Original MASM/LINK/RELOC generates all4307 bytes exactly equal to IO.SYS67632..71938, including64-message header,65 offsets and text. FC /B exit0; SHA256314f6d91ea1d9117fcce605026adbd14f1bd9004a440ef99a201b508b29b6189. Evidence: ../etc/T20-S2-P8.json. No new core file, binary substitution or publication.

Current counts: processed17, modified9, unchanged8; tools modified1. Next resolve remaining include prerequisites for the18-module BIOS cycle, then restore that component and its numeric message-index consumers. pathsrc follows the cycle. Full three-output byte identity remains pending.

### S2 P9 — shared device and BIOS definitions

Units18..22 retain devsym.inc, msequ.inc, msdskpr.inc, biostruc.inc and bootform.inc byte-for-byte against original DOS6. Full definitions and dependencies reviewed. The target CON header at2070 verifies SYSDEV18-byte layout; dispatch at8768 verifies request packet offsets1/13/18/20/28/26/2/14/3. Disk-table/system-descriptor/legacy boot-header definitions are source-reviewed only; their consumer validation remains open. No assembly change or unnecessary rebuild.

Located a concrete pending msbio1 difference: target8863 has D1 E0 (SHL AX,1), where the950 source uses ADD AX,AX. Restore inside the BIOS SCC once its remaining include prerequisites are resolved, together with the four local BDS templates. Evidence: ../etc/T20-S2-P9.json. Current counts: processed22, modified9, unchanged13; tools modified1. No new core files. Full-image identity remains pending.

### S2 P10 — legacy and extended IOCTL parameter layouts

Unit23: ioctl.inc retains the legacy31-byte device BPB despite A_BPB growing to53. Added the extended48h category and packet definition in this same include:53-byte BPB followed by32 reserved bytes. Legacy track count/table offsets remain38/40; extended offsets are92/94. Packet sizes292/346 pass original MASM assertions.

Eight compiled instruction spans totaling23 bytes match corresponding target instructions exactly, including copy lengths31/53, reserved length32, both track offsets and category48h. This is structure/constant validation, not full IOCTL code acceptance. Target slicing is comparison-only. No new core file or output substitution. Evidence: ../etc/T20-S2-P10.json.

Current counts: processed23, modified10, unchanged13; tools modified1. Remaining shared prerequisites, including FAT32 DPB and SYSVAR dependencies, precede the18-module BIOS component. Its msdioctl consumer still needs the target48h dispatch/copy logic. No full-image acceptance or publication.

### S2 P11 — FAT32 drive parameter block

Unit24: dpb.inc now defines61 bytes. The free count at1Fh is32-bit; flags/FSInfo/backup boot/first sector/max cluster/FAT size/root cluster/next-free fields occupy23h..3Ch. Target BPB conversion, FSInfo ingestion and startup allocation independently establish field meaning and3Dh stride. No INCLUDE/EXTRN; caller BREAK macro is listing-only.

Original ML/LINK/RELOC validates ten size/offset assertions and emits ten instruction spans totaling45 bytes exactly matching target. MASM5 uses a different valid386 prefix order; original ML reproduces target order without binary patching. Final probe assembles cleanly. Evidence: ../etc/T20-S2-P11.json.

Current counts: processed24, modified11, unchanged13; tools modified1. Existing DPB consumers remain pending: retain explicit WORD PTR where target uses low16 bits, and restore DWORD operations where required. Continue shared SYSVAR/macro prerequisites before BIOS SCC changes. No full-image acceptance or publication.

### S2 P12 — unchanged system definitions and remaining include closure

Units25..30: sysvar.inc, curdir.inc, arena.inc, rombios.inc, devmark.inc and cputype.inc are fully read and FC /B exact against v7.00.950. Direct950 comparison was completed after the owner corrected the reference policy. No INCLUDE/EXTRN or NT/BOP additions. Retained original code; no rebuild. These six are definition/source-reviewed only, not target-consumer validated. The CPU macro has no invocation in the current BIOS source scan.

The18-module BIOS SCC has24 remaining transitive include files after these units. Their explicit closure is recorded in ../etc/T20-S2-P12.json. Next inspect PDB/SF and remaining structure/constants, then resolve dosmac/dossym context and the executable parse/highload/highexit/mrcf includes. A textual leaf alone does not prove semantic independence.

Current counts: processed30, modified11, unchanged19; tools modified1. No new core files. Full-image identity remains pending.


### Owner reference-policy correction

Use only v7.00.950 as source reconstruction baseline and the frozen7.10.1111 image as target evidence. Do not consult or compare any other version, including for style. Earlier other-version comparisons above are historical activity, not acceptance criteria or authorization for further reference work. The codebase remains the full950-derived tree; no alternate baseline was substituted. Counts unchanged: modified11, unchanged19; tools modified1.


### S2 P13 — PDB retained and local FAT32 SFT aliases

Unit31 pdb.inc is FC /B exact against950 and retained. Unit32 sf.inc preserves59-byte entry layout while defining aliases for local FAT32 first-cluster2Bh, last-cluster35h, their high words and cluster-position high word0Bh. Target allocation and transfer paths establish these meanings; no other version was consulted.

Original-tool probe passes layout assertions and six exact instruction comparisons totaling23 bytes. SFT consumers are not yet restored or accepted. Evidence: ../etc/T20-S2-P13.json. Current counts: processed32, modified12, unchanged20; tools modified1. No new core files, no full-image acceptance or publication.


### S2 P14 — CONFIG and interrupt definitions

Units33..36 retain bios/config.inc, inc/syscall.inc, inc/mult.inc and inc/error.inc, all FC /B exact against950. Full source and caller context reviewed; no INCLUDE/EXTRN. Complete303-byte CONFIG command table at950 offset33012 equals1111 offset37949, through SWITCHES and its final zero. No unchanged source recompile.

The three interrupt/error files are source-reviewed only, not full target-consumer validation. Evidence: ../etc/T20-S2-P14.json. dirent.inc and buffer.inc remain open despite initial reading; do not infer FAT32 mappings from an arbitrary same-offset instruction. Current counts: processed36, modified12, unchanged24; tools modified1. No new core files; full-image identity pending.


### S2 P15 — FAT32 directory first-cluster high word

Unit37 dirent.inc adds DIR_FIRST_HI at14h as a WORD alias within the existing reserved area, retaining32-byte directory layout. Mapped950 CloseSetFields to target: SFT first-cluster low/high2Bh/2Dh transfer to directory1Ah/14h, followed by size/date/time stores.

Original-tool probe using sf.inc and dirent.inc generates the complete contiguous42-byte update block at target91683 exactly. Clean assembler log; FC /B exit0. Evidence: ../etc/T20-S2-P15.json. This does not certify or modify the full close.asm consumer. Current counts: processed37, modified13, unchanged24; tools modified1. Continue buffer and remaining shared dependencies. No full-image acceptance or publication.


### S2 P16 — 32-bit FAT buffer spacing

Unit38 buffer.inc changes FAT copy spacing to DWORD and aligns the header to24 bytes. DPB pointer moves to0Fh, data begins18h; these follow target GETBUFFR, BufWrite and FAT metadata stores, not unrelated displacement matches. Retained trailing950 fields, padded to DWORD boundary; their full consumer behavior remains pending.

Original-tool probe passes layout assertions and five instruction-span comparisons totaling24 bytes. Evidence: ../etc/T20-S2-P16.json. Final comment-only adjustment does not change instructions and was not rebuilt. Current counts: processed38, modified14, unchanged24; tools modified1. Next resolve remaining macro/include prerequisites; buffering consumers still need32-bit arithmetic. No full-image acceptance or publication.

### S2 P17 — macro and segment context

Units39..45 retain dbcs.sw, dosmac.inc, dossym.inc, doscntry.inc, ds_vers.inc, umb.inc and msgroup.inc exactly against v7.00.950 (FC /B exit0 each). No source edits or rebuild. Definition/context review does not establish target consumer equality.

Dossym supplies DEBUG/Installed before including dosmac, then uses its macros. They form one semantic context unit, not a textual include cycle. Invocation-generated externals and layout-sensitive jumps remain consumer obligations. Msgroup depends on the reviewed biosseg segment context. DS_INTERNAL_REVISION12 and UMB/NLS layouts remain subject to target consumer evidence.

Evidence: ../etc/T20-S2-P17.json. Processed45 core files: modified14, unchanged31; tools modified1. Nine remaining transitive BIOS includes are listed in the evidence. Resolve their context before restoring the18-module BIOS component. Full three-output identity and publication remain pending.

### S2 P18 — copyright and remaining BIOS definitions

Units46..49 retain copyrigh.inc, win386.inc, magicdrv.inc and highvar.inc exactly against950. The full117-byte USA copyright resource equals target offsets37570 and107655; both comparisons pass. No instruction changes or rebuild.

WIN386 and compressed-volume structures remain definition-reviewed pending consumer validation. Highvar emits local data in the BIOS context, with CS-based access macros; do not confuse this with its COMMAND external-data branches. Highexit was read but remains unprocessed until its arena/highvar/highload caller context is resolved.

Evidence: ../etc/T20-S2-P18.json. Processed49: modified14, unchanged35. Five executable/data include prerequisites remain: psdata, parse, highload, highexit and mrcf. Full three-output identity remains pending.

### S2 P19 — remaining BIOS include verification

Recorded psdata, mrcf, highload, highexit and parse. Complete decoder2641 bytes, DEVICEHIGH selected code1881 bytes, and parser/data2409 bytes have relocation-aware comparisons. All remaining bytes match exactly; address fields are resolved against segment placement or named source variables. No unchanged-source rebuild. Evidence: ../etc/T20-S2-P19.json. Reviewed54: modified14, unchanged40; no full-image acceptance.

### S2 P20 — msbio1 restoration in progress

Applied the target150-byte boot-drive BDS layout and SHL AX,1 dispatch instruction in the existing module. Original ML/LINK/RELOC now passes: all600 template bytes and the two instruction bytes match the frozen target, FC /B exit0 each. The probe uses known target segment placement; full module/link acceptance remains pending. Command-line execution succeeded through the authorized tool boundary. No new core source file. Evidence: ../etc/T20-S2-P20.json. This file remains open within the BIOS SCC. Total changed core files15, reviewed unchanged40; full three-output identity remains pending.

### S2 P22 — fourth BIOS error report restored

Restored the fourth message branch in msbio1 using the existing bios_msg_4 provider. The full68-byte procedure matches target10485 in an original-tool placement probe. Complete module still assembles. OMF code-segment comparison now finds zero differences among1739 emitted non-relocation bytes;106 relocation bytes and63 absent positions are explicitly excluded. This is not whole-module acceptance.

Evidence: ../etc/T20-S2-P22.json. Core counts remain modified15, reviewed unchanged40; one existing file changed this part, no new core files. Continue the same open msbio1 member, including data and relocation binding.

### S2 P23 — BIOS initial data values

Restored DosDataSg B146h and bios_flags1216h from their identified target header fields. Complete module compiles with only the two inherited ASSUME CS warnings. Bios_Data1067, SysInitSeg4399 and Bios_Code1739 emitted non-relocation bytes now compare without differences. All388 relocation bytes and63 absent positions remain explicitly outside this proof.

Evidence: ../etc/T20-S2-P23.json. Same existing file modified; totals modified15, reviewed unchanged40, no new core files. Continue symbol/frame binding within the open BIOS SCC; no full-image identity or publication.

### S2 P24 — integrated build and binary-difference baseline

Following the owner's method correction, ran extras/build.cmd on the current
complete source tree. BIOS, kernel, COMMAND, resource, CRT and configuration/
registry compile/link phases all completed through the private-desktop runner.
Packaging initially failed because ioimage searched for SI_end while the map
contains SI_END. Changed only its symbol-name comparison to ignore ASCII case;
recompiled that host C tool and reused the existing linked inputs. All three
diagnostic outputs now exist in extras/build/cmd-17081-23949/out.

Output | Built bytes | Target bytes | Exact result
--- | --- | --- | ---
IO.SYS | 225708 | 214836 | different
MSDOS.SYS | 9 | 9 | equal, FC /B
COMMAND.COM | 92870 | 93812 | different

Build maps, listings, exact comparison logs, output hashes and order-preserving
binary anchor logs are retained in that same build directory. Anchors are search
aids, not source-restoration percentages. IO configuration starts at179200 in
the build and187392 in target; linked BIOS_CODE starts at local1650h versus
target file8704. Differences must be mapped by segment/module, not raw offset.
BIOS_DATA_INIT is supplied by msinit.asm; it is the next integrated difference
restoration focus within the same open BIOS SCC. msbio1 is not marked complete.

The original build result remains failed; repack.cmd/analyze.cmd independently
record successful diagnostic output generation, not exact acceptance. No asset
publication or boot validation. ML.err is absent from the inherited staged tool
list, which suppresses some warning text; this did not prevent object/link
generation and is a tool-diagnostic follow-up, not a new source probe.

This part modifies one existing tool file and zero core files. Cumulative core
modified15, reviewed unchanged40; tools modified1. Evidence:
../etc/T20-S2-P24.json. Continue complete-image difference-driven restoration;
do not resume serial micro-probes or re-audit already proven matching blocks.

### S2 P25 — default BPBs restored in integrated BIOS

Mapped the initialized data differences to bios/msinit.asm. Extended the local
bpbx by28 zero-initialized FAT32 fields to53 bytes and changed its five alignment
bytes to the target zero values. The existing setdrvparms SIZE bpbx consumer
now copies53 bytes automatically. Retained all four existing floppy parameters
and module structure; no new source file or alternate implementation.

Copied the changed module into the existing integrated build directory and ran
original NMAKE: only msinit was assembled, followed by full BIOS LINK/RELOC.
Repackaged the complete IO.SYS from the linked components. Four BPBs including
their trailing alignment bytes match exactly: built file4030..4245 versus
target4040..4255, length216. Listing confirms offsets012F/0165/019B/01D1 and
SIZE bpbx=0035h; the source-grounded block match is recorded by blockdiff.
No probe executable was used. Three inherited warnings remain; staged ML.err
was supplied from the existing tooling copy so their text is visible.

The two FAT tables and their consumers remain to restore in this same module;
the tables precede the BPBs and currently account for the10-byte placement
difference. Do not mark msinit or the BIOS SCC complete. Current output sizes
remain225708/9/92870; sector rounding means this112-byte source-data growth need
not change the outer file length. Counts: this part changes1 core file;
cumulative modified16, reviewed unchanged40; tools modified1. Evidence:
../etc/T20-S2-P25.json. No assets published.

### S2 P26 — disk parameter tables and32-bit FAT calculations

Replaced the unused legacy disk table and old high-word-first limit records
with the target FAT16/FAT32 tables: seven and five ten-byte records. Restored
DWORD sector-limit scanning, default FAT-size calculation, and the FFOTHER
recommended-BPB calculation with32-bit multiplication/division and separate
legacy/extended FAT-size storage. Kept these in msinit's existing procedures;
no new core file or alternate implementation. Extended the existing short
set_recbpb transfer to a near jump after the procedure grew.

Original NMAKE reassembled msinit and linked/relocated the full BIOS; existing
linked kernel/COMMAND/configuration artifacts were reused. p26check.cmd extracts
only from the complete IO.SYS, not a probe. Direct FC /B passes:

Source block | Built file offset | Target file offset | Exact bytes
--- | --- | --- | ---
FAT16 and FAT32 parameter tables | 3900 | 3900 | 120
scan through default FAT calculation, before clear_ids binding | 6891 | 7409 | 202
process_other through cluster selection, before constant-address operands | 7315 | 7833 | 189

Evidence and the full checkpoint image/map/listing/log are retained under
extras/build/cmd-17081-23949/p26. The511-byte claim covers only these named
blocks. Hard-disk selection of the FAT32 table, partition recognition, backup
boot reads and validated BPB ingestion remain incomplete. The existing
init_temp_h consumers still need replacement before its bytes can become the
target FAT32/read-retry flags; do not introduce overlapping flag aliases.
Next restore that coordinated hard-disk path in this same open module.

Counts unchanged: cumulative core modified16, reviewed unchanged40; this part
modifies1 existing core file, no new source files. No full-image acceptance or
publication. Evidence: ../etc/T20-S2-P26.json.

### S2 P27 — coordinated hard-disk FAT32 path

Restored getboot's three-read retry and signature result, direct-volume boot
validation, primary partition types0Bh/0Ch, FAT32/LBA selection, backup boot
sector retry at partition start+6, extended BPB validation/copy,32-bit cluster
count/type classification and recommended hard-disk cylinder calculation.
Removed all init_temp_h consumers before replacing that word with separate
init_fat32 and init_boot_retry bytes; no overlapping temporary aliases or new
implementation files. Existing procedures and the two tables from P26 remain
the implementation. Unknown-media FAT32 selection now reaches disktable32.

Applied23 localized source hunks after automatic review rejected a whole-file
replacement. The safer localized patch succeeded; no approval remains pending.
Original ML/NMAKE and full BIOS LINK/RELOC pass with the same inherited warnings.
The complete IO.SYS now has226220 bytes; outer sector-aligned placement changed.
This size change is not a recovery percentage or acceptance result.

p27check.cmd compares slices of the complete linked image directly with target:

Source block | Built offset | Target offset | Exact bytes
--- | --- | --- | ---
getboot and sethard through extended-read call site | 6148 | 6213 | 563
CHS read, backup retry and boot-record validation | 6714 | 6779 | 396
validated BPB ingestion and cluster/type arithmetic | 7119 | 7184 | 190
unknown-media table selection and default FAT arithmetic | 7324 | 7389 | 222
recommended-BPB arithmetic before constant references | 7768 | 7833 | 189

All five FC /B checks return0, totaling1560 bytes at this checkpoint. These
overlap prior P26 proof; do not add the counts as newly recovered unique bytes.
External function offsets and remaining earlier/later module differences are
outside this exact proof. Full image/map/listing/log retained under
extras/build/cmd-17081-23949/p27. Continue on msinit's remaining integrated
differences, including earlier initialization and disk-helper tails. Neither
msinit nor the BIOS SCC is complete. Counts remain core modified16, reviewed
unchanged40; this part changes1 existing core file. No assets published.
Evidence: ../etc/T20-S2-P27.json.

### S2 P28 — vectors and extended partition helpers

Restored DWORD clearing and MOVSW vector copies, reused BX for the BIOS segment
when installing interrupt handlers, and matched the target debugger-vector
stores. Updated domini for getboot's separate signature/CF result. Extended
partition scanning now preserves the incoming buffer pointer, uses partition
type-relative CHS/LBA fields, checks the1FEh table boundary, and returns BX.
init_ext_read initializes AX=4200h. setmini recognizes FAT32 and LBA types and
sets the existing flags before entering sethard's shared path. No new files or
parallel implementations.

Original incremental ML plus full BIOS LINK/RELOC and repack pass. Three direct
comparisons from complete IO.SYS pass via p28check.cmd: vector initialization
269 bytes (built4438,target4445), continuous getboot/sethard path962 bytes
(built6147,target6213), complete setmini78 bytes (built8415,target8481). Total
at this checkpoint1309; ranges overlap previous proofs and must not be added
as unique progress. Snapshot image/map/listing/log under
extras/build/cmd-17081-23949/p28. Outer IO size remains226220; no exact full-image
acceptance or publication.

CPU/A20 message references remain open: target CPU error path switches DS to
the paragraph containing the message resource and uses relative offsets008Ah
and0008h. Current source still directly addresses SYSINIT message symbols from
the old data context. Resolve provider placement and both consumers together;
do not substitute the target segment constant1073h into source. Other earlier
initialization differences remain. Same open msinit/SCC; counts core modified16,
reviewed unchanged40, this part modifies1 existing core file. Evidence:
../etc/T20-S2-P28.json.

### S2 P29 — CPU/A20 indexes corrected; message frame remains open

Changed msinit's inherited61*2/62*2 message indexes to0*2/1*2, matching
sysimsg.inc's first two entries. Integrated original ML/LINK/RELOC and repack
pass. Listing external addends are0000/0002; target accesses resource offsets
0008/000A. This proves the index correction only, not the message path.
Current map TABLE04BF:AB18 and BASE04BF:AB9A still use a different frame from
target DS1073h/table0008h/base008Ah. Resolve resource-relative addressing and
provider layout without substituting target address constants or breaking
existing SYSINIT consumers. Same open module; counts modified16, reviewed
unchanged40. This part changes1 existing core file. No publication.
Evidence: ../etc/T20-S2-P29.json.

### S2 P30 — resource-relative CPU/A20 messages

Changed the existing sysimes provider from SYSINITSEG to paragraph-aligned
SYSINITMSG in the same SYSTEM_INIT class. No duplicate resource or new source
file. Declared its externals in that segment in msinit, switched DS through a
segment relocation for each message use, restored DS afterwards, and used ES
for the resident A20 pointer store. The indexed message contents are unchanged.
This is a provider placement correction required by the open consumer, not a
new style audit. Prior P8 proved resource bytes only, not its integrated frame.

Original ML/NMAKE plus complete BIOS LINK/RELOC pass. Current map reports
SYSINITMSG0F71:0000, table0008h/base008Ah. RELOC70h produces0FE1h in both calls;
target1073h differs because preceding BIOS modules remain incomplete. The
current resource file base65296 and runtime segment0FE1h are consistent:
(65296-2048)/16+70h=FE1h. No target segment constant is embedded in source.

p30check.cmd directly compares all4307 resource bytes at built65296 against
target67632. CPU20-byte and A2025-byte blocks match in all39 bytes outside the
two explicitly checked segment words. CPU file4425 and A20 file6001 map to
target4425/6052. Snapshot image/map/msinit listing/build log retained under
extras/build/cmd-17081-23949/p30. A SYSINIT1 consumer at file27675 still encodes
BE AB9Ah / CS:[AB46h], preserving its SYSINIT frame; this is a checked example,
not full acceptance of all message consumers. Full consumer restoration and
whole-image acceptance remain outstanding.

This part changes2 existing core files. sysimes moves from reviewed unchanged
to modified: cumulative modified17, reviewed unchanged39, no new core files.
The two open BIOS SCC members remain open. No publication. Evidence:
../etc/T20-S2-P30.json.

### S2 P31 — integrated floppy geometry restoration

Restored word cylinder storage and BDS writes, extended INT13 AH48 geometry,
change-line handling and PUSHA/POPA preservation. Kept the helper in msinit,
before print_init as located in target. Restored immediate shifts and both
DWORD COMPAQ comparisons. No new core files or alternative implementation.

Original ML/NMAKE plus full BIOS LINK/RELOC and repack pass with inherited
warnings. The395-byte floppy path at file5362 matches in383 bytes; only six
external eot word operands differ (current0DEF,target0DE5). The complete52-byte
helper at file8628 matches, and its call destination now matches as well.
These435 exact bytes are scoped evidence, not a whole-image percentage.
p31check.cmd retains direct FC/B results and full image/map/listing/log in p31.

Current output sizes226732/9/92870. Only MSDOS.SYS is fully exact. Continue
from integrated differences without repeating proven blocks. msinit and BIOS
SCC remain open. This part modifies1 existing core file; cumulative modified17,
reviewed unchanged39; tools modified1. No publication.
Evidence: ../etc/T20-S2-P31.json.

### S2 P32 — complete clock module and floppy binding closure

Integrated-image differences located three outdated BCD shift sequences in
initclk. Restored target immediate shifts and removed the now unnecessary CX
save/restore in bin_to_bcd. No new source file or alternate path. The resulting
nine-byte code reduction also removes a linker alignment byte, moving eot back
ten bytes to target0DE5 without editing any address constant.

Original ML/NMAKE and full BIOS LINK/RELOC pass. Direct FC/B verifies the entire
620-byte initclk module at file11628, including all resolved operands. The
entire395-byte P31 floppy path at file5362 also passes without exclusions.
Its six former external-address differences are closed by provider placement.
This is integrated binary evidence, not a whole-image completion claim.
Reproducible check and image/map/listing/log snapshot: cmd-17081-23949/p32check.cmd
and p32. Unchanged proven blocks were reused; no standalone probe was built.

This part modifies1 existing core file; cumulative modified18, reviewed
unchanged39. Reviewed55 includes16 modified and39 unchanged; the other two
modified files remain open SCC members. No new core files or publication.
Next integrated difference begins in msdisk at its FAT identifiers and disk
paths; preserve the SCC dependency scope. IO.SYS and COMMAND.COM remain open.
Evidence: ../etc/T20-S2-P32.json.

### S2 P33 — FAT32 media identification in existing disk module

Added the target FAT32 identifier to the existing data table and selection in
clear_ids. Restored FAT32 extended boot-record serial/label/system-ID ingestion
in mov_media_ids with PUSHA/POPA preservation, retaining one shared copy path.
Restored readbootsec conditions for F8 media, zero legacy sectors-per-FAT,
extended signature and OEM version recognition. No new core files.

Original ML/NMAKE and complete BIOS LINK/RELOC pass. From complete IO.SYS,
FC/B proves99 bytes of disk data, all57 bytes of clear_ids and all83 bytes of
mov_media_ids. readbootsec matches127 of129 bytes; only the relative call to
read_sector differs because intervening paths still need restoration. Snapshot
and reproducible comparisons are in cmd-17081-23949/p33 and p33check.cmd.

This part modifies1 core file. Cumulative modified19, reviewed unchanged39;
three modified SCC members remain in progress. Next restore GetBP's extended
BPB ingestion and replace its obsolete movbpb path from target evidence. No
whole-module or full-image acceptance, and no publication.
Evidence: ../etc/T20-S2-P33.json.

### S2 P34 — complete extended BPB ingestion path

GetBP now copies all53 BPB bytes, normalizes extended fields for conventional
volumes and preserves interrupt flags around extended-register initialization.
Old diskette reconstruction now writes word geometry and initializes extended
fields. EBX/ESI preservation matches target. Removed the obsolete movbpb
procedure after moving the target ingestion logic into the existing GetBP.
No new core files or duplicate path.

Original ML/NMAKE and full BIOS LINK/RELOC pass. GetBP through readfat occupies
the same618 bytes at file12739 as target. Direct comparisons prove614 bytes;
only the resetchanged and hidensity relative call words differ. Complete
readbootsec129, mov_media_ids83 and readfat15 bytes now match, closing P33's
read_sector call displacement. These ranges overlap P33 evidence and must not
be added as unique global progress. Snapshot and checks: p34/p34check.cmd in
the current integrated build directory. Remaining disk transfer paths and
external providers stay open within the BIOS SCC.

This part modifies1 existing core file; cumulative modified19, reviewed
unchanged39. No new core files, full-image acceptance or publication.
Evidence: ../etc/T20-S2-P34.json.

### S2 P35 — extended IOCTL provider and parameter return

The full2703-byte msdisk comparison localized remaining differences to operand
sites referencing providers; retained its matching transfer instructions. This
is diagnostic localization, not complete msdisk acceptance. Continued within
the same BIOS SCC to msdioctl, whose missing three state bytes displaced
Xfer_Seg and Media_Set_For_Format. Restored those fields, RAWIO32 dispatch,
FAT32 function restrictions and legacy BPB conversion in existing procedures.
GetDeviceParameters now returns31 legacy bytes or53 extended bytes plus32
reserved zero bytes; FAT32 compatibility uses512 root entries and saturates
the legacy FAT size atFFFF. No target address constants or duplicate paths.

Corrected an unavailable TESTB macro use to the module's direct TEST form.
Original ML/NMAKE and complete BIOS LINK/RELOC then pass. All296 bytes from
Do_Generic_IOCtl through GetDeviceParameters at file15024 match directly,
including all calls and data operands. p35check.cmd retains the comparison
and full image/map/listing/log snapshot. Xfer_Seg1874 and format-state1877
now match through ordinary linker placement.

This part modifies1 existing core file; cumulative modified20, reviewed
unchanged39. Four modified SCC members remain open. Next restore the following
SetDeviceParameters and related IOCTL paths. No new core files or publication.
Evidence: ../etc/T20-S2-P35.json.

### S2 P36 — parameter writes and continuous track paths

SetDeviceParameters now selects31 or53 BPB bytes according to request major
code, shares that count across recommended/fake destinations, and selects
the matching track-count and sector-table fields using existing DP/DP32
structure definitions. Restored TrackIo's immediate two-bit shift; its former
one-byte excess caused multiple downstream call displacements. No address
constants were substituted and no core files or second paths were added.

Original ML/NMAKE and full BIOS LINK/RELOC pass. Direct FC/B matches all1344
bytes from Do_Generic_IOCtl18B0 through ResetDisk end1DF0 at file15024. This
includes P35's296 bytes plus1048 bytes of parameter write, format, verify,
track I/O and setup helper code. Reused already matching instructions; this
is not a1344-byte claim of newly written code. No operand exclusions. Snapshot
and reproducible checks: current integrated build p36 and p36check.cmd.

This part modifies1 core file; cumulative modified20, reviewed unchanged39.
Next inspect remaining IOCTL routines beginning at ToRom. Four SCC members
remain open; full IO/CMD identity and publication remain outstanding.
Evidence: ../etc/T20-S2-P36.json.

### S2 P37 — media ID and backup boot I/O

Restored FAT32 serial/label/system-ID offsets in the existing get/set paths.
BootIo now obtains the logical drive from BDS, validates the backup boot sector,
retries reads from backup on error, and handles writes to both copies while
tracking combined error status. Restored RAWIO32 support query and target BIOS
functions45/46 with the55AA extension signature. No new core files or parallel
implementations. Existing helper names retained; comments reflect actual calls.

Original ML/NMAKE and full BIOS LINK/RELOC pass. Whole IOCTL region at file14951
through17189 (exclusive), including preceding alignment byte, compares directly
in2234 of2238 bytes. Only the two relative words for HasChange and Set_Changed_DL
differ; all other code/data and local bindings match. p37check.cmd records
explicit exclusions and retains the full image/map/listing/log in p37. This
supersedes overlapping P35/P36 ranges and is not full module acceptance.
Two comments corrected after build; no instruction change or redundant rebuild.

This part modifies1 core file; cumulative modified20, reviewed unchanged39.
Continue with the unresolved providers in the same BIOS SCC. Full IO.SYS and
COMMAND.COM identity remains open; no assets published.
Evidence: ../etc/T20-S2-P37.json.

### S2 P38 — provider corrections close complete IOCTL comparison

Restored INT13's immediate four-bit DMA segment conversion, eliminating five
instruction bytes and a following alignment byte. In msbio2 check_vid restored
the FAT32 boot signature selection and legacy FAT-sector validation. This
adds the target18 bytes and places HasChange/Set_Changed_DL at their target
addresses. No consumer address constants or alternate paths were introduced.

Original tools and full BIOS LINK/RELOC pass. Direct FC/B now verifies all2238
bytes of the IOCTL region without exclusions; the full618-byte GetBP/boot-reader
chain also matches. The changed DMA/ECC tail397 bytes matches directly. These
overlap earlier evidence and are not additive global percentages. The2703-byte
msdisk region retains only config_init_segment and dskdrvs operand differences.
Do not accept msdisk or the BIOS SCC as complete. Snapshot/check: p38 and
p38check.cmd in the current integrated build directory.

This part changes2 existing core files. Cumulative modified22, reviewed
unchanged39; IOCTL moves to complete-linked-module-verified pending final
integration. Five modified SCC members remain open. No new files/publication.
Evidence: ../etc/T20-S2-P38.json.

### S2 P39 — volume label reader and original assembler selection

Restored DWORD root-sector storage,32-bit FAT-size and sector calculations,
target FAT32 guards and immediate root-entry shift in existing msbio2 paths.
The old MASM5 recipe emits different386 prefix ordering and forward branches;
selected the same original ML recipe already used by adjacent BIOS modules.
Removed only the owned staged msbio2.obj to force that recipe change once.
No binary edits, target-address substitutions or new core files.

Original ML and complete BIOS LINK/RELOC pass. All297 bytes from set_volume_id
at file20092 through check_media_id end20389 match directly, including root_sec,
reader, copy and comparison routines. Snapshot/listing/log and direct FC/B
check are retained under p39 and p39check.cmd. Module-wide integration remains
open. This part changes1 assembly file and1 makefile: cumulative core modified23,
reviewed unchanged39. No full IO/CMD identity or publication claimed.
Evidence: ../etc/T20-S2-P39.json.

### S2 P40 — initialization storage closes complete disk comparison

Changed the existing deviceparameters declaration in stkinit to the existing
a_deviceparameters32 structure. Its additional54 bytes restore linker-derived
BDS1 at038E and DSKDRVS at148E; no hardcoded addresses or new paths were added.
Original tools and complete BIOS LINK/RELOC pass. Direct FC/B verifies the entire
2703-byte msdisk region at file12248 without exclusions. Snapshot and comparison
are retained under p40 and p40check.cmd in the integrated build directory.
stkinit itself remains open; this consumer proof does not accept its whole module.

This part modifies1 core file. Cumulative modified24, reviewed unchanged39;
no new core files. Complete output sizes remain IO227244, MSDOS9, COMMAND92870;
only MSDOS.SYS is fully exact. Continue from complete-image differences and maps,
skipping proven matching regions. No redundant rebuild after metadata updates.
Evidence: ../etc/T20-S2-P40.json.

### S2 P41 — extended BDS compaction and broad code comparison

Complete-image comparison localized the first changed initialization instruction
to BDS compaction: legacy100-byte literals must use the existing150-byte BDS
structure. sysinit1 now includes msbds.inc and uses size bds_struc for both
subtraction and destination advancement; makefile records the dependency.
Original tools and full BIOS LINK/RELOC pass. All67 bytes of the loop at27904
match. No extra implementation, hardcoded target address or binary patch.

Broader direct checks establish12265 bytes at8704 and1205 bytes at20971 exact;
the two intervening bytes remain unresolved. INT13 and following BIOS code
at17189 for2903 bytes also match, overlapping the prefix rather than adding
unique coverage. Do not promote files with other unverified segments.
Evidence and full-image/map/log snapshot: p41check.cmd and p41 in the integrated
build directory; ../etc/T20-S2-P41.json. This part changes2 core files (one
assembly, one makefile); cumulative modified25, reviewed unchanged39. No new
core files or publication. Continue with SYSINIT differences from the linked map.

### S2 P42 — stack transitions and RPL arena marking

Continued from the full linked image: restored the initial stack short jump,
the existing RPL name writes as two DWORD stores, and CLI/jump/STI around the
optional-system execution stack change. locstack is a near code label because
original ML rejects a direct jump to the former byte label. No byte directives,
new implementation or target address constants were used.

Original ML/NMAKE and full BIOS LINK/RELOC pass after resolving that label-type
error. Direct comparisons prove42 bytes of the initial stack/workspace path,
the complete82-byte RPL branch, and the7-byte second stack switch. Existing
external-symbol differences remain open; sysinit1 is not accepted as complete.
Snapshot, listing, map, log and checks are retained in p42/p42check.cmd under the
integrated build. Evidence: ../etc/T20-S2-P42.json. This part modifies1 core file;
cumulative modified25, reviewed unchanged39. No new core files or publication.

### S2 P43 — VDISK address conversion and next boot-volume gap

Restored immediate shifts in ClrVDISKHeader; original tools and full BIOS link
pass. Direct comparisons prove128 bytes of VDISK helper code at30696 and the
complete53-byte compressed-boot record procedure at30894. Retained snapshot,
listing, map and checks: p43/p43check.cmd in the integrated build directory.
Boot-flag references inspected here are layout differences and were not changed.

Next substantive target gap is the existing boot-volume reader and root lookup:
target2250 includes INT13 AH42 for types0C/0E; target2311 includes FAT32 root
traversal. Reconcile the saved BPB provider (boot_copy_buffer in sysinit2) and
its population before accepting dependent reader changes. No new implementation
file is needed. This part changes1 core file; cumulative modified25, reviewed
unchanged39. Evidence: ../etc/T20-S2-P43.json. Full IO/CMD identity remains open.

### S2 P44 — saved boot parameters and extended boot-volume reads

Expanded boot_old_sector from62 to90 bytes, retaining subsequent register fields.
Target capture and old-DOS handoff both copy31h words; restored both counts.
Restored INT13 AH42 in existing boot_read_sector for partition types0C/0E using
a stack DAP; retained CHS fallback and moved its drive reference to offset40h.
Bounds/error helper placement follows the target. No new source file or patching.

Original full link, RELOC and packaging pass. First build returned FAIL at LINK
without a captured error; isolated diagnostic full link and the following formal
build passed without a source workaround. Reader206 bytes have180 direct matches;
the13 differing words all refer to saved buffer48FE versus target4DD2. These
explicit exclusions are not whole-reader acceptance. Capture-copy12 bytes at5061
match directly. Snapshot, listings and reproducible checks: p44/p44check.cmd.
Next restore FAT32 root traversal and compressed-driver lookup within sysinit1.
This part modifies3 core files; cumulative modified26, reviewed unchanged39.
Evidence: ../etc/T20-S2-P44.json. No publication or full IO/CMD identity.

### S2 P45 — FAT32 root traversal and compression-driver lookup

Restored boot_find_file's FAT32 root-cluster loop and target cluster search/FAT
entry helpers in the same module. Preserved the target's separate fixed-root
and cluster-directory loops, including flags at directory end and cluster end.
The target INT3 in active-FAT selection is retained. Compressed-driver lookup
now uses32-bit FAT area arithmetic, directory high cluster words and carry
propagation, with the extended boot-drive field. No new source file or raw-byte
implementation was introduced.

Original ML/NMAKE and complete BIOS LINK/RELOC pass. The348-byte directory/FAT
chain has310 matching bytes; the following262-byte compression lookup including
its filename has244 matching bytes. Every mismatch is one of28 saved-buffer
word operands; all other bytes including branches and local calls match.
p45check.cmd verifies all complementary spans in the full image and retains
image/map/listing/log under p45. Full provider placement remains open.

This part modifies1 core file; cumulative modified26, reviewed unchanged39.
IO image is227756 bytes after alignment, MSDOS9 and COMMAND92870; output size
is not a recovery percentage. Evidence: ../etc/T20-S2-P45.json. No publication.

### S2 P46 — extended device parameters and compatibility fallback

setparms now clears DP32 track count and issues RAWIO32. On failure, only a
nonzero legacy FAT size permits fallback to RAWIO after clearing its track count.
Failure carry is retained; successful EOT update explicitly clears carry. Existing
DP/DP32 fields and IOCTL constants are reused. No new core file or duplicate
implementation. Original tools and complete BIOS LINK/RELOC pass.

Entire106-byte process at built31776/target31775 has100 matching bytes; only three
drive/switch operand words differ. The preceding extra state byte remains open;
do not hide it with padding or accept whole-module identity. p46check.cmd retains
full image/map/listing/log and verifies all complementary spans. Next restore
DRIVPARM options/defaults and BPB calculation using target evidence and existing
provider declarations. This part modifies1 core file; cumulative modified26,
reviewed unchanged39. Evidence: ../etc/T20-S2-P46.json. No publication.

### S2 P47 — DRIVPARM option state and validation

Restored the11-entry ARVFHSTDICN table and reserved-sector, root-entry and cluster
state in si2front before their sysinit1 consumers. Added table-derived form-factor
count, target defaults and validation for numeric options. Numeric errors now
propagate carry through check_switch; legacy unconditional success was removed.
No new core files. BPB application and capacity/FAT calculation are still pending;
parser restoration is not complete DRIVPARM support.

Original tools and complete BIOS LINK/RELOC pass. All12 switch-table bytes match;
numeric validation152 bytes has134 matching bytes, with nine provider word operands
remaining. p47 contains the full-image/map/listing/log snapshot; p47verify.cmd
passes all complementary spans. Initial p47check.cmd failed CMD label lookup after
saving the snapshot; direct-command verifier avoids that test-script issue.
This part modifies2 core files; cumulative modified27, reviewed unchanged39.
Evidence: ../etc/T20-S2-P47.json. No publication or full-image acceptance.

### S2 P48 — complete recommended BPBs and cylinder selection

All five recommended BPB records were still25 bytes although the consumer copies
size A_BPB, now53. Added each record's actual target extended fields, including
FFFF FSInfo/backup sector defaults. This removes reads into the next record.
Restored target cylinder selection: preserve a supplied nonzero value, otherwise
select80 or the applicable40-cylinder default. No synthetic padding or new file.

Original tools and full BIOS LINK/RELOC pass. The entire265-byte table matches
directly at built37772/target38264. The57-byte cylinder/BPB-copy prefix has53
matching bytes with only switches and table address words unresolved. Evidence,
snapshot and checks: ../etc/T20-S2-P48.json and integrated p48/p48check.cmd.
This part modifies2 core files; cumulative modified27, reviewed unchanged39.
BPB option application and the target capacity/FAT/cluster algorithm remain
pending. No full-module acceptance or publication.

### S2 P49 — complete BPB capacity and FAT-size calculation

Restored actual capacity thresholds and explicit-cluster limits in si2front,
then applied the target reserved/root/cluster option logic and32-bit capacity,
FAT-size and allocation-unit arithmetic in existing setdeviceparameters. The
legacy media logic remains only as the target's no-extended-options branch.
All instructions are assembled source; no address patches or new core files.

Original ML/NMAKE and complete BIOS LINK/RELOC pass. Entire setdeviceparameters
676 bytes at built32265/target32266 match, as do all106 setparms bytes at
built31776/target31775 and all126 threshold bytes at38562. No operand exclusions.
This closes P46/P48's provider words at those scopes through natural layout.
The boot-volume chain still references buffer4DCC versus target4DD2; no whole
SYSINIT acceptance. Snapshot/check: p49/p49check.cmd. Output IO228268, MSDOS9,
COMMAND92870; only MSDOS is fully exact. This part modifies2 core files;
cumulative modified27, reviewed unchanged39. Evidence: ../etc/T20-S2-P49.json.

### S2 P50 — final BDS/SFT initialization closes boot-volume chain

Saved-buffer displacement originated in earlier executable code, not missing
data padding. Corrected si1tail's legacy100-byte BDS count and stride with size
bds_struc, restored SFT chain-tail traversal and target immediate shifts. Added
the structure include and make dependency. No arbitrary address or filler bytes.

Original tools and full BIOS LINK/RELOC pass. boot_copy_buffer now lands at4DD2.
Entire816-byte chain at30947 matches directly, closing every P44/P45 operand
exclusion. The21-byte SFT chain append and9-byte paragraph rounding helper also
match. Snapshot/check: p50/p50check.cmd. Other bindings and module scopes remain
open; no full-image acceptance. This part changes2 core files (assembly/makefile);
cumulative modified28, reviewed unchanged39. Evidence: ../etc/T20-S2-P50.json.

### S2 P51 — extended startup drive queries

Complete-image differences identified a63-byte extended Get DPB return buffer
after the safe-boot message, consumed by three AX7302 queries. Restored the
buffer and all three calls together in sysinit2, including register preservation
and the expanded menu conditional branch. No artificial padding or new core file.

Original tools and complete BIOS LINK/RELOC pass. boot_shell_main naturally
aligns at52A6. The entire125-byte Windows-path check and63-byte return buffer
match directly. Menu check198 bytes matches outside seven external address
words; all184 complementary bytes are exact. No whole-module acceptance.
Snapshot/check: p51/p51check.cmd in the integrated build; evidence
../etc/T20-S2-P51.json. This part modifies1 core file; cumulative modified28,
reviewed unchanged39. IO228780, MSDOS9, COMMAND92870; only MSDOS is fully exact.
No publication. Continue from full-image differences, skipping proven regions.

### S2 P52 — shell validation and AUTOEXEC handle lifetime

Restored immediate shifts and target7Ah shell-image check. Complete-image
comparison located a missing16-byte AUTOEXEC handle-close sequence; restored
the error sentinel, successful close and BX preservation within existing shell
preparation. Together these changes naturally align environment preparation5C56
and previous-menu check5E50. No new source files or synthetic padding.

Original tools/full BIOS link pass. Full shell-record rotation72 bytes is exact.
Shell sizing212 bytes retains only two external address words; shell preparation
290 bytes retains only four external address words. All208 and282 complementary
bytes pass direct comparison. Snapshot/check p52/p52check.cmd; evidence
../etc/T20-S2-P52.json. This part modifies1 core file; cumulative modified28,
reviewed unchanged39. IO/CMD identity remains open; no publication.

### S2 P53 — AUTOSCAN option and environment provider alignment

Restored the target AUTOSCAN table entry and existing-file handler, including
numeric validation0..2 and AH52 system-information flag updates at offset60h.
No duplicate parser or new core file. Original tools and full BIOS link pass.
The table, handler and assembler branch expansions naturally align environment
data at669A/669C, closing both P52 shell-sizing operand exclusions.

Full shell-size procedure212 bytes and AUTOSCAN51 bytes now match. Across the
945-byte option parsing region, only four external address words remain;
all937 complementary bytes match. Snapshot/check p53/p53check.cmd; evidence
../etc/T20-S2-P53.json. This part modifies1 core file; cumulative modified28,
reviewed unchanged39. Comments clarified after build without instruction changes.
IO/CMD full identity remains open; no assets published.

### S2 P54 — extended DPB initialization for loaded devices

Full-image differences located the next instruction gap in sysconf's existing
per-unit device initialization. Restore access flag80h, extended BPB version/FAT
validation, temporary legacy FAT-size fallback and EX/AR SetDPB signature, with
register and original BPB restoration. Reuse existing BPB fields and add their
include dependency. Scope .386 to the expanded DEC/JNZ loop tail.

Original tools/full BIOS link pass. Direct checks verify86 bytes at53814 and
the10-byte loop tail at53903. Snapshot/check p54/p54check.cmd; evidence
../etc/T20-S2-P54.json. Whole sysconf remains in progress; exec_mode nowAC97
versus targetACAD. This part modifies2 core files (assembly/makefile), cumulative
modified29, reviewed unchanged39, no new core files. No publication.

### S2 P55 — DRIVPARM dispatch and startup switch application

Restore target DRIVPARM calls and error checks using existing diddleback;
remove obsolete /W flag write but retain the target empty conditional branch.
Restore the immediate shift in SetInt12Mem and scope newer instruction modes
locally, returning to inherited .8086. No new implementation files.

Original tools/full BIOS link pass. Entire65-byte switch application and29-byte
SetInt12Mem match. DRIVPARM33 bytes retains four external call words, each
displaced by one byte; all25 complementary bytes match. Snapshot/check
p55/p55check.cmd; evidence ../etc/T20-S2-P55.json. This part changes1 core file;
cumulative modified29, reviewed unchanged39. Full IO/CMD identity remains open.

### S2 P56 — device size and UMB paragraph conversion

Restored immediate shifts in SizeDevice and the INT12 memory-size conversion,
scoping .286 locally and retaining existing procedures. Full BIOS compilation,
linking and packaging pass. Complete SizeDevice136 bytes and8-byte INT12
conversion match directly with no exclusions. Snapshot/check p56/p56check.cmd;
evidence ../etc/T20-S2-P56.json. This part modifies1 core file; cumulative
modified29, reviewed unchanged39. No new core files, full-image acceptance or
publication. Temporary automatic-review service errors cleared before final build.

### S2 P57 — device recording and drive snapshot

Restore target PUSHA/POPA in existing record-generation and drive-snapshot
procedures, locally scoping .286. Original tools/full BIOS link pass. Entire
contiguous699-byte region from92D7 through9592 matches directly, including
all helper calls and operands; no exclusions. No new source files.
Snapshot/check p57/p57check.cmd; evidence ../etc/T20-S2-P57.json. This part
modifies1 core file; cumulative modified29, reviewed unchanged39. Full IO/CMD
identity remains open; no publication.

### S2 P58 — QEMM detection and contiguous tail comparison

Restore target PUSHA/POPA within existing config_check_qemm, with local .286
scope. Original tools/full BIOS link pass. Direct comparison extends P57's
699-byte match to914 contiguous bytes from92D7 through9669, including hook
handling, QEMM detection and following name data. This overlaps P57 rather
than adding914 unique bytes. Snapshot/check p58/p58check.cmd; evidence
../etc/T20-S2-P58.json. This part modifies1 core file; cumulative modified29,
reviewed unchanged39. Next inspect syspre revision and preload failure path.
No whole-module acceptance or publication.

### S2 P59 — compression preload and extended device parameters

Target revision data distinguishes extended0101h from the retained legacy12
initialization field; preserve ds_vers.inc and use a local extended constant.
Restore failure prompts/keyboard wait and extended DPB setup in the existing
preload loop. Existing BPB structure is reused with an explicit make dependency.

Original tools/full BIOS link pass. Region9669..9B10 (1191 bytes) matches apart
from four message-address words; all1183 complementary bytes are exact. Checks
cover full preload/postload/CDS code, without promoting unresolved bindings.
Snapshot/check p59/p59check.cmd; evidence ../etc/T20-S2-P59.json. This part
modifies2 core files (assembly/makefile); cumulative modified30, reviewed
unchanged39, no new core files. No full-image acceptance or publication.

### S2 P60 — system EXEC FAT32 exchange and configuration buffer

Export existing Allow_Fat32_Bpb without changing emitted bytes. Restore target
DWORD option and eighth system EXEC record, segment binding and returned flag
propagation. Restore immediate shifts in configuration buffer and environment
conversion in existing mblate; no extra implementation file.

Original tools/full BIOS link pass. Contiguous4522 bytes at61872 match directly.
The950-byte EXEC region at66378 retains only two message-table words, four
bytes below target; all946 complementary bytes match. Snapshot/check
p60/p60check.cmd; evidence ../etc/T20-S2-P60.json. This part modifies2 core
files; cumulative modified31, reviewed unchanged39. No publication.

### S2 P61 — compression and EXEC message index correction

Target resource has two leading entries; four literal table offsets in syspre
and mblate still selected earlier entries. Correct the consumers, preserving
resource content and natural linker addresses. Full BIOS build passes.
Direct comparison now proves6647 contiguous bytes at60681 with no exclusions,
joining and overlapping P59/P60 coverage rather than adding separate totals.
Snapshot/check p61/p61check.cmd; evidence ../etc/T20-S2-P61.json. This part
modifies2 core files; cumulative modified31, reviewed unchanged39, new0.
Other consumers and whole-image acceptance remain open; no publication.

### S2 P62 — complete sysinit2 region matches

Correct23 literal message-table references and seven inline indexed-message
arguments against the target resource and full-image differences. Full BIOS
build passes. All6984 bytes from4B52 through669A match directly, including
startup data, shell handling, prior-DOS handling, menu and option parsing.
No operand exclusions. This closes earlier sysinit2 partial comparisons.

Snapshot/check p62/p62check.cmd; evidence ../etc/T20-S2-P62.json. Promote
sysinit2 to locally verified pending full-image integration and skip repeated
block auditing. This part modifies1 core file; total modified31, reviewed
modified20, unchanged39 (reviewed59). No new files or publication.

### S2 P63 — sysconf messages and extended buffer header

Correct seven direct and nine indexed message references. Replace two legacy
20-byte buffer header literals with existing BUFINSIZ24 in device sector-size
validation and buffer clearing; no new structure or parallel implementation.
Original tools/full BIOS link pass. Across12192 bytes at48442, all12180 bytes
outside six external call words match directly. Full sysconf integration remains
open. Snapshot/check p63/p63check.cmd; evidence ../etc/T20-S2-P63.json.
This part modifies1 core file; cumulative modified31, reviewed unchanged39.
No new core files or publication.

### S2 P65 — complete linked initialization and message segments

The full-image diff isolated17 direct message-table offsets,11 indexed message
IDs and3 DRIVPARM initial values. Correct these in sysinit1, si2front and si1tail.
Original-tool BIOS rebuild/link passes. Direct comparison at file22176 for49763
bytes passes with no exclusions: all45456 bytes of SYSINITSEG and4307 bytes of
SYSINITMSG. Promote the three changed modules to locally verified pending final
integration. Evidence ../etc/T20-S2-P65.json; snapshot/check p65/p65check.cmd.
This supersedes overlapping region proofs, not additional unique coverage.
This part modifies3 core files; cumulative modified31; reviewed63 = modified24
+ unchanged39. No new core files or publication. Next locate linked differences
outside the exact initialization/message segments.

### S2 P64 — upstream call bindings and contiguous integration

Restore DRIVPARM rejected-switch cleanup/common return in sysinit1, share the
compression filename terminator with the following zero flag as in the target,
and use the target immediate menu-color shift in si2front. No call-site address
patches or padding. Original-tool BIOS rebuild/link succeeds. Direct comparison
of the linked IO.SYS region at41458 for25870 bytes passes without exclusions.
This closes all six P63 call operands and verifies the complete12192-byte sysconf
region; promote sysconf to locally verified pending final integration. Evidence:
../etc/T20-S2-P64.json and p64check.cmd. Overlapping earlier proof is not added
as unique coverage. This part modifies2 core files; cumulative modified31;
reviewed60 = modified21 + unchanged39. No new core files or publication.

