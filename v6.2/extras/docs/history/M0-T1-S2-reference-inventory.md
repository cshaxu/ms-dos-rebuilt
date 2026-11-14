# M0 T1 S2 reference inventory

The frozen [DOS 6.0 candidate inventory](../etc/reference-source-inventory.json) and separate [ordered progress ledger](../etc/file-review-ledger.json) contain 250 files: BIOS 41, DOS 69, COMMAND 54 and shared includes 86. All are pending; target relevance remains unverified. The [generator](../../tools/reference_inventory.py) was run twice, and the resulting JSON files compared byte for byte. Frozen inventory SHA-256: `2a2d9311d5b2aebf32f113abbfa850c42d99df122fa4cbbc9bbcceb7f572d057`.

The reference BIOS, DOS and COMMAND link lists name 15, 57 and 35 modules, respectively; all have corresponding same-directory assembly files. `bios/msload.asm` is additional. These are reference link lists, not proof of the DOS 6.20 target's link composition. The reference `messages/` directory is absent; recursive includes, generated resources, optional configurations and target-only files remain for M1 dependency analysis. Any additions require explicit ledger reconciliation without renumbering.

No DOS 6.20 source was imported, modified or built. S2 is closed for this bounded reference inventory, not for target source qualification.
