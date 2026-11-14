sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 6820h
scsi_device_name db 'SCSIMGR$',0
scsi_device_entry dd 0
 org 87feh
config_scsi_entry proc near
        push    si
        push    di
        push    ds
        push    es
        push    cx
        lea     si,[bx+0ah]
        mov     di,offset scsi_device_name
        push    cs
        pop     es
        mov     cx,8
        repe    cmpsb
        jnz     config_scsi_fail
        push    cs
        pop     ds
        mov     dx,offset scsi_device_name
        mov     ax,3d00h
        int     21h
        jc      config_scsi_fail
        push    ax
        mov     bx,ax
        mov     dx,offset scsi_device_entry
        mov     cx,4
        mov     ax,4402h
        int     21h
        pop     bx
        mov     ah,3eh
        int     21h
        mov     bx,cs:word ptr [scsi_device_entry]
        mov     dx,cs:word ptr [scsi_device_entry+2]
        clc
        jmp     short config_scsi_done
config_scsi_fail:
        stc
config_scsi_done:
        pop     cx
        pop     es
        pop     ds
        pop     di
        pop     si
        ret
config_scsi_entry endp

sysinitseg ends
end
