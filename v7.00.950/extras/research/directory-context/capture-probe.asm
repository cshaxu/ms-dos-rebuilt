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
TestStack db 256 dup (0)
StackTop LABEL BYTE
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

TestStart PROC FAR
        mov ax,DOSDATA
        mov ds,ax
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov word ptr DirStart,1111h
        mov word ptr DirSec,2222h
        mov word ptr DirSec+2,3333h
        mov word ptr ClusNum,4444h
        mov word ptr LastEnt,5555h
        mov ax,410Fh
        call CaptureDir
        or al,al
        jnz bad
        cmp word ptr DirSave1,1
        jne bad
        cmp word ptr DirSave1+2,1111h
        jne bad
        cmp word ptr DirSave1+4,2222h
        jne bad
        cmp word ptr DirSave1+6,3333h
        jne bad
        cmp word ptr DirSave1+8,4444h
        jne bad
        cmp word ptr DirSave1+10,5555h
        jne bad
        mov word ptr DirStart,7777h
        mov ax,420Fh
        call CaptureDir
        cmp word ptr DirSave1,2
        jne bad
        cmp word ptr DirSave1+2,1111h
        jne bad
        mov ax,0E50Fh
        call CaptureDir
        cmp al,0FFh
        jne bad
        cmp word ptr DirSave1,3
        jne bad
        mov ax,4100h
        call CaptureDir
        cmp al,0FFh
        jne bad
        cmp word ptr DirSave1,3
        jne bad
        mov ax,4C00h
        int 21h
bad:    mov ax,4C01h
        int 21h
TestStart ENDP

DOSCODE ENDS
END TestStart
