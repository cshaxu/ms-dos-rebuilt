# Supporting evidence index

- [IO.SYS preliminary reference investigation](io-reference-investigation.md): hash-verified target fixture, three link inventories, NTIO reference build and bounded MSLOAD target correspondence; full IO.SYS recovery remains open.

- [M0 T1 S1 baseline](evidence/m0-t1-s1-baseline.md) and [reference manifest](evidence/m0-t1-reference-manifest.tsv): owner M0 T1; identifies inspected target and scoped reference inputs. Retain as the frozen comparison baseline; supersede only with an explicitly reasoned new inventory, preserving the old baseline.

- [M1 T2 build investigation](evidence/m1-t2-build-investigation.md): owner M1 T2; include graph and tool candidates, retained until replaced by a verified build baseline.

- [T3 TFOR call constraints](evidence/m2-t3-tfor-call-constraints.json): owner T3; 13 inferred code destinations, repeated references agree; retain until corroborated or superseded.

- [T3 command entry reconstruction](evidence/m2-t3-command-entry.md): owner T3; source edits, clean build and bounded target instruction comparison.

- [T3 resident prefix recovery](evidence/m2-t3-resident-layout.md): owner T3; exact CheckA20 bytes and reconstructed data-address constraints.

- [T3 startup recovery](evidence/m2-t3-startup.md): owner T3; startup source changes and bounded target-byte comparison.

- [T3 AUTOEXEC recovery](evidence/m2-t3-autoexec.md): owner T3; local batch paths, filename storage and explicit remaining branch differences.

- [T3 environment and startup tail](evidence/m2-t3-environment.md): owner T3; local environment copying, resolved AUTOEXEC branch differences and permanent EXIT recycling.

- [T3 resident buffer and prefix](evidence/m2-t3-resident-buffer.md): owner T3; target-corroborated buffer capacity and complete prefix mismatch inventory.

- [T3 complete INIT code layout](evidence/m2-t3-init-module.md): owner T3; corrected banner location, removed NT /Z and unused wrappers, complete module layout comparison.

- [T3 executable-path recovery](evidence/m2-t3-execpath.md): owner T3; DOS path search, capacity, and removal of NT transient communication fields.

- [T3 initialization messages](evidence/m2-t3-messages.md): owner T3; exact message bytes, aligned transient entry and pre-transient mismatch inventory.

- [T3 PATH display and scan limit](evidence/m2-t3-path-display.md): owner T3; restored PATH copy logic and shared scan limit, nine-module layout comparison.

- [T3 EXEC copy and PATH construction](evidence/m2-t3-exec-copy.md): owner T3; fixed resident pathname copy, removed target-absent bypass and 21-module layout comparison.

- [T3 COMMAND.COM full identity](evidence/m2-t3-command-identity.md): authoritative current COMMAND result; two clean builds, direct whole-file equality and source snapshots. Supersedes earlier partial identity findings for this source state.

- [T4 SoftPC preparation and first run](evidence/m3-t4-softpc-preparation.md): owned test medium and process, explicit fixture/padding limits; first run timed out without guest output, runtime acceptance pending.

- [T4 headless core probe](evidence/m3-t4-headless-probe.md): guest text memory and FAT artifacts confirm shell smoke; separate from supplied-product verification.

- [T4 supplied product result](evidence/m3-t4-product-runtime.json): isolated-desktop product run, owned console start, guest file checks and immutable-input hashes. [Closure audit](../history/M3-T4-completion-audit.md) owns the final T4 disposition.

- [T5 kernel baseline](evidence/m4-t5-kernel-baseline.md): pinned link-unit inventory and successful native assembly of all 38 OpenNT kernel units; linking and target recovery pending.

- [T5 kernel recovery](evidence/m4-t5-init-recovery.md): incremental reconstruction, source origins and remaining FAT/ABI gaps. [Get-DPB and buffer verification](evidence/m4-t5-fat-chain-verification.json) records eight exact routine slices and six static target call edges; [current FAT name ledger](evidence/m4-t5-fat-current-resolution.json) records remaining missing symbols.

- [T5 full BUF candidate](evidence/m4-t5-full-buf-verification.json): complete 644-byte candidate matches at target layout with explicit OMF relocations; external disk routines remain address-only and production integration is pending.

