# XP NTDOS authority: initial LFN contract cross-check

Owner-directed supplementary semantic review; general style baseline remains
effective v6.22. XP source root:
O:/repos.external/winxpscodes/Source/XPSP1/NT/base/mvdm/dos.

Guest v86/doskrnl/dos/file.asm:906 delegates $LongFileNameAPI via
HRDSVC SVC_DEMLFNENTRY. dem/demdisp.c:175 maps it to demLFNEntry;
dem/demlfn.c:5591 delegates to demLFNDispatch and returns AX/CF. The actual
semantics must be read in DEM, not inferred from the guest stub alone.

## Checked interface surface

API | Microsoft authority | Current 950 correspondence | Scope
--- | --- | --- | ---
714E | demlfn.c:5350, demlfn.h:656 | TMISC2 PathFindFirst uses DS:DX, CX, ES:DI, SI=0; AX saved as handle | Registers and Win32 time-format selection checked
714F | demlfn.c:5400 | PathFindNext uses BX handle, ES:DI, SI=0 | Registers checked; wrapper preserves search flags but may overwrite AX during close
71A1 | demlfn.c:5435 | ClosePathFind supplies BX | Register contract checked; full ownership/cleanup semantics still pending
71A0 | demlfn.c:5298, :3792; demlfn.h:374 | SelectPathInterface supplies DS:DX root and CX=0; tests BX bit 4000h | Register/capability contract checked; all path boundary cases not proved
7160 | demlfn.c:5333; demlfn.h:673 | COPYPR2 CanonicalizePath uses DS:SI, ES:DI, CX=1 | Short-path request and expansion flag checked
716C | demlfn.c:5506 | TMISC2 redirection supplies DS:SI, BX/CX/DX/DI | Register roles checked; modes/error cases not exhaustively checked
7141 | demlfn.c:5441 and :4905 | TUCODE uses DS:DX pathname; batch LFN deletion sets CX=0 and SI=1, individual deletion sets SI=0 | Wildcard-selection contract checked; broader deletion edge cases still pending

PATH2 prefers the returned short filename by adding 104h to the long filename
pointer; SelectReturnedName subtracts 104h when the short-name field is empty.
XP dispatcher writes both cFileName and cAlternateFileName. This supports the
two-field design, not an assertion that every filename/path edge case is proven.

## Corrected finding

P48 corrects PathFindNext's overly strong AX return comment. Its instruction
stream saves search flags, then may call ClosePathFind, which loads AX=71A1h
and invokes DOS. This wrapper therefore cannot promise the original search AX.
No machine-code change is justified solely by the XP API contract. Consumers
must be checked against the wrapper's actual contract and frozen 950 target.

## Remaining semantic acceptance work

Enumerate all LFN callers and dispatched services; check conversion modes,
UNC/root/drive-relative/quoted/DBCS boundary handling, unsupported-call fallback,
returned error/CF propagation, search handle ownership and termination cleanup,
find-buffer and pathname sizing, and open/create/share/action behavior.
Record target-specific differences explicitly. Earlier file acceptance is not
retroactively described as full XP validation. A passed binary build proves
byte preservation, not the semantic cross-check itself.
