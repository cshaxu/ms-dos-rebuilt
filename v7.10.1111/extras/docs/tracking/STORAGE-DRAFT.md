# Unapplied storage migration diff

This is an implementation working draft, not production source, not a build
input and not evidence of restored functions. Do not apply it wholesale.

registry-storage-draft.patch replaces bodies of 13 corresponding original
regread.asm procedures under their existing names. Verified validators and
checksum bodies are retained. The draft mechanically translates target
correspondence names; its purpose is to expose the complete changed contracts
and subsequent edits in one reviewable diff rather than add parallel routines.

The raw body substitution is still too broad: 1256 inserted / 2547 deleted
lines. Existing comments outside replaced procedures are not yet updated.
No production source or binary changed. This is not an accepted minimal-diff
solution and is not authorized to bypass the owner's source-fidelity goal.

Before integration:

* Reconcile reusable original instruction/control-flow portions, preserving
  original comments and organization where their semantics still apply.
* Complete shared file/cache representation and active-reference ownership
  for all producers and consumers (REGISTRY-ABI.md).
* Migrate corresponding callers and calling conventions as a group; FAR to
  NEAR stack offsets/cleanup cannot be patched at just the callee.
* Resolve newly factored target dependencies through existing source domains;
  remove superseded original routines when their consumers are switched.
* Reconcile segment placement and original-tool object recipes, assemble and
  fully link, then compare the target-corresponding complete region.

The current exact-function count remains 461 and IO remains 233548 bytes.
Production core changed: 0; newly certified identical files/functions: 0.
