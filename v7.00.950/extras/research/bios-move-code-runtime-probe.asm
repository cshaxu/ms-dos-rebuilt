SOURCE SEGMENT PARA PUBLIC 'DATA'
SourceBytes db 02F61h dup (?)
SOURCE ENDS
DEST SEGMENT PARA PUBLIC 'DATA'
DestBytes db 02F61h dup (?)
DEST ENDS
TESTDATA SEGMENT PARA PUBLIC 'DATA'
TestStack db 256 dup (?)
StackTop LABEL BYTE
TESTDATA ENDS
; Move BIOS code into the requested segment.
SYSINITSEG SEGMENT
ASSUME CS:SYSINITSEG,DS:NOTHING,ES:NOTHING
        ORG 01924h
MovBIOS PROC NEAR
        mov     ds,word ptr cs:[0F40h]
        mov     si,30h
        mov     di,si
        mov     cx,2DA0h
        add     cx,word ptr cs:[0FF7h]
        sub     cx,si
        shr     cx,1
        rep     movsw
        mov     ax,es
        call    ReinitBios
        ret
MovBIOS ENDP
        ORG 01BEDh
ReinitBios:
        mov cs:HelperResult,ax
        ret
HelperResult dw 0

TestStart PROC FAR
        mov ax,TESTDATA
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov ax,SOURCE
        mov ds,ax
        mov cs:[0F40h],ax
        mov word ptr cs:[0FF7h],01C0h
        mov byte ptr ds:[002Fh],33h
        mov byte ptr ds:[0030h],11h
        mov byte ptr ds:[2F5Fh],22h
        mov ax,DEST
        mov es,ax
        mov byte ptr es:[002Fh],66h
        mov byte ptr es:[0030h],00h
        mov byte ptr es:[2F5Fh],00h
        mov byte ptr es:[2F60h],77h
        call MovBIOS
        cmp byte ptr es:[002Fh],66h
        jne bad
        cmp byte ptr es:[0030h],11h
        jne bad
        cmp byte ptr es:[2F5Fh],22h
        jne bad
        cmp byte ptr es:[2F60h],77h
        jne bad
        mov ax,es
        cmp cs:HelperResult,ax
        jne bad
        mov ax,4C00h
        int 21h
bad:    mov ax,4C01h
        int 21h
TestStart ENDP

SYSINITSEG ENDS
END TestStart
