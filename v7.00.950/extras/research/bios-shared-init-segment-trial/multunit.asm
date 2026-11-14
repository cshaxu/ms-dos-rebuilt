; Multiplex boot log services, isolated target-layout experiment.
        .386
Ticks_Absolute segment use32 at 0
        org 46Ch
bios_ticks dd ?
Ticks_Absolute ends
Bios_Code segment word public use16 'Bios_Code'
        assume cs:Bios_Code,ds:Bios_Code,es:nothing
        extrn bios_data_word:word
        public mult_call16,mult_call17,mult_call18,mult_call21

        public config_init_segment,sysinit_seg
sysinit_seg label word
config_init_segment dw 0
log_name db 'C:\BOOTLOG.TXT',0
old_log_name db 'C:\BOOTLOG.PRV',0
log_rotate db 1
log_flags dw 2041h
log_handle dw -1
log_open_count dw 0
log_state db 2
log_level db '0'
        even
log_device dw 0
log_message db 'MDF??'
log_extra db '(Logo disabled)',13,10

mult_call16 proc near
        push ds
        push cx
        push dx
        push si
        push cs
        pop ds
        mov ax,0FFFFh
        cmp log_state,1
        jz short open_exit
        cmp log_state,0
        jz short open_check
        mov log_level,'0'
open_check:
        mov bx,log_handle
        or bx,bx
        jns short open_count
        xor al,al
        xchg al,log_rotate
        mov dl,11h
        or al,al
        jz short open_file
        cmp log_level,'3'
        jc short open_rotate
        mov log_state,1
        mov ax,0FFFFh
        jmp short open_exit
open_rotate:
        cmp log_level,'0'
        jnz short open_drive
        or log_flags,4000h
open_drive:
        mov ax,3305h
        int 21h
        add dl,40h
        mov log_name,dl
        mov old_log_name,dl
        call rotate_bootlog
        mov dl,12h
open_file:
        mov bx,log_flags
        mov ax,6C00h
        mov cx,2
        xor dh,dh
        mov si,offset log_name
        int 21h
        jc short open_exit
        mov log_handle,ax
        mov bx,ax
        xor cx,cx
        mov dx,cx
        mov ax,4202h
        int 21h
open_count:
        inc log_open_count
        xor ax,ax
open_exit:
        pop si
        pop dx
        pop cx
        pop ds
        ret
mult_call16 endp

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

mult_call18 proc near
        mov     ax,cs:log_open_count
        dec     ax
        js short close_exit
        mov     cs:log_open_count,ax
        jnz short close_exit
        mov     bx,cs:log_handle
        mov     ah,3Eh
        int     21h
        mov     cs:log_handle,-1
        jc short close_exit
        xor     ax,ax
close_exit:
        ret
mult_call18 endp

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

rotate_bootlog proc near
        push es
        mov dx,offset old_log_name
        mov ah,41h
        int 21h
        mov dx,offset log_name
        mov di,offset old_log_name
        push cs
        pop es
        mov ah,56h
        int 21h
        jnc short rotate_exit
        cmp al,2
        jnz short rotate_exit
        or log_flags,4000h
rotate_exit:
        pop es
        ret
rotate_bootlog endp

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
        end