- T5 disk candidates: [read wrapper](evidence/m4-t5-disk-read-verification.json) and [physical I/O/error wrappers](evidence/m4-t5-disk2-io-verification.json) match at target layout, with the ReadOp data-address disagreement explicitly recorded. Production integration remains pending.

- [T5 CDS/HardErr production repair](evidence/m4-t5-cds-harderr-verification.json): corrected data layout, exact 98-byte linked error prefix, unchanged COMMAND inputs. Current disk candidate reports no longer require a ReadOp address override; full integration remains pending.

- [T5 linked storage slices](evidence/m4-t5-linked-storage-verification.json): full BUF, disk wrappers, device/cache tail and critical sections integrated; 1561 bytes checked with 12 explicit call relocations. [FAT name resolution](evidence/m4-t5-fat-linked-resolution.json) now resolves 37/37; FAT integration and runtime acceptance remain pending.

- [T5 FAT/Get-DPB integration](evidence/m4-t5-fat-getdpb-verification.json): FAT and physical Get-DPB are linked; 2593 bytes and 35 call edges checked. [FAT target-layout proof](evidence/m4-t5-fat-verification.json) covers the complete 984-byte module. CDS initialization and runtime acceptance remain pending.

- [T5 CDS lookup recovery](evidence/m4-t5-cds-path-verification.json): real FIND_DPB/InitCDS/GetCDSFromDrv integrated; 2814-byte regression with 36 named calls. Startup still obtains DPBs through an NT service; that construction and runtime remain pending.

- [T5 physical startup DPB construction](evidence/m4-t5-dpb-init-verification.json): replaced the DPB-list host service with block-device/BPB initialization; 3000-byte integrated regression and 39 named calls pass. Complete startup/runtime acceptance remains pending.

- [T5 direct SETDPB restoration](evidence/m4-t5-setdpb-verification.json): removed NT SCS dispatch; verified the full conversion body and word3, extending integrated regression to 3202 bytes. Whole-kernel identity and runtime remain pending.

- [T5 segment reinitialization](evidence/m4-t5-segreinit-verification.json): native CPU detection and no NT symbol callback; full 137-byte procedure checked with explicit symbol operands. Data-layout differences remain recorded. [Storage regression](evidence/m4-t5-segreinit-storage-regression.json) passes.

- [T5 DOS segment patch restoration](evidence/m4-t5-patchmisc-verification.json): removed the 30-byte WOW block; full 81-byte patch procedure is byte-identical. Segment reinitialization still has explicit data-layout differences. [Storage regression](evidence/m4-t5-patchmisc-storage-regression.json) passes for 3202 bytes and 39 named calls.

- [T5 current-directory dependency audit](evidence/m4-t5-currentdir-dependency-audit.json): identifies disabled GetPath as the next integration dependency; formal inputs restored. [ValidateCDS candidate](evidence/m4-t5-validatecds-verification.json) matches 190 bytes at target layout, without integration/runtime claims.

- [T5 GetPath dependency audit](evidence/m4-t5-getpath-closure-audit.json): [GetPath and helpers](evidence/m4-t5-getpath-verification.json), 858 bytes, and [FastOpen paths](evidence/m4-t5-fastpath-verification.json), 296 bytes, are exact target-layout candidates. Physical directory-search/disk dependencies remain for integration.

- [T5 directory integration audit](evidence/m4-t5-directory-integration-audit.json): physical directory search/read and FIGREC/StartSrch now linked. [Integrated verification](evidence/m4-t5-directory-verification.json) and [initialization regression](evidence/m4-t5-directory-segreinit-regression.json) pass. Candidate proofs: [dir](evidence/m4-t5-dir-verification.json), [DirRead](evidence/m4-t5-dirread-verification.json), [FIGREC](evidence/m4-t5-figrec-verification.json).

- [T5 time and GetPath integration](evidence/m4-t5-time-getpath-integration-audit.json): full time module and retained physical GetPath/FastOpen now linked. [Integrated verification](evidence/m4-t5-time-getpath-verification.json), [initialization regression](evidence/m4-t5-time-getpath-segreinit-regression.json), and [time target-layout proof](evidence/m4-t5-time-verification.json) pass; CurrentValidate/ValidateCDS remain to connect.

