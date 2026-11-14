# M6 T25 S1 P31: file 122

122. stub.asm -- accepted_necessary. Reviewed the complete effective-v6.22
diff and all added code in context. Existing common interrupt entry stubs,
XMM enabling, UMB restoration and stack handling retain reference structure.

The two relocation entry offsets share RelocateBody rather than maintaining
two source implementations. Their emitted copies, initial version byte and
extra trailer zero are part of the accepted target layout. BadMem_Trap uses
the same A20/DS/CS dispatch as inherited traps and is called by RDATA; RUCODE
exposes ReleaseInit_Entry for initialization ownership. Preserve these entries.

QueryA20 first checks low/high alias addresses and only calls the inherited
XMM query when necessary. Removing this target-specific check changes behavior.
Issue_Exec_Call initializes SumHigh once before EXEC, matching INIT's reset and
COMMAND2's later comparison. The added checksum routine shares its word loop
across two resource spans. COMMAND2 has a similar checksum calculation, but
different segment placement and preservation contracts: its block routine
loads/restores DS itself, whereas the stub wrapper preserves AX/CX/SI/DS and
its block uses the established DS. Merging would change call encodings and
target layout; retain both target implementations, without inventing a wrapper.

No source edit. Accepted source hash remains the frozen inventory hash;
no redundant build. Latest verified stage remains t25-rucode-13899-32129.
Prefix 122/293: modified 52, exact 21, necessary unchanged 13, no same-name
reference unchanged 36. Separate tool modification one. Next: 123 tbatch.asm.
Final full automatic build remains pending. P31 is delivered separately.
