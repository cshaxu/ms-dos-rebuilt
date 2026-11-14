;** CRTCMP.ASM - Case-insensitive far string comparison
;
; Entry: two far string pointers on the C stack.
; Exit: AX is negative, zero or positive; caller removes arguments.
; Same algorithm as LLIBCE stricmp. MASM chooses opcode 3Ah for
; register CMP; the original compiler chose equivalent opcode 38h.
; Encode only these two instructions explicitly; no object patching.
_TEXT segment word public 'CODE'
        assume cs:_TEXT
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
_TEXT ends
        end
