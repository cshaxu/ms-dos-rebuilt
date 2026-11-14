# Registry open and close entry tests 
 
Run from an existing populated build stage with its runner, DOSBox configuration and historical tools. Compile openapi_extract.c using gcc, then use it to extract RegOpenKey or RegCloseKey from the production bios/rapiopen.asm into the stage bios directory, combining the respective prefix and suffix templates. Copy the matching .bat and .cmd files to the stage root and run the .cmd. 
 
Example arguments to the extractor: production-rapiopen.asm openapi_prefix.asm openapi_suffix.asm stage-bios-openapi.asm RegOpenKey. Use closeapi templates, closeapi.asm and RegCloseKey for close. 
 
Both tests run the real extracted function with controlled storage and handle stubs and a nonzero RegVMEntry. Open covers invalid handle, failed path, allocation failure, success and stack balance. Close covers invalid handle, save, protected handle, destruction and stack balance. They do not exercise real registry storage or prove target-byte identity.
