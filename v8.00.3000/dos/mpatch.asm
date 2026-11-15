;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;
;mpatch.asm -- holds data patch location for callouts 
; -- allocate cluster in rom.asm
;
; This area is pointed to by OffsetMagicPatch[609h] in fixed DOS data.
; Currently, this location is used only by magicdrv.sys's patch to
; cluster allocation, however it can be expanded to be used by other
; patches.  This is important since we have an easy-access pointer to
; this location in OffsetMagicPatch.  Magicdrv.sys is guaranteed to
; only patch out a far call/retf, so any space after that could be
; used as a patch by using OffsetMagicPatch+6.  See rom.asm on how
; to call out here.
;
; Currently, we allocate only the minimum space required for the 6
; byte magicdrv patch, so if you change the dos data, you may want
; to reserve space here if your new data will be position dependent
; and would prohibit growing of this table.
;       
;history	-	created 8-7-92 by scottq
;		-	added Rational386PatchPtr 2-1-93 by jimmat
;
;Exported Functions
;==================
;MagicPatch     -       callout patched by magidrv.sys for cluster allocations
;
DosData Segment



MagicPatch proc far
        retf            ;default is to just return to allocate
        nop             ;however, this code will be patched
        nop             ;by magicdrv.sys to
        nop             ; call far ?:?     
        nop             ; retf or perhaps just jmp far
        nop             ;retf/nop take one byte, so we need six instructions
                        ;for 6 byte patch
MagicPatch endp

DosData Ends

	END

