; Candidate reconstruction of SYSINIT PATH environment lookup.
; This is a research input; callers and original ownership remain unverified.
;
; Carry clear: ES:DI points just after the matching PATH= prefix.
; Carry set: the variable was not found.
;
FindPathEnv proc near
        lea     si,PathVariable
        mov     cx,5
        cmp     word ptr [config_envlen],0
        je      short path_not_found
        cld
        mov     es,[config_wrkseg]
        xor     di,di
path_next:
        push    si
        push    cx
        repe    cmpsb
        pop     dx
        pop     si
        je      short path_done
        dec     di
        xor     al,al
        mov     cx,100h
        repne   scasb
        cmp     byte ptr es:[di],0
        mov     cx,dx
        jne     short path_next
path_not_found:
        stc
path_done:
        ret
FindPathEnv endp