- [T5 current-directory chain integration](evidence/m4-t5-currentdir-linked-audit.json): $CURRENT_DIR/ValidateCDS/DOS_CHDIR now call restored physical code. [Linked verification](evidence/m4-t5-currentdir-linked-verification.json) records the shared error jump encoding difference explicitly; [initialization regression](evidence/m4-t5-currentdir-linked-segreinit-regression.json) passes.

- [T5 device-path integration](evidence/m4-t5-devicepath-integration-audit.json): restored device parser and caller ABI; [linked verification](evidence/m4-t5-devicepath-verification.json) and [initialization regression](evidence/m4-t5-devicepath-segreinit-regression.json) pass. Subsequent Microsoft-style formatting preserves binary and map exactly.

- [T5 physical CHDIR integration](evidence/m4-t5-chdir-integration-audit.json): replaces NT set-directory service, restores CDS updates. [Linked verification](evidence/m4-t5-chdir-verification.json) explicitly checks shared error/success jump chains and records layout differences; [initialization regression](evidence/m4-t5-chdir-segreinit-regression.json) passes.

- [T5 full dircall dependency audit](evidence/m4-t5-dircall-closure-audit.json): [complete 521-byte candidate](evidence/m4-t5-dircall-verification.json) matches target layout and restores shared near-jump encoding naturally. Six missing helper symbols and physical SFT support remain before integration.

- [T5 RELEASE integration](evidence/m4-t5-release-integration-audit.json): target-specific return behavior restored without DOS 6 flush tail. [Candidate proof](evidence/m4-t5-release-verification.json), [actual-link regression](evidence/m4-t5-release-linked-verification.json), and [initialization regression](evidence/m4-t5-release-segreinit-regression.json) pass.

- [T5 full node-maker audit](evidence/m4-t5-mknode-closure-audit.json): [941-byte full module proof](evidence/m4-t5-mknode-verification.json) covers node creation and SFT population at target layout; four helper symbols and physical SFT migration remain before production integration.

- [T5 allocation/FastOpen audit](evidence/m4-t5-allocate-fastopen-audit.json): [179-byte allocation candidate](evidence/m4-t5-allocate-verification.json) matches DOS 5 without MAGICDRV; [62-byte FastOpen candidate](evidence/m4-t5-fastopen-verification.json) is now linked with [regression proof](evidence/m4-t5-fastopen-linked-verification.json).

- T5 sharing and physical SFT transition: [82-byte sharing candidate](evidence/m4-t5-share-verification.json), [15-byte creation-error mapping](evidence/m4-t5-create-error-verification.json), and [native-layout/NT-user inventory](evidence/m4-t5-sft-transition-audit.json). Integration awaits coherent field and host-path restoration.

- [T5 physical device open/close integration](evidence/m4-t5-openclose-integration-audit.json): restores SHARE-gated DPB driver dispatch; [129-byte candidate](evidence/m4-t5-dev-openclose-verification.json), [linked regression](evidence/m4-t5-openclose-linked-verification.json), and [initialization regression](evidence/m4-t5-openclose-segreinit-regression.json) pass.

- [T5 IOFUNC candidate](evidence/m4-t5-dev-iofunc-verification.json): complete 360-byte process/table match. [Integration dependency audit](evidence/m4-t5-iofunc-transition-audit.json) proves active NT command-6 caller and missing physical file-transfer entries; no production ABI change yet.

- [T5 complete disk/disk2 dependency audit](evidence/m4-t5-disk-full-closure-audit.json): [1206-byte disk proof](evidence/m4-t5-disk-full-verification.json) records comparison-only IsWin386 placement; [737-byte disk2 proof](evidence/m4-t5-disk2-full-verification.json) covers physical file read and SFT updates. Both await coherent production integration.

- T5 complete write/cluster modules: [810-byte disk3 proof](evidence/m4-t5-disk3-full-verification.json), [704-byte rom proof](evidence/m4-t5-rom-full-verification.json), and [12-candidate named-code graph](evidence/m4-t5-storage-closure-audit.json). Three code providers remain absent; data ABI and runtime are not covered by graph closure.

