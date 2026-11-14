sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 4287h
boot_emm_name db 'EMMXXXX0',0
boot_qmm_name db 'QMMXXXX0',0
 org 4ac0h
; Check UMB support and installed expanded-memory managers.
boot_check_umb_manager proc near
        cmp     byte ptr [DevUMB],0
        je      boot_umb_done
        push    ds
        xor     ax,ax
        mov     ds,ax
        assume  ds:nothing
        mov     ax,word ptr ds:[019eh]
        cmp     ax,1
        jb      boot_umb_restore_ds
        mov     ds,ax
        cmp     word ptr ds:[0bh],'MM'
        jne     boot_umb_restore_ds
        cmp     word ptr ds:[0eh],'XX'
boot_umb_restore_ds:
        pop     ds
        assume  ds:sysinitseg
        je      boot_umb_found
        mov     dx,offset boot_emm_name
        call    boot_check_device
        je      boot_umb_found
        mov     dx,offset boot_qmm_name
        call    boot_check_device
        je      boot_umb_found
        sub     ax,ax
        jmp     short boot_umb_done
boot_umb_found:
        call    boot_double_provider
boot_umb_done:
        ret
boot_check_umb_manager endp
 org 4bd6h
boot_double_provider proc near
 ret
boot_double_provider endp
 org 4c16h
boot_check_device proc near
 ret
boot_check_device endp
 org 66dfh
DevUMB db 0
sysinitseg ends
end
