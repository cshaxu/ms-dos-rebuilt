; Exchange saved and current directory positions.
DOSDATA SEGMENT
        ORG 0348h
LastEnt dw 0
        ORG 058Ah
ThisDPB dd 0
        ORG 05BCh
ClusNum dw 0
DirSec dd 0
DirStart dw 0
        ORG 05DAh
EntLast dw 0
        ORG 05E2h
CurBuf dd 0
DirtyCalled dw 0
TestContext dw 2,1111h,2222h,3333h,4444h,0,0064h
TestDPB db 32 dup (0)
TestBuffer db 32 dup (0)
EntryArea db 64 dup (0)
TestStack db 256 dup (0)
StackTop LABEL BYTE
DOSDATA ENDS

DOSCODE SEGMENT
ASSUME CS:DOSCODE,DS:DOSDATA
        ORG 07AEAh
GetEntry:
        mov bx,OFFSET EntryArea
        mov dx,bx
        add dx,64
        clc
        ret
        ORG 08FC7h
FlushBufGuarded:
        clc
        ret
        ORG 0AAD4h
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
        xchg    ax,word ptr [DirStart]
        mov     [di+2],ax
        mov     ax,[di+4]
        xchg    ax,word ptr [DirSec]
        mov     [di+4],ax
        mov     ax,[di+6]
        xchg    ax,word ptr [DirSec+2]
        mov     [di+6],ax
        mov     ax,[di+8]
        xchg    ax,word ptr [ClusNum]
        mov     [di+8],ax
        mov     ax,[di+10]
        xchg    ax,word ptr [LastEnt]
        mov     [di+10],ax
        mov     ax,[di+12]
        xchg    ax,word ptr [EntLast]
        mov     [di+12],ax
        push    bp
        push    es
ReadDir:
        les     bp,dword ptr [ThisDPB]
        push    di
        call    GetEntry
        pop     di
        jc      RestoreDir
        les     bp,dword ptr [CurBuf]
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
        inc     word ptr [LastEnt]
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
        les     bp,dword ptr [ThisDPB]
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
        mov     word ptr [DirStart],ax
        mov     ax,[di+4]
        mov     word ptr [DirSec],ax
        mov     ax,[di+6]
        mov     word ptr [DirSec+2],ax
        mov     ax,[di+8]
        mov     word ptr [ClusNum],ax
        mov     ax,[di+10]
        mov     word ptr [LastEnt],ax
        mov     ax,[di+12]
        mov     word ptr [EntLast],ax
        mov     word ptr [di],0
        ret
BadDir:
        stc
        jmp     short RestoreDir
SaveDirError:
        stc
        ret
SaveDir ENDP
        ORG 0C17Bh
IncDirty:
        inc word ptr DirtyCalled
        ret

TestStart PROC FAR
        mov ax,DOSDATA
        mov ds,ax
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov word ptr ThisDPB,OFFSET TestDPB
        mov word ptr ThisDPB+2,ax
        mov word ptr CurBuf,OFFSET TestBuffer
        mov word ptr CurBuf+2,ax
        mov word ptr DirStart,0AAAAh
        mov word ptr DirSec,0BBBBh
        mov word ptr DirSec+2,0CCCCh
        mov word ptr ClusNum,0DDDDh
        mov word ptr LastEnt,0EEEEh
        mov word ptr EntLast,0FFFFh
        mov byte ptr EntryArea,41h
        mov byte ptr EntryArea+11,0Fh
        mov byte ptr EntryArea+32,42h
        mov byte ptr EntryArea+43,20h
        mov di,OFFSET TestContext
        call SaveDir
        jnc $+5
        jmp near ptr bad
        cmp byte ptr EntryArea,0E5h
        je $+5
        jmp near ptr bad
        cmp byte ptr EntryArea+32,0E5h
        je $+5
        jmp near ptr bad
        cmp word ptr TestContext,0
        je $+5
        jmp near ptr bad
        cmp word ptr DirtyCalled,1
        je $+5
        jmp near ptr bad
        cmp byte ptr TestBuffer+5,44h
        je $+5
        jmp near ptr bad
        cmp word ptr DirStart,0AAAAh
        je $+5
        jmp near ptr bad
        cmp word ptr DirSec,0BBBBh
        je $+5
        jmp near ptr bad
        cmp word ptr DirSec+2,0CCCCh
        je $+5
        jmp near ptr bad
        cmp word ptr ClusNum,0DDDDh
        je $+5
        jmp near ptr bad
        cmp word ptr LastEnt,0EEEEh
        je $+5
        jmp near ptr bad
        cmp word ptr EntLast,0FFFFh
        je $+5
        jmp near ptr bad

        ; Empty saved context returns without an error.
        mov word ptr TestContext,0
        stc
        mov di,OFFSET TestContext
        call SaveDir
        jnc $+5
        jmp near ptr bad
        cmp word ptr DirStart,0AAAAh
        je $+5
        jmp near ptr bad
        ; Out-of-range saved context returns an error untouched.
        mov word ptr TestContext,2
        mov word ptr TestContext+10,64h
        mov word ptr TestContext+12,64h
        mov di,OFFSET TestContext
        call SaveDir
        jc $+5
        jmp near ptr bad
        cmp word ptr TestContext,2
        je $+5
        jmp near ptr bad
        cmp word ptr DirStart,0AAAAh
        je $+5
        jmp near ptr bad
        ; Unexpected short entry returns an error and restores positions.
        mov word ptr TestContext+10,0
        mov word ptr TestContext+12,64h
        mov byte ptr EntryArea,41h
        mov byte ptr EntryArea+11,20h
        mov di,OFFSET TestContext
        call SaveDir
        jc $+5
        jmp near ptr bad
        cmp byte ptr EntryArea,41h
        je $+5
        jmp near ptr bad
        cmp word ptr TestContext,0
        je $+5
        jmp near ptr bad
        cmp word ptr DirStart,0AAAAh
        je $+5
        jmp near ptr bad
        cmp word ptr DirSec,0BBBBh
        je $+5
        jmp near ptr bad
        cmp word ptr DirSec+2,0CCCCh
        je $+5
        jmp near ptr bad
        cmp word ptr ClusNum,0DDDDh
        je $+5
        jmp near ptr bad
        cmp word ptr LastEnt,0EEEEh
        je $+5
        jmp near ptr bad
        cmp word ptr EntLast,0FFFFh
        je $+5
        jmp near ptr bad

        mov ax,4C00h
        int 21h
bad:    mov ax,4C01h
        int 21h
TestStart ENDP

DOSCODE ENDS
END TestStart
