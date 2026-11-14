sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 6732h
; State used while recording device and interrupt-vector changes.
config_record_ptr       dd      0
config_record_count     dw      0
config_record_name      db      'IO      SYS'
config_record_flags     dw      0
                        db      0
config_record_vectors   label   byte
        irp     aa,<1,2,3,4,5,6,7,8,9>
        db      aa
        dw      -1,-1
        endm
        db      10
        dw      0,0


 org 87d5h
; Copy a changed vector into the current device record.
config_record_item proc near
        push    si
        lea     si,[si+0eh]
        mov     ah,5
        dec     al
        mul     ah
        add     si,ax
        cmp     cs:[si+1],bx
        jne     config_record_changed
        cmp     cs:[si+3],dx
        je      config_record_done
config_record_changed:
        mov     cs:[si+1],bx
        mov     cs:[si+3],dx
        movs    byte ptr es:[di],byte ptr cs:[si]
        movs    word ptr es:[di],word ptr cs:[si]
        movs    word ptr es:[di],word ptr cs:[si]
        inc     cx
config_record_done:
        pop     si
        ret
config_record_item endp

sysinitseg ends
end
