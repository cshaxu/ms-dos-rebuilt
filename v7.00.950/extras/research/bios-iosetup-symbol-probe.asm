BIOS_CODE SEGMENT
ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
        ORG 0DD8h
tim_drv db 0FFh
        ORG 0DDEh
motorstartup db 0
settlecurrent db 0
settleslow db 0
        ORG 0DE2h
save_eot db 0
eot db 9
dpt dd 0
        ORG 13D3h
iosetup PROC NEAR
        mov al,es:[di+4]
        mov cs:tim_drv,al
        cmp byte ptr cs:media_set_for_format,0
        jne iosetup_done
        mov al,cs:eot
        push ds
        lds si,cs:dpt
        xchg al,[si+4]
        mov ah,[si+10]
        mov cs:save_eot,al
        mov cs:motorstartup,ah
        cmp byte ptr es:[di+22h],2
        jnz motor_ok
        mov byte ptr [si+10],4
motor_ok:
        mov al,1
        xchg al,[si+9]
        pop ds
        mov cs:settlecurrent,al
        mov al,15
        mov cs:settleslow,al
iosetup_done:
        ret
iosetup ENDP
        ORG 17A2h
media_set_for_format db 0
BIOS_CODE ENDS
END