- [T5 full locking integration](evidence/m4-t5-lock-integration-audit.json): [178-byte lock candidate](evidence/m4-t5-lock-full-verification.json), [linked regression](evidence/m4-t5-lock-linked-verification.json), and [initialization regression](evidence/m4-t5-lock-segreinit-regression.json). [428-byte close/commit candidate](evidence/m4-t5-close-full-verification.json) awaits SFT migration; [updated named-code graph](evidence/m4-t5-storage-closure-audit.json) has no absent providers.

- [T5 physical SFT assembly probe](evidence/m4-t5-physical-sft-probe.json): 51 native modules assemble in owned scratch with explicitly unverified comparative user overlays. [OMF symbol audit](evidence/m4-t5-physical-sft-symbol-audit.json) records duplicate CHECK_VIRT_OPEN and remaining pathname imports; not a linked/runtime result.

- [T5 pathname/storage expansion](evidence/m4-t5-pathname-storage-audit.json): complete finfo (260 bytes), delete (480 bytes) and rename (573 bytes) candidates match target layout; expanded 53-module physical-SFT probe assembles, with new create/search dependencies explicitly open.

- T5 complete [create](evidence/m4-t5-create-full-verification.json), [open](evidence/m4-t5-open-full-verification.json), and [internal search](evidence/m4-t5-isearch-full-verification.json) candidates match target layout. [54-module physical-SFT link probe](evidence/m4-t5-physical-sft-link-probe.json) passes in private desktop; not yet a stripped/accepted MSDOS.SYS or runtime result.

- T5 physical SFT consumer/startup proofs: [109-byte abort](evidence/m4-t5-abort-full-verification.json), [51-byte console SFT initializer](evidence/m4-t5-init-sft-verification.json), and [actual probe EXE verification](evidence/m4-t5-sft-init-abort-linked-verification.json). Four other comparative SFT users remain unverified.

- T5 [640-byte handle candidate](evidence/m4-t5-handle-full-verification.json) and [complete actual-link proof](evidence/m4-t5-handle-full-probe-linked-verification.json): restores file-time critical calls, checks 48 named relocations, records IsWin386 layout difference. SFT startup/abort regression passes on the updated probe.

- T5 complete pathname consumer: [969-byte file candidate](evidence/m4-t5-file-full-verification.json) and [actual-link proof with 119 fixups](evidence/m4-t5-file-full-probe-linked-verification.json). Restores allocation critical calls; remaining comparative SFT consumers are the two FCB modules.

- T5 complete FCB consumers: [FCBIO candidate](evidence/m4-t5-fcbio-full-verification.json) and [FCBIO2 candidate](evidence/m4-t5-fcbio2-full-verification.json); actual linked proofs for [1224-byte FCBIO, 95 fixups](evidence/m4-t5-fcbio-full-probe-linked-verification.json) and [778-byte FCBIO2, 49 fixups](evidence/m4-t5-fcbio2-full-probe-linked-verification.json). Zero remaining differences after named relocation adjustment; LocalSFT placement remains unresolved in production. Current named-code graph has 23 candidates/284 edges, no absent provider.

- T5 [DOSTAB layout proof](evidence/m4-t5-dostab-layout-verification.json): restores the 34-byte EXEC allocation and verifies 127 initialized bytes at target offsets, including IsWin386/LocalSFT. Records the NT 62-byte extended-header read that must be restored before integration; data-only native assembly, no runtime acceptance.

- T5 [EXEC header/read-chain proof](evidence/m4-t5-exec-header-verification.json): 54-byte header/classification and 71-byte read/ownership chain match target with 17 named fixups. Confirms 26-byte read ends at restored Win386_Info boundary; full comparative MSPROC candidate remains unverified and unpromoted.

- T5 [complete MSPROC candidate](evidence/m4-t5-msproc-full-verification.json): 1736 bytes/156 OMF fixups match target under [pinned symbol attributions](evidence/m4-t5-msproc-target-bindings.json). Removes DOS 6-only Rational patch call and restores DOS 5/NTDOS COM memory threshold. Nineteen production data placements remain different; actual integration/runtime are pending.

- T5 [actual linked EXEC/DOSTAB integration](evidence/m4-t5-exec-layout-probe-linked-verification.json): complete 1736-byte MSPROC correspondence and raw-exact 127-byte DOSTAB tail; 54-module isolated link passes. FCB/handle/file/startup regressions pass; three A20/HMA/patch data-address differences remain.

