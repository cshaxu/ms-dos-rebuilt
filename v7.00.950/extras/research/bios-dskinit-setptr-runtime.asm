BIOS_DATA SEGMENT
        ORG 0012h
ptrsav dd 0
        ORG 0068h
drvmax db 0
Request db 32 dup (0)
TestStack db 256 dup (0)
StackTop LABEL BYTE
BIOS_DATA ENDS
SYSINITSEG SEGMENT
        ORG 0EAEh
dskdrvs dw 0
SYSINITSEG ENDS
BIOS_CODE SEGMENT
ASSUME CS:BIOS_CODE,DS:BIOS_DATA,ES:NOTHING
        ORG 0E65h
dsk_init PROC NEAR
        mov ah,byte ptr drvmax
        mov es,cs:config_init_segment
        mov di,offset dskdrvs
        jmp setptrsav
dsk_init ENDP
        ORG 0F6Bh
SetPtrSav PROC NEAR
        mov cx,es
        les bx,[ptrsav]
        mov es:[bx+0Dh],ah
        mov es:[bx+12h],di
        mov es:[bx+14h],cx
        clc
        ret
SetPtrSav ENDP
        ORG 2B4Eh
config_init_segment dw 0

TestStart PROC FAR
        mov ax,BIOS_DATA
        mov ds,ax
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov word ptr ptrsav,OFFSET Request
        mov word ptr ptrsav+2,ax
        mov byte ptr drvmax,4
        mov ax,SYSINITSEG
        mov cs:config_init_segment,ax
        stc
        call dsk_init
        jc bad
        cmp byte ptr Request+0Dh,4
        jne bad
        cmp word ptr Request+12h,0EAEh
        jne bad
        mov ax,SYSINITSEG
        cmp word ptr Request+14h,ax
        jne bad
        mov ax,4C00h
        int 21h
bad:    mov ax,4C01h
        int 21h
TestStart ENDP

BIOS_CODE ENDS
END TestStart
