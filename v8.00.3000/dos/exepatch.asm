;
;	Microsoft Confidential
;	Copyright (C) Microsoft Corporation 1991
;	All Rights Reserved.
;

;** EXEPATCH.ASM 
;
;	Contains the foll:
;
;		- code to find and overlay buggy unpack code
;		- new code to be overlayed on buggy unpack code 
;		- old code sequence to identify buggy unpack code
;
;	Revision history:
;
;		Created: 5/14/90
;
;
;
;----------------------------------------------------------------------------
;
; M020 : Fix for rational bug - for details see routine header
; M028 : 4b04 implementation
; M030 : Fixing bug in EXEPACKPATCH (EXEC_CS is an un-relocated value)
; M032 : set turnoff bit only if DOS in HMA.
; M033 : if IP < 2 then not exepacked.
; M046 : support for a 4th version of exepacked files.
; M068 : support for copy protected apps.
; M071 : use A20OFF_COUNT of 10.
;
;----------------------------------------------------------------------------
;
.XLIST
.XCREF

INCLUDE version.inc
INCLUDE dosseg.inc
INCLUDE DOSSYM.INC
INCLUDE exe.inc
INCLUDE	PDB.INC

.CREF
.LIST


	public	exepatch

PATCH1_COM_OFFSET	EQU	06CH
PATCH1_OFFSET		EQU	028H
PATCH1_CHKSUM		EQU	0EF4EH
CHKSUM1_LEN		EQU	11CH/2

PATCH2_COM_OFFSET	EQU	076H
PATCH2_OFFSET		EQU	032H

	; The strings that start at offset 076h have two possible 
	; check sums that are defined as PATCH2_CHKSUM PATCH2A_CHKSUM

PATCH2_CHKSUM		EQU	78B2H
CHKSUM2_LEN		EQU	119H/2
PATCH2A_CHKSUM		EQU	1C47H		; M046
CHKSUM2A_LEN		EQU	103H/2		; M046

PATCH3_COM_OFFSET	EQU	074H
PATCH3_OFFSET		EQU	032H
PATCH3_CHKSUM		EQU	4EDEH
CHKSUM3_LEN		EQU	117H/2




DOSDATA	SEGMENT

;	EXTRN	exec_signature	:WORD	; Must contain 4D5A  (yay zibo!)

;	EXTRN	exec_init_IP 	:WORD	; IP of entry
;	EXTRN	exec_init_CS 	:WORD	; CS of entry

	EXTRN	UNPACK_OFFSET	:WORD
;	EXTRN	A20OFF_FLAG	:byte

DOSDATA	ENDS


DOSCODE	SEGMENT
	ASSUME	CS:DOSCODE, SS:DOSDATA
	EXTRN	ScanCodeSeq:near,VerifyVersion:near
public		exepatch_start
exepatch_start	label 	byte

	;
	; The following is the code that'll be layed over the buggy unpack
	; code.
	;
str1	label	byte

	db  06h	  		;push	es		 
	db  8Ch, 0D8h		;mov	ax,ds 

first_stop	equ	$ - str1
			
	db  2Bh, 0C2h		;sub	ax, dx			

first		label	byte

	db  8Eh, 0D8h		;mov	ds,ax			
	db  8Eh, 0C0h		;mov	es,ax			
	db  0BFh, 0Fh, 00h	;mov	di,000FH
	db  57h	    		;push	di
	db  0B9h, 10h, 00h	;mov	cx,0010H
	db  0B0h, 0FFh 		;mov	al,0FFH 		
	db  0F3h, 0AEh 		;repz	scasb			
	db  47h	    		;inc	di			
	db  8Bh, 0F7h  		;mov	si,di			
	db  5Fh	    		;pop	di
	db  58h	    		;pop	ax

second_stop	equ	$ - first

	db  2Bh, 0C2h  		;sub	ax, dx			

