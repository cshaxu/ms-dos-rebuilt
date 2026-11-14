DOSDATA SEGMENT
        ORG     0AACh
DirSave1 dw     7 dup (0)
DOSDATA ENDS

DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:DOSDATA,ES:NOTHING
CopyDirSave PROC NEAR
        mov     cx,DirSave1
        mov     [di],cx
        jcxz    CopyDirDone
        push    si
        push    es
        mov     cx,ds
        mov     es,cx
        mov     si,OFFSET DirSave1
        mov     cx,7
        cld
        rep     movsw
        pop     es
        pop     si
CopyDirDone:
        ret
CopyDirSave ENDP
DOSCODE ENDS
END
