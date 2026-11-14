BIOS_DATA SEGMENT
        ORG 0F8h
start_bds dd 0
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
BIOS_CODE ENDS
END