second		label	byte

	db  8Eh, 0C0h  		;mov	es,ax			
		    		;NextRec:				
	db  0B9h, 04h, 02h	;mov	cx, 0204h
		    		;norm_agn:				
	db  8Bh, 0C6h		;mov	ax,si			
	db  0F7h, 0D0h		;not	ax		
	db  0D3h, 0E8h		;shr	ax,cl		
	db  74h, 13h		;jz	SI_ok			
	db  8Ch, 0DAh		;mov	dx,ds			
	db  83h, 0CEh, 0F0h	;or	si,0FFF0H
	db  2Bh, 0D0h		;sub	dx,ax			
	db  73h, 08h		;jnc	SItoDS			
	db  0F7h, 0DAh		;neg	dx			
	db  0D3h, 0E2h		;shl	dx,cl			
	db  2Bh, 0F2h		;sub	si,dx			
	db  33h, 0D2h		;xor	dx,dx			
				;SItoDS: 				
	db  8Eh, 0DAh		;mov	ds,dx		
				;SI_ok:					
	db  87h, 0F7h		;xchg	si,di			
	db  1Eh			;push	ds			
	db  06h			;push	es			
	db  1Fh			;pop	ds			
	db  07h			;pop	es			
	db  0FEh, 0CDh		;dec	ch			
	db  75h, 0DBh		;jnz	norm_agn		
	db  0ACh		;lodsb			
	db  92h			;xchg	dx,ax
	db  4Eh			;dec	si
	db  0ADh		;lodsw			
	db  8Bh, 0C8h		;mov	cx,ax		
	db  46h			;inc	si		
	db  8Ah, 0C2h		;mov	al,dl		
	db  24h, 0FEh		;and	al,0FEH		
	db  3Ch, 0B0h		;cmp	al,RPTREC
	db  75h, 05h		;jne	TryEnum
	db  0ACh		;lodsb				
	db  0F3h, 0AAh		;rep stosb			

;	db  0EBh, 07h, 90h	;jmp	TryNext
	db  0EBh, 06h		;jmp	TryNext

				;TryEnum:
	db  3Ch, 0B2h		;cmp	al,ENMREC
	db  75h, 6Ch		;jne	CorruptExe		
	db  0F3h, 0A4h		;rep movsb			
				;TryNext:

	db  92h			;xchg	dx,ax
;	db  8Ah, 0C2h		;mov	al,dl			

	db  0A8h, 01h		;test	al,1			
	db  74h, 0B9h		;jz	NextRec			
	db  90h, 90h		;nop, nop
	

last_stop	equ	$ - second
size_str1	equ	$-str1


	;
	; The following is the code that we need to look for in the exe
	; file.
	;
scan_patch1	label	byte

	db  8Ch, 0C3h		;mov	bx,es			
	db  8Ch, 0D8h		;mov	ax,ds
	db  2Bh, 0C2h		;sub	ax, dx
	db  8Eh, 0D8h		;mov	ds,ax			
	db  8Eh, 0C0h		;mov	es,ax			
	db  0BFh, 0Fh,00h	;mov	di,000FH
	db  0B9h, 10h, 00h	;mov	cx,0010H
	db  0B0h, 0FFh		;mov	al,0FFH
	db  0F3h, 0AEh		;repz	scasb			
	db  47h			;inc	di			
	db  8Bh, 0F7h		;mov	si,di
	db  8Bh, 0C3h		;mov	ax,bx			
	db  2Bh, 0C2h		;sub	ax, dx
	db  8Eh, 0C0h		;mov	es,ax
	db  0BFh, 0fh,00h	;mov	di,000FH
				;NextRec:
	db  0B1h, 04h		;mov	cl,4
	db  8Bh, 0C6h		;mov	ax,si
	db  0F7h, 0D0h		;not	ax		
	db  0D3h, 0E8h		;shr	ax,cl		
	db  74h, 09h		;jz	SI_ok
	db  8Ch, 0DAh		;mov	dx,ds
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0DAh		;mov	ds,dx		
	db  83h, 0CEh, 0F0h	;or	si,0FFF0H	       
	       			;SI_ok:
	db  8Bh, 0C7h		;mov	ax,di		
	db  0F7h, 0D0h		;not	ax
	db  0D3h, 0E8h		;shr	ax,cl
	db  74h, 09h		;jz	DI_ok
	db  8Ch, 0C2h		;mov	dx,es
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0C2h		;mov	es,dx
	db  83h, 0CFh, 0F0h	;or	di,0FFF0H
				;DI_ok:

size_scan_patch1	equ	$-scan_patch1


