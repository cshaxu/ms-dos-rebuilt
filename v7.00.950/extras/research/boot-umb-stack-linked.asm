sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 413eh
boot_device_scratch db 78 dup (0)
 org 4affh
; Check the expanded-memory manager version before placing stacks high.
boot_umb_ioctl dw 2
boot_check_umb_stack proc near
        cmp     byte ptr [DevUMB],0
        jne     boot_umb_stack_enabled
        jmp     near ptr boot_umb_stack_done
boot_umb_stack_enabled:
        cmp     byte ptr [stack_high],0
        je      boot_umb_stack_done
        push    ds
        xor     ax,ax
        mov     ds,ax
        assume  ds:nothing
        mov     ax,word ptr ds:[019eh]
        cmp     ax,1
        jb      boot_umb_stack_pop_ds
        mov     ds,ax
        mov     si,0ah
        cmp     word ptr [si+1],'MM'
        jne     boot_umb_stack_pop_ds
        cmp     word ptr [si+4],'XX'
        jne     boot_umb_stack_pop_ds
        cld
        mov     di,offset boot_device_scratch
        mov     dx,di
        mov     cx,8
        rep     movsb
        mov     al,0
        stosb
        pop     ds
        assume  ds:sysinitseg
        push    dx
        mov     dl,1
        mov     ax,3307h
        int     21h
        pop     dx
        mov     ax,3d00h
        int     21h
        jc      boot_umb_stack_no_file
        xchg    ax,bx
        mov     ax,4400h
        int     21h
        jc      boot_umb_stack_close
        test    dx,80h
        jz      boot_umb_stack_close
        test    dx,4000h
        jz      boot_umb_stack_close
        mov     dx,offset boot_umb_ioctl
        mov     cx,2
        mov     ax,4402h
        int     21h
        jc      boot_umb_stack_close
        cmp     ax,cx
        jne     boot_umb_stack_close
        mov     si,dx
        mov     ax,[si]
        xchg    al,ah
        cmp     ax,043ch
        jae     boot_umb_stack_close
        mov     byte ptr [stack_high],0
boot_umb_stack_close:
        mov     ax,3e00h
        int     21h
boot_umb_stack_no_file:
        jmp     short boot_umb_stack_done
boot_umb_stack_pop_ds:
        pop     ds
        assume  ds:sysinitseg
boot_umb_stack_done:
        ret
boot_check_umb_stack endp

boot_umb_rom_id db 'IBM ThinkPad 510'

; Disable high stacks for the affected system ROM.
boot_check_umb_rom proc near
        cmp     byte ptr [DevUMB],0
        je      boot_umb_rom_done
        cmp     byte ptr [stack_high],0
        je      boot_umb_rom_done
        cld
        push    es
        mov     di,0f000h
        mov     es,di
        mov     di,0b000h
        mov     al,[boot_umb_rom_id]
        mov     cx,1000h
boot_umb_rom_search:
        repne   scasb
        jcxz    boot_umb_rom_restore
        push    cx
        push    di
        mov     cx,15
        mov     si,offset boot_umb_rom_id+1
        repe    cmpsb
        pop     di
        pop     cx
        jne     boot_umb_rom_search
        mov     byte ptr [stack_high],0
boot_umb_rom_restore:
        pop     es
boot_umb_rom_done:
        ret
boot_check_umb_rom endp
 org 65ach
stack_high db 0
 org 66dfh
DevUMB db 0
sysinitseg ends
end
