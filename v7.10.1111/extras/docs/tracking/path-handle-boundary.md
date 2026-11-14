# Registry path and handle migration boundary 
 
Current production uses RegValidateKeyHandle, RegOpenPath, RegSearchPath and RegCreatePath. The 1111 target reconstruction identifies a path-validation, handle-validation and unified open/create sequence. The historical Target names are evidence only and must not be linked as a second production implementation. 
 
Current RegValidateKeyHandle uses seven 28h-byte RegRootTable entries and the RegHandleList. The historical target validator uses six predefined pointer slots and key-handle fields at different offsets; it also opens lazy roots through the unified target path. Changing the validator alone would invalidate callers. 
 
Current production callers of RegValidateKeyHandle occur in rapiopen.asm, reginit.asm and regstart.asm. RegOpenPath callers occur in rapiopen.asm and regstart.asm. RegCreatePath is also called directly by regstart.asm. RegPathPart is called by RegOpenPath, RegSearchPath, RegCreatePath and RegFindAlias. 
 
RegRootTable is also read and written by rapiopen.asm, regfind.asm and regstart.asm, and the file and handle objects connect this path to regread.asm and registry lifecycle. Migration must update these producers and consumers together, directly replacing obsolete first-path code and data after the new call chain is integrated. No inference is made that every historical reconstructed instruction has been independently validated in the current build. 
 
No core code changed by this boundary inventory. Existing IO, COMMAND and function-match results remain unchanged.
