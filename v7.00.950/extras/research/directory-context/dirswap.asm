; Exchange saved and current directory positions.
DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:NOTHING
EXTRN SaveDirError:NEAR
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
SaveDir ENDP
DOSCODE ENDS
END
