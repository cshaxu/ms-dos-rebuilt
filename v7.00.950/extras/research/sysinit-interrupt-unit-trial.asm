; Hardware interrupt entry table, isolated target-layout experiment.
.386
stacks equ 8
firstentry equ 0ch
lastentry equ 0eh
nextentry equ 10h
Bios_Data equ 70h
IsWin386 equ 8
fatal_msg equ 21bh
SysInitSeg segment word public 'system_init' use16
        assume cs:SysInitSeg
        org 0012h
old02   dd      0
int02 proc far
        call    do_int_stacks
        dw      old02
int02 endp
old08   dd      0
int08 proc far
        call    do_int_stacks
        dw      old08
int08 endp
old09   dd      0
int09 proc far
        jmp     short keyboard_lbl
        nop
        db      0
keyboard_lbl label near
        call    do_int_stacks
        dw      old09
int09 endp
old70   dd      0
int70 proc far
        call    do_int_stacks
        dw      old70
int70 endp
        irp     a,<0a,0b,0c,0d,0e,72,73,74,76,77>
int&a proc far
        jmp     short entry_int&a&_stk
old&a   dd      0
        dw      424Bh
firstflag&a db  0
        jmp     short intret_&a
        db      7 dup (0)
entry_int&a&_stk:
        call    do_int_stacks
        dw      old&a
intret_&a:
        iret
int&a endp
        endm
do_int_stacks proc near
        push    eax
        push    bp
        push    es
        mov     es,word ptr cs:[stacks+2]
        mov     bp,cs:[nextentry]
        mov     al,1
        xchg    es:byte ptr [bp],al
        cmp     al,0
        jne     short notfree02
        sub     word ptr cs:[nextentry],8
found02:
        mov     es:word ptr [bp+2],sp
        mov     es:word ptr [bp+4],ss
        mov     ax,bp
        mov     bp,es:word ptr [bp+6]
        cmp     es:[bp],ax
        jne     short foundbad02
        mov     ax,es
        mov     es,bp
        mov     bp,sp
        mov     bp,[bp+8]
        mov     ss,ax
        mov     sp,es
        mov     es,ax
        mov     bp,cs:[bp]
        pushf
        call    dword ptr cs:[bp]
        mov     bp,sp
        mov     bp,es:[bp]
        mov     ss,es:word ptr [bp+4]
        mov     sp,es:word ptr [bp+2]
        mov     es:byte ptr [bp],0
        mov     cs:[nextentry],bp
        pop     es
        pop     bp
        pop     eax
        add     sp,2
        iret
notfree02:
        cmp     al,1
        je      short findnext02
        xchg    es:byte ptr [bp],al
        jmp     short findnext02
foundbad02:
        cmp     bp,cs:[firstentry]
        jc      short findnext02
        mov     bp,ax
        mov     es:byte ptr [bp],3
findnext02:
        mov     bp,cs:[lastentry]
lploopp:
        cmp     es:byte ptr [bp],0
        jne     short inuse
        mov     al,1
        xchg    es:byte ptr [bp],al
        cmp     al,0
        je      short found02
        cmp     al,1
        je      short inuse
        mov     es:byte ptr [bp],al
inuse:
        cmp     bp,cs:[firstentry]
        je      short fatal
        sub     bp,8
        jmp     short lploopp
do_int_stacks endp
fatal   proc    near
        cli                             ; disable and mask interrupts
        mov     al,0ffh
        out     021h,al
        out     0a1h,al
        mov     ax,Bios_Data
        mov     ds,ax
        test    byte ptr ds:[IsWin386],40h
        jz      short fatal_loop_setup
        sub     di,di
        mov     es,di
        mov     bx,15h
        mov     ax,1684h
        int     2fh                     ; get V86 API entry
        mov     ax,es
        or      ax,di
        jz      short fatal_loop_setup
        push    cs
        mov     ax,offset fatal_loop_setup
        push    ax
        push    es
        push    di
        mov     ax,1                    ; set focus
        retf
fatal_loop_setup:
        push    cs
        pop     ds
        mov     si,fatal_msg
fatal_loop:
        lodsb
        or      al,al
        jz      short fatal_done
        mov     bl,7
        mov     ah,14
        int     010h
        jmp     short fatal_loop
fatal_done:
        hlt
        jmp     short fatal_done
fatal   endp
SysInitSeg ends
        end int02
