# M6 T25 S1 P54: files 148-150

148. dos/create.asm -- accepted_necessary. The entire difference retains the
CDS segment until CheckCDSDrive has examined it, preserving DI, then redirects
unavailable local-drive requests through the existing network-create path.
misc2.asm checks the CDS segment and per-drive state, returns Z for availability
and preserves general registers. No duplicate create implementation is added.
Keep this required caller adaptation without edits.

149. dos/crit.asm -- accepted_modified. Full effective-reference diff reviewed.
Remove unused User_In_AX and CurrentPDB externals. Remove the obsolete claim
that handlers begin with a patchable RET: the accepted entries begin PUSHF.
Restore inherited procedure declarations, individual exports, alias-label forms
and instruction columns. Preserve shared disk/device nesting paths, callback,
console bypass, leave-all behavior, AX/flags saves and all instruction operands.
Do not replace the required local-state path with the old interrupt-only path
or merge the target's distinct entry sequences into a different binary layout.

Original NMAKE/MASM/LINK rebuilds the affected kernel byte-identical. Fresh
IO.SYS repack matches its frozen target. Both unaffected inherited outputs are
also exact; all 293 source inputs match the stage. Evidence: file149-build.txt,
file149-make.txt; extras/build/t25-crit-27983-31332.

150. dos/delete.asm -- accepted_necessary. Full diff adds IoState1-based LFN
entry cleanup, routes invalid first-cluster cases through that same cleanup,
uses the shared DeferredFlush policy, and removes the unused Del_ExtCluster
declaration. LfnDeleteEntries consumes the saved directory chain and restores
search state; the existing deletion path remains shared. Required changes are
already in inherited source form. No edit or redundant compilation. This is
internal directory-chain review, not a claim of complete XP LFN API validation.

Prefix 150/293: modified 74, exact 21, necessary unchanged 19, no same-name
reference unchanged 36. Separate modified tool one. Next: 151 dos/dev.asm.
Final full build and completion audit remain pending.
