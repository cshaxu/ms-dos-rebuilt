;** CRTPRINT.ASM - Formatted console and string output
;
; FAR C entries with variable argument lists; caller removes arguments.
; Return AX = number of characters written, or a negative error result.
; Define PRINTF_ONLY or SPRINTF_ONLY for separate library contributions.
        .286
        extrn __output:far,__flsbuf:far
_DATA segment word public 'DATA'
        extrn __iob:byte
_DATA ends
ifndef PRINTF_ONLY
_BSS segment word public 'BSS'
        public __edata,CRTStringStream
__edata label byte
CRTStringStream db 12 dup (?)
_BSS ends
; Keep the CRT static BSS before the near communal variables.
XOB segment word public 'BSS'
XOB ends
XO segment word public 'BSS'
XO ends
XOE segment word public 'BSS'
XOE ends
XOFB segment word public 'BSS'
XOFB ends
XOF segment word public 'BSS'
XOF ends
XOFE segment word public 'BSS'
XOFE ends
c_common segment para public 'BSS'
c_common ends
endif
ifdef PRINTF_ONLY
DGROUP group _DATA
else
DGROUP group _DATA,_BSS,XOB,XO,XOE,XOFB,XOF,XOFE,c_common
endif
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        extrn __stbuf:near,__ftbuf:near
ifndef SPRINTF_ONLY
        public _printf
_printf proc far
        enter 6,0
        push di
        push ds
        push offset DGROUP:__iob+12
        call __stbuf
        add sp,4
        mov di,ax
        lea ax,[bp+10]
        push ss
        push ax
        push word ptr [bp+8]
        push word ptr [bp+6]
        push ds
        push offset DGROUP:__iob+12
        call __output
        add sp,12
        mov [bp-6],ax
        push ds
        push offset DGROUP:__iob+12
        push di
        call __ftbuf
        add sp,6
        mov ax,[bp-6]
        pop di
        leave
        ret
_printf endp
endif
ifndef PRINTF_ONLY
        public _sprintf
_sprintf proc far
        enter 4,0
        push di
        push si
        mov byte ptr CRTStringStream+10,42h
        mov ax,[bp+6]
        mov dx,[bp+8]
        mov word ptr CRTStringStream+6,ax
        mov word ptr CRTStringStream+8,dx
        mov si,offset DGROUP:CRTStringStream
        mov [si],ax
        mov [si+2],dx
        mov word ptr CRTStringStream+4,7FFFh
        lea ax,[bp+14]
        push ss
        push ax
        push word ptr [bp+12]
        push word ptr [bp+10]
        push ds
        push si
        call __output
        add sp,12
        mov di,ax
        dec word ptr CRTStringStream+4
        js short print_flush
        les bx,dword ptr CRTStringStream
        inc word ptr CRTStringStream
        mov byte ptr es:[bx],0
        jmp short print_done
        nop
print_flush:
        push ds
        push si
        db 06Ah,0               ; push 0, compiler imm8 form
        call __flsbuf
        add sp,6
print_done:
        mov ax,di
        pop si
        pop di
        leave
        ret
_sprintf endp
endif
_TEXT ends
        end
