# T3 resident prefix recovery

Target/reference prefix comparison identified four absent instructions: PUSH AX / POP AX around CheckA20 and the UMB restoration in Issue_Exec_Call. Source edits remove those two pairs only. Target keeps Int2f_Trap STI, so the DOS6 difference removing it was deliberately not imported. DOS6 corroborates the CheckA20 pair removal but its later UMB implementation differs; the DOS5 target remains decisive.

Clean build evidence m2-t3-resident-prefix-build.json: 48462 bytes, SHA-256 1cc71c75816ccdeaea8e6c09a3f5e9554b527d03cfe5eb9280cb4c2c21d45dae. Four removed instruction bytes caused a 16-byte final reduction due to segment alignment; this is not a coverage measure. The rebuilt CheckA20 routine at file offset 0x9D, length 19, is exactly `9c2e803e3401007408e80c007303e81a009dc3`, identical to the target, including operand bytes.

MAP now gives Batch=0x0252 and EchoFlag=0x02A6, matching independently observed target operands. This corroborates the preceding four-byte layout correction without fixed-address patching. SingleCom=0x02AD, ForFlag=0x02B3 and ForPtr=0x02B4 remain one byte above target, consistent with the extra Io_Stderr byte. Its consumers in init.asm and command2.asm are still active and must be reconstructed before removing the field. No runtime test or whole-file match is claimed.

## Handle state and Io_Stderr recovery

Target at file offset 0xF0D restores stdin/stdout, skips handles 2/3/4 with ADD BX,4, and directly closes remaining handles. DOS6 corroborates this path; OpenNT instead restores stderr separately and filters invalid JFN entries. Replaced that bounded HeadFix block from the DOS6 reference, with target bytes as acceptance evidence. Target init at 0x186A stores only the word Io_Save before updating COM pointers; removed the OpenNT extra stderr load/store. Removed Io_Stderr data/public/extern declarations across rdata, command2, init and tcode after its consumers were removed.

Clean build m2-t3-handles-build.json: 48430 bytes, SHA-256 4a95684cf1109a6a1cbc2d5c1a329e101fcd8366bf963074ab0973cb154d89bd. `python tools/verify_handle_layout.py` confirms nine resident variables now have target-derived addresses, including SingleCom=0x2AC, ForFlag=0x2B2 and ForPtr=0x2B3. The 70-byte HeadFix region after its SetVect call equals target bytes exactly, including operand words. Initial test assumed HeadFix was public; it is local, so the verifier uses a unique fixed entry signature and still compares every byte. These are static checks; no guest behavior or whole-file equivalence is claimed.

## PAUSE behavior restored

Target PAUSE at 0x3C6A is a 13-byte routine: load message pointer 0x82A5, call std_printf=0x7232, GetKeystroke=0x2775, CRLF2=0x48D7, return. Removed the OpenNT SCS_PAUSE conditional wrapper from tcmd1b.asm. The field and init COMSPEC host service remain pending, rather than removing a still-written field blindly. Five other NT-only fields have no active consumer after TCODE recovery, but their removal is deferred until the remaining resident/init boundary is reconciled.

Initial editing accidentally matched PAUSE within SCS_PAUSE's EXTRN; compilation rejected the malformed module. Restored this previously unmodified file from its recorded OpenNT origin and reapplied the change to the whole-line PAUSE label only. Definition matching must use whole-line anchors to avoid suffix collisions. No failed candidate was accepted. Final clean build is 48416 bytes, SHA-256 bf0167131af8de9e4b95db92155aa3b6e1f4410cfe0777aee1d7d72f574ac0d4. `python tools/verify_pause.py` verifies the 13-byte opcode layout and resolves all three candidate calls against its MAP and the target destinations. Message and segment offsets remain different; static evidence does not replace a guest test.

## COMSPEC notification removed

Target bytes at 0x18DA are PUSH CS/POP DS immediately followed by EnvMaximum's checksum sequence at 0x18DC. DOS6 source agrees; OpenNT inserts a permanent-shell CMDSVC COMSPEC notification and stores its result in SCS_PAUSE. Removed that block after restoring PAUSE, then removed six now-unreferenced resident symbols (SCS_PAUSE, SCS_Is_First, SCS_PROMPT16, SCS_FIRSTTSR, RES_RDRINFO, RES_BATSTATUS), totaling nine bytes. A token-based source scan admitted only declaration/storage lines; any remaining executable use would have rejected the edit. Other NT state fields still used by init remain untouched.

Clean build m2-t3-comspec-build.json: 48384 bytes, SHA-256 22c260f969e4053d530642544097bebc3790581802d47c611e54c96131601200. `python tools/verify_comspec_init.py` checks direct segment-register handoff, checksum prefix with only its two layout words masked, and absence of removed publics. PIPEFILES remains four bytes above target; remaining active NT state fields explain an outstanding layout hypothesis, not a completed reconstruction. No target byte patching or guest behavior claim.
