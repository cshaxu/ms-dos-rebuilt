DOS7_CONFIG equ 1
desc struc
 seg_lim dw 0
 lo_word dw 0
 hi_byte db 0
 acc_rights db 0
 reserved dw 0
desc ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f39h
sys_model_byte dw 0
 org 1b1bh
bmove label byte
 org 1b2bh
src_desc desc <>
 org 1b4bh
ClrdVDISKHead db 32 dup(0)
 org 1b6bh
ClrVDISKHeader	proc	near

;-----------------------------------------------------------	      ;I070
; The following workaround get around a problem with the	      ;I070
; Tortugas and PS/2 30-286 BIOS when password server mode	      ;I070
; is set.  On those machines the INT 15h block move code	      ;I070
; goes through the 8042 to twiddle A20 instead of port 92h.	      ;I070
; In password server mode the 8042 is disabled so the block	      ;I070
; move crashes the system. We can do this because these		      ;I070
; systems clear all of memory on a cold boot.			      ;I070
								      ;I070
                in      al,64h         ; Test for password servr mode ;I070
                test    al,10h         ; Is keyboard inhibited?	      ;I070
                jnz     ClrVDISKok     ; No, go do block move.	      ;I070
                                       ; Check for Tortugas...	      ;I070
                cmp     word ptr cs:[sys_model_byte],19F8h	      ;I070
                je      ClrVDISKno				      ;I070
                                       ; Check for mod 30-286	      ;I070
                cmp     word ptr cs:[sys_model_byte],09FCh	      ;I070
IFDEF DOS7_CONFIG
                je      ClrVDISKno
ELSE
                jne     ClrVDISKok				      ;I070
ClrVDISKno:     ret                    ; Return w/o block move.	      ;I070
ENDIF
								      ;I070
ClrVDISKok:							      ;I070
;-----------------------------------------------------------	      ;I070

		push	es
		mov	ax, cs
		mov	dx, ax
		mov	cl, 12
		shr	dx, cl
		mov	cl, 4
		shl	ax, cl
		add	ax, offset ClrdVDISKHead
		adc	dl, 0
		mov	src_desc.lo_word, ax
		mov	src_desc.hi_byte, dl
		mov	cx, 16			; 16 words
		push	cs
		pop	es
		mov	si, offset bmove
		mov	ah, 87h
		int	15h
		pop	es
IFDEF DOS7_CONFIG
ClrVDISKno:
ENDIF
		ret
ClrVDISKHeader	endp
sysinitseg ends
end
