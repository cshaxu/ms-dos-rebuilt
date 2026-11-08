# Deferred file observations

- File 53 `dos/buf.asm`: inspect the `BuffInHMA` path, where `shr cx,1` follows `popf` before the later carry test. Compare target bytes and DOS 6 behavior; branch reachability and runtime effects are unproven. Reviewed: see [BUF evidence](evidence/file-review-053-buf.json); runtime reachability remains unverified.
