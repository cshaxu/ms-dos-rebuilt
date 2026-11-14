BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
EXTRN tim_drv:BYTE,motorstartup:BYTE,settlecurrent:BYTE,settleslow:BYTE
EXTRN save_eot:BYTE,eot:BYTE,dpt:DWORD,media_set_for_format:BYTE
        ORG 05BCh
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
BIOS_CODE ENDS
END
