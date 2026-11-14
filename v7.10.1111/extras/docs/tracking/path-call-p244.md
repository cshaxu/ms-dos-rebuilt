# Path call alignment, P244 
 
RegCreatePath now calls the existing same-segment RegSearchPath using push cs and a near call. Both routines retain their FAR interfaces, and their argument and return contracts are unchanged. No parallel implementation was added. 
 
The affected module assembled and the complete IO linked successfully. The isolated actual RegCreatePath test passed with controlled storage stubs. Link checkers verified both callers and the adjusted call target; the 186880-byte prefix, 557-byte registry DOS service group, RegNameChecksum and RegCompareName still matched their target regions. 
 
IO.SYS is 233766 bytes, target 214836; complete identity has not been achieved. The exact whole-function count remains 461, including two separately verified CONFIG entries in the symbol inventory. This change does not establish that RegCreatePath is target-exact. One core file changed this step; against 950 the existing inventory is 95 different and 198 identical.
