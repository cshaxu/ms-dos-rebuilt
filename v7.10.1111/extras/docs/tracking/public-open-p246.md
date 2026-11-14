# Registry public open entry, P246 
 
Removed the RegVMOpenKey forwarding branch from the original RegOpenKey entry. The recorded 1111 target entry proceeds directly to the registry open chain. The existing 950-derived open implementation remains in place and no second implementation was added. Other VM services and their callers were not changed. 
 
MASM and complete IO relink passed; IO is 233732 bytes versus target 214836. The 186880-byte IO prefix, 557-byte DOS service group, two name functions, checksum and data header comparisons passed. Link binding checks for value, alias, mount, search, create, hash and preparation passed after updating source-listing offsets. The isolated query-chain test passed with controlled stubs. The modified RegOpenKey body has not been proven byte-identical to its target and no integrated open behavior test was performed. 
 
Function tracking remains 461 exact entries. One core source changed this step; current 950 comparison inventory remains 95 different and 198 identical.
