# T20 S2 Registry Lifecycle Map

Current configuration callers: cfgmain calls RegInitialize, RegOpenKey, RegQueryValueEx, RegCloseKey and RegTerminate. cfgmenu also calls open, query and close; cfgline calls query.

Legacy public providers: regstart.asm provides RegInitialize and RegTerminate; rapiopen.asm provides RegOpenKey and RegCloseKey; rqvalue.asm provides RegQueryValueEx. These remain active and cannot yet be deleted.

Legacy initialization in regstart calls RegFileCreate, RegRecoverFile, RegReadFile and root initialization; release paths call RegReleaseFileBuffers, RegFileUnlink, ConfigFree and RegReleaseMounts. Save flows call RegSaveFile. Existing providers are still FAR interfaces.

Target-side staged NEAR providers: RegInitKeyCache and RegInitDataCache initialize caches; RegFetchKeyRecord, RegFetchDataRecord and corresponding unlock routines provide reads; RegAllocateKeyRecord and RegCompactDataCache provide allocation prerequisites; RegSaveFileState writes a changed file. Their complete procedure comparisons are recorded through P164. These are not yet connected to the legacy FAR lifecycle.

Required transition: establish target file-object initialization and teardown, path open and handle validation, then replace public API consumers together with cfgmain, cfgline and cfgmenu bindings. Only then remove corresponding unreferenced FAR implementations and root records. Exact target entrypoint and calling conventions must be resolved from the linked target before editing callers.

Open: data record allocation, file creation/open and lifecycle, target path open and value query, target public entry interfaces. No legacy removal is certified by this map.
