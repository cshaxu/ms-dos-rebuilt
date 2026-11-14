; Isolated target-layout experiment for the stack failure handler.
Bios_Data       equ     70h             ; target image segment value
IsWin386        equ     8               ; target BIOS data offset
fatal_msg       equ     21bh            ; appended to copied stack code
SysInitSeg segment word public 'system_init'
        assume  cs:SysInitSeg
        org     01d6h
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
        end     fatal
