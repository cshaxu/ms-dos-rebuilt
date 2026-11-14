; Open boot log, isolated target-layout experiment.
Bios_Code segment word public 'Bios_Code'
        assume cs:Bios_Code,ds:Bios_Code
        org 2B50h
log_name        db 'C:\BOOTLOG.TXT',0
old_log_name    db 'C:\BOOTLOG.PRV',0
log_rotate      db 1
log_flags       dw 2041h
log_handle      dw -1
log_open_count  dw 0
log_state       db 2
log_level       db '0'
        org 2B90h
mult_call16 proc near
        push ds
        push cx
        push dx
        push si
        push cs
        pop ds
        mov ax,0FFFFh
        cmp log_state,1
        jz open_exit
        cmp log_state,0
        jz open_check
        mov log_level,'0'
open_check:
        mov bx,log_handle
        or bx,bx
        jns open_count
        xor al,al
        xchg al,log_rotate
        mov dl,11h
        or al,al
        jz open_file
        cmp log_level,'3'
        jc open_rotate
        mov log_state,1
        mov ax,0FFFFh
        jmp short open_exit
open_rotate:
        cmp log_level,'0'
        jnz open_drive
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
        jc open_exit
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
        org 2CF4h
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
        jnc rotate_exit
        cmp al,2
        jnz rotate_exit
        or log_flags,4000h
rotate_exit:
        pop es
        ret
rotate_bootlog endp
Bios_Code ends
        end mult_call16
