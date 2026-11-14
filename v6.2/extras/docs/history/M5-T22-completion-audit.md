# M5 T22 completion audit

T22 S1 is complete. Scope remains the original 225-file fixed DIR-order source
universe; no files were transferred out or silently excluded during execution.

Requirement | Evidence and conclusion
--- | ---
Only original DOS6.0 source reference | references.csv records only v6.0 paths; parts 2-5 explain comparisons. No other-version source or binary comparison used as acceptance.
Fixed DIR order, one file at a time | dir-raw.txt and inventory.csv preserve raw ordinals. Accepted prefixes advanced 31,39,49,221,225; edited files 34,35,45,50 each passed before later acceptance.
Review every source difference | 195 exact-source records plus 26 nonidentical/no-reference dispositions; CURRENT records file10, parts2-5 cover all remaining differing entries. All 225 have terminal dispositions.
Reduce unnecessary differences | Four files restored original source forms: SYSINIT1 call comment, SYSINIT2 fourteen comment/format lines, COPY declaration/convergence label, DIR standalone jump. Existing instruction flow and meaningful 6.20 data remain.
Preserve Microsoft structure/style | Original modules, empty conditionals, macros, tables, comments and source layout retained. New capabilities remain in existing functions/modules; no new source file, wrapper, second path or directory introduced.
Compile each changed file | file34/35/45/50-build-result.txt correspond to separate original-tool builds cmd-2134-27375, cmd-2556-4896, cmd-3212-2638, cmd-3702-9267. Each changed OBJ also directly compared identical to its preceding accepted object.
Keep three outputs byte-identical | Every changed-file build reports three MATCH results. Final direct FC/B compares current assets to frozen same-version targets. final-check.txt checks target, last build and assets hashes.
No source drift after verification | Final native checker validates all 225 current input hashes against the last accepted build source copy, plus frozen entry hashes for every unmodified file. Earlier reference checker revalidated actual DOS6 reference hashes.
Keep source scope and structure | Native enumeration of bios/cmd/dos/inc/lang finds 225 files; each frozen path exists and matches the checked build. No source additions/deletions.
Keep metadata in extras | Admission, inventory, hash/reference evidence and audit parts are under extras/docs. Build output remains under ignored extras/build; assets stay at extras/assets.
Report honest counts | 4 modified, 195 exact DOS6, 22 necessary differences retained, 4 missing same-name reference retained. The last group is explicitly not source identity.

Limit: This is an audit against the available DOS6 source and exact DOS6.20
targets, not proof that reconstructed symbol names/comments are Microsoft's
unavailable original DOS6.20 source. Four language inputs lack same-name DOS6
references; their original-format interfaces and target output are verified.
No outstanding file or verification task remains in T22.
