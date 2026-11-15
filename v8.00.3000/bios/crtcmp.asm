;** CRTCMP.ASM - Case-insensitive far string comparison
;
; Entry: two far string pointers on the C stack.
; Exit: AX is negative, zero or positive; caller removes arguments.
; Same algorithm as LLIBCE stricmp. MASM chooses opcode 3Ah for
; register CMP; the original compiler chose equivalent opcode 38h.
; Encode only these two instructions explicitly; no object patching.
_TEXT segment word public 'RESUME_CODE'
        assume cs:_TEXT
	public _strncmp
_strncmp proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	mov	cx,[bp+0eh]
	jcxz	short snc_done
	mov	bx,cx
	les	di,dword ptr [bp+6]
	mov	si,di
	xor	ax,ax
	repne	scasb
	neg	cx
	add	cx,bx
	mov	di,si
	lds	si,dword ptr [bp+0ah]
	repe	cmpsb
	mov	al,[si-1]
	xor	cx,cx
	cmp	al,es:[di-1]
	ja	short snc_sign
	jz	short snc_done
	dec	cx
	dec	cx
snc_sign:
	not	cx
snc_done:
	mov	ax,cx
	pop	ds
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	retf
_strncmp endp

	db 0
        public __stricmp,__strcmpi
__strcmpi label far
__stricmp proc far
        push bp
        mov bp,sp
        mov dx,si
        push ds
        lds si,[bp+10]
        les bx,[bp+6]
        mov al,0FFh
compare_next:
        or al,al
        jz short compare_done
        lodsb
        mov ah,es:[bx]
        inc bx
        db 038h,0C4h            ; cmp ah,al (r/m8,r8)
        jz short compare_next
        sub al,'A'
        cmp al,26
        sbb cl,cl
        and cl,20h
        add al,cl
        add al,'A'
        xchg ah,al
        sub al,'A'
        cmp al,26
        sbb cl,cl
        and cl,20h
        add al,cl
        add al,'A'
        db 038h,0E0h            ; cmp al,ah (r/m8,r8)
        jz short compare_next
        sbb al,al
        sbb al,0FFh
compare_done:
        cbw
        pop ds
        mov si,dx
        pop bp
        ret
__stricmp endp
	db 0
	public _strncpy
_strncpy proc far
	push	bp
	mov	bp,sp
	push	di
	push	si
	push	ds
	les	di,dword ptr [bp+6]
	lds	si,dword ptr [bp+0ah]
	mov	bx,di
	mov	cx,[bp+0eh]
	jcxz	short snc_result
snc_copy:
	lodsb
	or	al,al
	jz	short snc_pad
	stosb
	loop	snc_copy
snc_pad:
	xor	al,al
	rep	stosb
snc_result:
	mov	ax,bx
	mov	dx,es
	pop	ds
	pop	si
	pop	di
	mov	sp,bp
	pop	bp
	retf
_strncpy endp

_TEXT ends
        end