scan_patch2	label	byte

			
	db  8Ch, 0C3h		;mov	bx,es			
	db  8Ch, 0D8h		;mov	ax,ds
	db  48h			;dec	ax
	db  8Eh, 0D8h		;mov	ds,ax			
	db  8Eh, 0C0h		;mov	es,ax			
	db  0BFh, 0Fh, 00h	;mov	di,000FH
	db  0B9h, 10h, 00h	;mov	cx,0010H
	db  0B0h, 0FFh		;mov	al,0FFH
	db  0F3h, 0AEh		;repz	scasb			
	db  47h			;inc	di			
	db  8Bh, 0F7h		;mov	si,di
	db  8Bh, 0C3h		;mov	ax,bx			
	db  48h			;dec	ax
	db  8Eh, 0C0h		;mov	es,ax
	db  0BFh, 0Fh, 00h	;mov	di,000FH		
				;NextRec:
	db  0B1h, 04h		;mov	cl,4
	db  8Bh, 0C6h		;mov	ax,si
	db  0F7h, 0D0h		;not	ax		
	db  0D3h, 0E8h		;shr	ax,cl		
	db  74h, 0Ah		;jz	SI_ok
	db  8Ch, 0DAh		;mov	dx,ds
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0DAh		;mov	ds,dx		
	db  81h, 0CEh, 0F0h, 0FFh
				;or	si,0FFF0H
				;SI_ok:
	db  8Bh, 0C7h		;mov	ax,di		
	db  0F7h, 0D0h		;not	ax
	db  0D3h, 0E8h		;shr	ax,cl
	db  74h, 0Ah		;jz	DI_ok
	db  8Ch, 0C2h		;mov	dx,es
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0C2h		;mov	es,dx
	db  81h, 0CFh, 0F0h, 0FFh
				;or	di,0FFF0H
				;DI_ok:


size_scan_patch2	equ	$-scan_patch2


scan_patch3	label	byte

			
	db  8Ch, 0C3h		;mov	bx,es			
	db  8Ch, 0D8h		;mov	ax,ds
	db  48h			;dec	ax
	db  8Eh, 0D8h		;mov	ds,ax			
	db  8Eh, 0C0h		;mov	es,ax			
	db  0BFh, 0Fh, 00h	;mov	di,000FH
	db  0B9h, 10h, 00h	;mov	cx,0010H
	db  0B0h, 0FFh		;mov	al,0FFH
	db  0F3h, 0AEh		;repz	scasb			
	db  47h			;inc	di			
	db  8Bh, 0F7h		;mov	si,di
	db  8Bh, 0C3h		;mov	ax,bx			
	db  48h			;dec	ax
	db  8Eh, 0C0h		;mov	es,ax
	db  0BFh, 0Fh, 00h	;mov	di,000FH		
				;NextRec:
	db  0B1h, 04h		;mov	cl,4
	db  8Bh, 0C6h		;mov	ax,si
	db  0F7h, 0D0h		;not	ax		
	db  0D3h, 0E8h		;shr	ax,cl		
	db  74h, 09h		;jz	SI_ok
	db  8Ch, 0DAh		;mov	dx,ds
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0DAh		;mov	ds,dx	
	db  83h, 0CEh, 0F0h	;or	si,0FFF0H	
				;SI_ok:
	db  8Bh, 0C7h		;mov	ax,di		
	db  0F7h, 0D0h		;not	ax
	db  0D3h, 0E8h		;shr	ax,cl
	db  74h, 09h		;jz	DI_ok
	db  8Ch, 0C2h		;mov	dx,es
	db  2Bh, 0D0h		;sub	dx,ax
	db  8Eh, 0C2h		;mov	es,dx
	db  83h, 0CFh, 0F0h	;or	di,0FFF0H
				;DI_ok:


size_scan_patch3	equ	$-scan_patch3


scan_com	label	byte

	db  0ACh		;lodsb			
	db  8Ah, 0D0h		;mov	dl,al		
	db  4Eh			;dec	si
	db  0ADh		;lodsw			
	db  8Bh, 0C8h		;mov	cx,ax		
	db  46h			;inc	si		
	db  8Ah, 0C2h		;mov	al,dl		
	db  24h, 0FEh		;and	al,0FEH		
	db  3Ch, 0B0h		;cmp	al,RPTREC
	db  75h, 06h		;jne	TryEnum
	db  0ACh		;lodsb				
	db  0F3h, 0AAh		;rep stosb			
	db  0EBh, 07h, 90h	;jmp	TryNext
				;TryEnum:
	db  3Ch, 0B2h		;cmp	al,ENMREC
	db  75h, 6Bh		;jne	CorruptExe		
	db  0F3h, 0A4h		;rep movsb			
				;TryNext:
	db  8Ah, 0C2h		;mov	al,dl			
	db  0A8h, 01h		;test	al,1			
