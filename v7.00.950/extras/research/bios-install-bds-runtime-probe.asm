BIOS_DATA SEGMENT
        ORG 0F8h
start_bds dd 0
FirstBDS db 64 dup (0)
NewBDS db 64 dup (0)
TestStack db 256 dup (0)
StackTop LABEL BYTE
BIOS_DATA ENDS
BIOS_CODE SEGMENT
ASSUME CS:BIOS_CODE,DS:BIOS_DATA,ES:NOTHING
        ORG 0DE3h
eot db 0
        ORG 2800h
nul_vid db "NO NAME    ",0
tmp_vid db "NO NAME    ",0
install_bds PROC NEAR
        push ds
        mov si,offset start_bds
loop_next_bds:
        lds si,dword ptr [si]
        mov al,byte ptr es:[di+4]
        cmp byte ptr [si+4],al
        jnz next_bds
        mov bl,10h
        or byte ptr es:[di+23h],bl
        or byte ptr [si+23h],bl
        and byte ptr es:[di+23h],0DFh
        mov bl,byte ptr [si+23h]
        and bl,2
        or byte ptr es:[di+23h],bl
next_bds:
        cmp word ptr [si],-1
        jnz loop_next_bds
        mov word ptr [si+2],es
        mov word ptr [si],di
        mov word ptr es:[di],-1
        pop ds
        mov al,byte ptr es:[di+34h]
        cmp al,cs:eot
        jbe eot_ok
        mov cs:eot,al
eot_ok:
        ret
install_bds ENDP

TestStart PROC FAR
        mov ax,BIOS_DATA
        mov ds,ax
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov es,ax
        mov word ptr start_bds,OFFSET FirstBDS
        mov word ptr start_bds+2,ax
        mov word ptr FirstBDS,0FFFFh
        mov byte ptr FirstBDS+4,80h
        mov byte ptr FirstBDS+23h,2
        mov byte ptr NewBDS+4,80h
        mov byte ptr NewBDS+23h,20h
        mov byte ptr NewBDS+34h,18
        mov byte ptr cs:eot,9
        mov di,OFFSET NewBDS
        call install_bds
        mov ax,OFFSET NewBDS
        cmp word ptr FirstBDS,ax
        je $+5
        jmp near ptr bad
        mov ax,es
        cmp word ptr FirstBDS+2,ax
        je $+5
        jmp near ptr bad
        cmp word ptr NewBDS,0FFFFh
        je $+5
        jmp near ptr bad
        cmp byte ptr FirstBDS+23h,12h
        je $+5
        jmp near ptr bad
        cmp byte ptr NewBDS+23h,12h
        je $+5
        jmp near ptr bad
        cmp byte ptr cs:eot,18
        je $+5
        jmp near ptr bad
        ; A different physical drive leaves the existing flags intact.
        mov word ptr FirstBDS,0FFFFh
        mov byte ptr FirstBDS+23h,2
        mov byte ptr NewBDS+4,81h
        mov byte ptr NewBDS+23h,20h
        mov byte ptr NewBDS+34h,9
        mov di,OFFSET NewBDS
        call install_bds
        cmp byte ptr FirstBDS+23h,2
        je $+5
        jmp near ptr bad
        cmp byte ptr NewBDS+23h,20h
        je $+5
        jmp near ptr bad
        cmp byte ptr cs:eot,18
        je $+5
        jmp near ptr bad
        mov ax,4C00h
        int 21h
bad:    mov ax,4C01h
        int 21h
TestStart ENDP

BIOS_CODE ENDS
END TestStart
