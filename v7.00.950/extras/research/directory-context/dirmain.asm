; Exchange saved and current directory positions.
DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:NOTHING
EXTRN GetEntry:NEAR, IncDirty:NEAR, FlushBufGuarded:NEAR
SaveDirDone:
        clc
        ret
SaveDir PROC NEAR
        mov     cx,[di]
        jcxz    SaveDirDone
        add     cx,[di+10]
        dec     cx
        cmp     cx,[di+12]
        jbe     SaveDirSwap
        jmp     SaveDirError
SaveDirSwap:
        mov     ax,[di+2]
        xchg    ax,word ptr ds:[05C2h]
        mov     [di+2],ax
        mov     ax,[di+4]
        xchg    ax,word ptr ds:[05BEh]
        mov     [di+4],ax
        mov     ax,[di+6]
        xchg    ax,word ptr ds:[05C0h]
        mov     [di+6],ax
        mov     ax,[di+8]
        xchg    ax,word ptr ds:[05BCh]
        mov     [di+8],ax
        mov     ax,[di+10]
        xchg    ax,word ptr ds:[0348h]
        mov     [di+10],ax
        mov     ax,[di+12]
        xchg    ax,word ptr ds:[05DAh]
        mov     [di+12],ax
        push    bp
        push    es
ReadDir:
        les     bp,dword ptr ds:[058Ah]
        push    di
        call    GetEntry
        pop     di
        jc      RestoreDir
        les     bp,dword ptr ds:[05E2h]
        xor     ah,ah
CheckDir:
        mov     al,es:[bx]
        or      al,al
        jz      RestoreDir
        cmp     al,0E5h
        je      SkipDir
        mov     al,0Fh
        and     al,es:[bx+11]
        cmp     al,0Fh
        je      DeleteDir
        cmp     word ptr [di],1
        jne     BadDir
DeleteDir:
        mov     byte ptr es:[bx],0E5h
        or      ah,40h
SkipDir:
        inc     word ptr ds:[0348h]
        dec     word ptr [di]
        jz      BufferDone
        add     bx,20h
        cmp     bx,dx
        jb      CheckDir
BufferDone:
        test    byte ptr es:[bp+5],40h
        jnz     BufferMarked
        test    ah,ah
        jz      ReadDir
        call    IncDirty
BufferMarked:
        or      byte ptr es:[bp+5],44h
        les     bp,dword ptr ds:[058Ah]
        mov     al,es:[bp]
        push    di
        call    FlushBufGuarded
        pop     di
        jc      RestoreDir
        cmp     word ptr [di],0
        jne     ReadDir
RestoreDir:
        pop     es
        pop     bp
        mov     ax,[di+2]
        mov     word ptr ds:[05C2h],ax
        mov     ax,[di+4]
        mov     word ptr ds:[05BEh],ax
        mov     ax,[di+6]
        mov     word ptr ds:[05C0h],ax
        mov     ax,[di+8]
        mov     word ptr ds:[05BCh],ax
        mov     ax,[di+10]
        mov     word ptr ds:[0348h],ax
        mov     ax,[di+12]
        mov     word ptr ds:[05DAh],ax
        mov     word ptr [di],0
        ret
BadDir:
        stc
        jmp     short RestoreDir
SaveDirError:
        stc
        ret
SaveDir ENDP
DOSCODE ENDS
END
