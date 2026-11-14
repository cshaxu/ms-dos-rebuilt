; INT 2Fh multiplex boot log write, isolated target-layout experiment.
        .386
Ticks_Absolute segment use32 at 0
        org 46Ch
bios_ticks dd ?
Ticks_Absolute ends
Bios_Code segment word public use16 'Bios_Code'
        assume cs:Bios_Code,ds:nothing,es:nothing
        org 00DAh
bios_data_word dw 0
        org 2B6Fh
log_flags dw 2041h
log_handle dw -1
log_count dw 0
        org 2B78h
log_device dw 0
log_message db 'MDF??'
log_extra db '(Logo disabled)',13,10
        org 2C1Fh
mult_call17 proc near
        mov bx,cs:log_handle
        or bx,bx
        js short write_exit
        push cx
        push edx
        push di
        push ds
        push es
        sub ax,ax
        mov es,ax
        mov ds,ax
        assume ds:Ticks_Absolute
        mov edx,bios_ticks
        assume ds:nothing
        mov di,604h
        mov al,'['
        stosb
        call hex_dword
        mov word ptr [di],205Dh
        mov cx,11
        mov dx,604h
        mov ah,40h
        int 21h
        pop es
        pop ds
        pop di
        pop edx
        pop cx
        jc short write_exit
        mov ah,40h
        int 21h
        jc short write_exit
        push cx
        push dx
        push si
        push ds
        mov ds,cs:bios_data_word
        test byte ptr ds:[9],20h
        jnz short write_notify
        push cs
        pop ds
        assume ds:Bios_Code
        mov si,offset log_extra
        cmp byte ptr [si],0
        jz short write_notify
        push es
        push di
        sub di,di
        mov es,di
        mov di,604h
        mov dx,di
        mov cx,11h
        cld
        push cx
        rep movsb
        pop cx
        mov byte ptr [si-11h],0
        push es
        pop ds
        assume ds:nothing
        mov ah,40h
        int 21h
        pop di
        pop es
write_notify:
        call mult_call21
        pop ds
        pop si
        pop dx
        pop cx
        jc short write_exit
        xor ax,ax
write_exit:
        ret
mult_call17 endp
        org 2CC8h
mult_call21 proc near
        push bx
        push cx
        push dx
        test cs:log_flags,4000h
        jz short notify_exit
        mov bx,cs:log_device
        or bx,bx
        jz short notify_exit
        push cs
        pop ds
        assume ds:Bios_Code
        mov word ptr log_message+3,3F3Fh
        mov dx,offset log_message
        mov ax,4404h
        mov cx,5
        int 21h
notify_exit:
        pop dx
        pop cx
        pop bx
        ret
mult_call21 endp
        org 2D16h
hex_digits db '0123456789ABCDEF'
hex_dword proc near
        push bx
        cld
        mov bx,offset hex_digits
        mov ah,0Fh
        mov cx,8
hex_next:
        rol edx,4
        mov al,dl
        and al,ah
        xlat cs:hex_digits
        stosb
        loop hex_next
        pop bx
        ret
hex_dword endp
Bios_Code ends
        end mult_call17
