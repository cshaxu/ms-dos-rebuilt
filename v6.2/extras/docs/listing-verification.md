# Historical listing-verification record

The Python listing checker was retired at the owner request in M5/T7.
Its consolidation evidence remains in etc/listing-consolidation-check.json;
interval metadata is archived as etc/pre-cmd-listing-regions.json.
Use build.cmd for current full-output acceptance.

The following content describes the earlier audit only.

# Historical listing verification

Use an explicitly selected MASM listing:

    python -B extras/tools/verify_listing.py cparse PATH/CPARSE.LST

The module choices and frozen target intervals are in
extras/tools/listing-regions.json. This replaces twenty former
verify_MODULE_listing.py scripts. Their names and hashes remain in that table.

The tool reads the listing and frozen COMMAND.COM only. It never assembles,
writes into a scratch stage, or modifies source. Its result records the listing
hash and reports coverage, non-relocation bytes and internal branch checks.
External relocations are excluded; the result is not current-source acceptance.
Use build_three.py for complete current-source and binary verification.

Consolidation was checked against all twenty existing listing fixtures and
negative cases. See docs/etc/listing-consolidation-check.json.