- T5 [physical LMSTUB actual-link proof](evidence/m4-t5-lmstub-probe-linked-verification.json): 416 raw-exact bytes at DOSDATA 108Ah–122Ah, with native A20/interrupt paths and restored old Windows instance table. All 19 MSPROC data-placement differences are now resolved in the probe; whole-kernel/runtime acceptance remains open.

- T5 [finite actual-link storage suite](evidence/m4-t5-physical-storage-linked-suite.json): all 23 declared units pass, covering 12800 unique bytes and 1381 named fixups. Twenty complete modules plus three DEV slices; excludes other kernel code and runtime.

- T5 [SEARCH candidate](evidence/m4-t5-search-full-verification.json) and [actual-link proof](evidence/m4-t5-search-full-probe-linked-verification.json): 465 bytes/68 fixups pass. Storage suite expands to 24 units/13265 bytes/1449 fixups. [Current emitted BOP audit](evidence/m4-t5-probe-host-calls.json) records 16 sites, down from [20 before SEARCH](evidence/m4-t5-host-calls-before-search.json); not a complete host-dependency or runtime audit.

- T5 [PATH candidate](evidence/m4-t5-path-full-verification.json) and [actual-link proof](evidence/m4-t5-path-full-probe-linked-verification.json): 366 bytes/43 fixups pass; MKDIR/RMDIR now use physical directory paths. Storage suite: 25 units/13631 bytes/1492 fixups; current emitted BOP count is 14.

- T5 [IOCTL candidate](evidence/m4-t5-ioctl-full-verification.json) and [actual-link proof](evidence/m4-t5-ioctl-full-probe-linked-verification.json): 735 bytes including dispatch table, 103 fixups pass. Storage suite expands to 26 units/14366 bytes/1595 fixups; emitted BOP count decreases to 12.

- M5 [single-config multi-pass dispatch proof](evidence/m5-bios-multipass-verification.json): 170 linked bytes and eight named relative-address fixups match the target; checks are limited to the dispatch slice and do not establish runtime behavior.

- M5 [DEVICEHIGH and DEVICE prelude proof](evidence/m5-bios-devicehigh-verification.json): three linked intervals cover 253 bytes with named address checks; later device initialization and runtime are outside this proof.

- M5 [device initialization and DPB proof](evidence/m5-bios-devicehigh-verification.json): target [63D1h,6633h) covers 610 linked bytes with named fixups; no claim for called routine bodies or runtime.

- M5 [UMB allocation and device marking proof](evidence/m5-bios-devicehigh-verification.json): 259 linked bytes and 24 named address checks; `ShrinkUMB` and runtime are outside this interval.

- M5 [absolute BIOS layout proof](evidence/m5-bios-absolute-layout-verification.json): 224 bytes across the checksum error path and parser tables match at target positions with no address normalization.

- M5 [expanded absolute BIOS proof](evidence/m5-bios-absolute-layout-verification.json): eight target-position intervals total 868 raw-equal bytes, including 416 consecutive bytes of device memory and load preparation.

- M5 [CONFIG.SYS table and DRIVPARM proof](evidence/m5-bios-config-table-verification.json): 145-byte displaced raw-equal table and 87-byte helpers with eight named data-address checks. [Absolute proof](evidence/m5-bios-absolute-layout-verification.json) covers 1411 bytes.

- M5 [complete IO.SYS combination proof](evidence/m5-io-combined-verification.json): existing source-built MSLOAD and BIOS components concatenate byte-for-byte to the pinned 33430-byte IO.SYS extract; fresh integrated build, original-image and runtime verification remain open.

- M6 [existing three-file candidate](evidence/m6-three-file-existing-candidate.json): all three existing source-build outputs directly match both retained FAT12 copies; this is not an integrated build, original-media revalidation, boot or deployment.

- M5 [local BIOS source audit](evidence/m5-bios-local-source-audit.json): 15 link modules and 44 statically discovered includes checked against retained inputs. SYSIMES and MSEND differ in source but have matching literal active statements; no fresh build or complete dependency-closure claim.

- M5 [local build input evidence](evidence/m5-bios-local-build-inputs.json): local link list, skeleton and message sources match the prior exact BIOS build; `--local-source` recipes are statically checked but unexecuted.