;	db  74h, 0BAh		;jz	NextRec			

size_scan_com	equ	$-scan_com

ExePatch	proc	near
		call	ExePackPatch
		ret
ExePatch	endp



;---------------------------------------------------------------------------
;
; Procedure Name 	: ExePackPatch
;
; Inputs	 	: DS 			-> DOSDATA
;			  ES:0 			-> read in image
;			  ax:cx = start cs:ip of program
; Output		:		
;
;	1. If ES <= 0fffh
;	   2. if exepack signature ('RB') found
;	      3. if common code to patch compares (for 3 diff. versions)
;	       	 4. if rest of the code & checksum compares
;	  	    5. overlay buggy code with code in 
;		       doscode:str1.
;		 6. endif
;	      7. endif
;	   8. endif
;	9. endif
;
;
; Uses			: NONE
;
;---------------------------------------------------------------------------
		

ExePackPatch	proc	near

	push	bx
	mov	bx, es			; bx has load segment
	cmp	bx, 0fffh		; Q: is the load segment > 64K
	jbe	ep_cont			; N: 
	pop	bx			; Y: no need to patch
	ret

ep_cont:
	push	ds
	push	es
	push	ax
	push	cx
	push	si
	push	di
	
		; M033 - start
		; exepacked prgrams have an IP of 12h (>=2)

	sub	cx, 2			; Q: is IP >=2 
	.386
	JC	NEAR PTR ep_notpacked		; N: exit
	.8086
					; ax:cx now points to location of
					; 'RB' if this is an exepacked file.

		; M033 - end

	mov	di, cx
	mov	es, ax
	mov	[unpack_offset], di	; save pointer to 'RB' in 
					; unpack_offset


	cmp	word ptr es:[di], 'BR'
	.386
	JNE	NEAR PTR ep_notpacked
	.8086

	push	cs
	pop	ds			; set ds to cs
	assume	ds:nothing

	add	di, PATCH1_COM_OFFSET	; es:di -> points to place in packed 
					;          file where we hope to find
					;	   scan string. 

	call	chk_common_str		; check for match

	jnz	ep_chkpatch2		; Q: does the patch match
					; N: check at patch2_offset
					; Y: check for rest of patch string

	mov	si, offset DOSCODE:scan_patch1
					; ds:si -> scan string 
	mov	di, [unpack_offset]	; restore di to point to 'RB'

	add	di, PATCH1_OFFSET	; es:di -> points to place in packed 
					;          file where we hope to find
					;	   scan string. 
	mov	cx, size_scan_patch1
	mov	bx, CHKSUM1_LEN
	mov	ax, PATCH1_CHKSUM
	call	chk_patchsum		; check if patch and chk sum compare
	jc	ep_done1		; Q: did we pass the test
					; N: exit
					; Y: overlay code with new 
	
	mov	si, offset DOSCODE:str1
	mov	cx, size_str1
	
rep	movsb


ep_done1:
	jmp	ep_done


ep_chkpatch2:
	mov	di, PATCH2_COM_OFFSET	; es:di -> possible loaction of patch
					; in another version of unpack
	call	chk_common_str		; check for match

	jnz	ep_chkpatch3		; Q: does the patch match
					; N: check for patch3_offset
					; Y: check for rest of patch string

	mov	si, offset DOSCODE:scan_patch2
					; ds:si -> scan string 

	mov	di, PATCH2_OFFSET	; es:di -> points to place in packed 
					;          file where we hope to find
					;	   scan string. 
	mov	cx, size_scan_patch2
	mov	bx, CHKSUM2_LEN
	mov	ax, PATCH2_CHKSUM
	call	chk_patchsum		; check if patch and chk sum compare

					; M046 - Start
					; Q: did we pass the test
	jnc	ep_patchcode2		; Y: overlay code with new 
					; N: try with a different chksum


	mov	si, offset DOSCODE:scan_patch2
					; ds:si -> scan string 
	mov	cx, size_scan_patch2
	mov	bx, CHKSUM2A_LEN
	mov	ax, PATCH2A_CHKSUM
	call	chk_patchsum		; check if patch and chk sum compare
					; Q: did we pass the test
	jc	ep_notpacked		; N: try with a different chksum
					; Y: overlay code with new 
						
