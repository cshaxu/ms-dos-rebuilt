; Capture the directory position for a run of long-name entries.
DOSDATA SEGMENT
        ORG 0348h
LastEnt dw 0
        ORG 05BCh
ClusNum dw 0
DirSec dd 0
DirStart dw 0
        ORG 0AACh
DirSave1 dw 7 dup (0)
DOSDATA ENDS

DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:DOSDATA
CaptureDir PROC NEAR
        push    ds
        push    ss
        pop     ds
        test    ah,ah
        jz      CaptureBad
        cmp     ah,0E5h
        je      CaptureDeleted
        and     al,0Fh
        cmp     al,0Fh
        jne     CaptureBad
        cmp     word ptr [DirSave1],0
        jne     CaptureNext
        mov     cx,word ptr [DirStart]
        mov     word ptr [DirSave1+2],cx
        mov     cx,word ptr [DirSec]
        mov     word ptr [DirSave1+4],cx
        mov     cx,word ptr [DirSec+2]
        mov     word ptr [DirSave1+6],cx
        mov     cx,word ptr [ClusNum]
        mov     word ptr [DirSave1+8],cx
        mov     cx,word ptr [LastEnt]
        mov     word ptr [DirSave1+10],cx
CaptureNext:
        inc     word ptr [DirSave1]
        sub     al,al
        pop     ds
        ret
CaptureDeleted:
        cmp     word ptr [DirSave1],0
        je      CaptureBad
        inc     word ptr [DirSave1]
CaptureBad:
        or      al,0FFh
        pop     ds
        ret
CaptureDir ENDP
DOSCODE ENDS
END