- M6 [fresh integrated source audit](evidence/m6-fresh-integrated-source-audit.json): owner-approved private-desktop build; all three files match pinned retained media and 104 objects match prior builds.

- M6 [three-file headless runtime](evidence/m6-integrated-headless-runtime.json): disposable media passed DOS version, environment, shell and file smoke checks; supplied product probe did not start and remains a separate obligation.

- M6 [Get-DPB and FAT probe](evidence/m6-dpbfat-headless-runtime.json): headless SoftPC core verified valid/default/invalid Get-DPB calls and guest plus host checks of a four-cluster file. Not full FAT coverage or supplied-product acceptance.

- M6 [source package candidate](evidence/m6-source-package-candidate.json): 330 source/build inputs match the fresh build; target binaries and tool executables excluded, rights review remains open.

- M6 [local source archive](evidence/m6-source-archive.json): 330 source/build inputs plus manifest and README, all verified against the snapshot; no target or tool binaries.

- M6 [archive input equivalence](evidence/m6-archive-input-equivalence.json): extracted inputs equal those of the earlier successful build and preflight passes; a separate archive rebuild was rejected by automatic approval review and did not run.

- M6 exact-object BOP signature audits: [kernel](evidence/m4-t5-exact-kernel-bop-audit.json), [BIOS/MSLOAD](evidence/m5-bios-exact-bop-audit.json), [COMMAND](evidence/m3-command-exact-bop-audit.json). No `C4 C4` matches in emitted record data; other host interfaces and fixup effects remain outside the audit.

- M3 [COMMAND local source audit](evidence/m3-command-local-source-audit.json): 34 linked module sources match the retained exact build except the [documented comment-only style edits](command-style-adjustment.md); four assets are identical. The fresh build matches all prior object hashes; not all historical shared includes are verified.

- M5 [BIOS message-source verification](evidence/m5-bios-message-source-verification.json): 15 NTIO-referenced source messages produce the same 472 bytes as the linked target interval; no target bytes are used as build input.

- M5 NTIO source recovery: [SYSIMES](evidence/m6-sysimes-nt-correspondence.json) and [MSEND](evidence/m6-msend-nt-recovery.json) have matching active statements and fresh object hashes against retained BIOS builds.

- M6 fresh build [headless runtime](evidence/m6-fresh-integrated-headless-runtime.json), [deployment](evidence/m6-fresh-deployment.json), and [supplied-product attempt](evidence/m6-fresh-integrated-product-attempt.json). The product attempt exited before launch; original-image revalidation remains open.

- M6 [thread-desktop product attempt](evidence/m6-fresh-product-thread-attempt.json): the child's desktop name could not be verified, so it was terminated while suspended. No product boot occurred.

- M6 [canary-assisted product attempt](evidence/m6-fresh-product-canary-attempt.json): a benign child confirmed the private desktop, but the product thread's desktop could not be queried externally; the owned job was terminated before console input or guest boot.

- M6 [console-check product attempt](evidence/m6-fresh-product-console-attempt.json): the private-desktop canary passed, but the product exited with code 1 before console verification; no input was sent and the guest image is unchanged.

- M6 [headless composition diagnostic](evidence/m6-softpc-compose-split-probe-result.json): current local SoftPC objects create/destroy the machine but audio initialization returns IO_ERROR. It does not execute the supplied product and cannot identify that binary's failure conclusively.

- M6 FAT12 headless probes on existing binaries: [fragmented read](evidence/m6-fragmented-fat-runtime.json), [cross-cluster write](evidence/m6-fragmented-fat-write-runtime.json), [extension](evidence/m6-fragmented-fat-extend-runtime.json), and [truncation](evidence/m6-fragmented-fat-truncate-runtime.json). Each is a bounded disposable-media test, not full FAT coverage.

- M6 [Get-DPB geometry](evidence/m6-dpbfields-headless-runtime.json): 13 checked fields match one 1.44 MB FAT12 fixture; other fields and geometries remain open.

- M6 reference inventories: [kernel modules](evidence/m6-kernel-module-reference-inventory.json), [BIOS modules](evidence/m6-io-module-reference-inventory.json), and [MSCHAR NT seams](evidence/m6-mschar-nt-seam-audit.json). These are bounded source comparisons, not proof of historical authorship or full runtime behavior.