ep_patchcode2:			       	; M046 - End
	mov	si, offset DOSCODE:str1
	mov	cx, first_stop
	
rep	movsb

	mov	ax, 4890h		; ax = opcodes for dec ax, nop
	stosw
	add	si, 2

	mov	cx, second_stop

rep	movsb

	stosw				; put in dec ax and nop
	add	si, 2

	mov	cx, last_stop

rep	movsb

	jmp	short ep_done

ep_chkpatch3:

	mov	di, PATCH3_COM_OFFSET	; es:di -> possible loaction of patch
					; in another version of unpack
	call	chk_common_str		; check for match

	jnz	ep_notpacked		; Q: does the patch match
					; N: exit
					; Y: check for rest of patch string


	mov	si, offset DOSCODE:scan_patch3
					; ds:si -> scan string 

	mov	di, PATCH3_OFFSET	; es:di -> points to place in packed 
					;          file where we hope to find
					;	   scan string. 
	mov	cx, size_scan_patch3
	mov	bx, CHKSUM3_LEN
	mov	ax, PATCH3_CHKSUM
	call	chk_patchsum		; check if patch and chk sum compare
	jc	ep_notpacked		; Q: did we pass the test
					; N: exit
					; Y: overlay code with new 

	mov	si, offset DOSCODE:str1
	mov	cx, first_stop
	
rep	movsb

	mov	al, 48h			; al = opcode for dec ax
	stosb
	add	si, 2

	mov	cx, second_stop

rep	movsb

	stosb				; put in dec ax
	add	si, 2

	mov	cx, last_stop

rep	movsb

	

ep_notpacked:

;	stc
;

ep_done:

	pop	di
	pop	si
	pop	cx
	pop	ax
	pop	es
	pop	ds
	pop	bx
	ret

;-------------------------------------------------------------------------
;
; 	Procedure Name	: chk_common_str
;
;	Input		: DS = DOSCODE
;			; ES:DI points to string in packed file
;
;	Output		; Z if match else NZ
;
;-----------------------------------------------------------------------

chk_common_str	proc	near

	mov	si, offset DOSCODE:scan_com
					; ds:si -> scan string 
	mov	cx, size_scan_com

repe	cmpsb	       

					; M046 - start
	; a fourth possible version of these exepacked programs have a 
	; 056h instead of 06bh. See scan_com above
	;
	; 	db  75h, 6Bh		;jne	CorruptExe		
	;
	; If the mismatch at this point is due to a 56h instead of 6bh 
	; we shall try to match the rest of the string
	;

	jz	ccs_done
	cmp	byte ptr es:[di-1], 56h
	jnz	ccs_done

repe	cmpsb	    
  
ccs_done:				; M046 - end
	ret

chk_common_str	endp		


;---------------------------------------------------------------------------
;
;	Procedure Name	: chk_patchsum
;
;	Input		: DS:SI -> string we're looking for
;			: ES:DI -> offset in packed file
;			: CX 	= scan length
;			: BX	= length of check sum
;			: AX 	= value of check sum
;
;	Output		: if patch & check sum compare
;				NC
;			  else
;				CY
;
;	Uses		: AX, BX, CX, SI
;----------------------------------------------------------------------------

chk_patchsum	proc	near

	push	di

repe	cmpsb			   

	jnz	cp_fail			; Q: does the patch match
					; N: exit
					; Y:	


		; we do a check sum starting from the location of the 
		; exepack signature 'RB' up to 11c/2 bytes, the end of the
		; unpacking code.


	mov	di, [unpack_offset]	; di -> start of unpack code
	mov	cx, bx			; cx = length of check sum

	mov	bx, ax			; save check sum passed to us in bx
	xor	ax, ax

ep_chksum:
	add	ax, word ptr es:[di]
	add	di, 2
	loop	ep_chksum

	pop	di			; restore di

	cmp	ax, bx		 	; Q: does the check sum match
	jnz	cp_fail			; N: exit
					; Y: 

	clc	
	ret

cp_fail:
	stc
	ret

chk_patchsum	endp


ExePackPatch	endp
;
DOSCODE	ENDS

	END


