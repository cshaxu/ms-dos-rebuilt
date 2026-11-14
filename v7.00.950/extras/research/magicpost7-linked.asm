multMagicdrv equ 4a11h
MD_VERSION equ 0
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 022dh
bpb_addr dd 0
 org 66d0h
DevSize dw 0
DevLoadAddr dw 0
 org 66dah
DevBrkAddr dd 0
ConvLoad db 0
 org 66efh
DeviceHi db 0
DevSizeOption dw 0
 org 8041h
InitDevLoad proc near
 ret
InitDevLoad endp
 org 8228h
DevSetBreak proc near
 ret
DevSetBreak endp
 org 824dh
DevBreak proc near
 ret
DevBreak endp
 org 8a84h
MagicDDName db 'C:\DBLSPACE.BIN',0
 org 8aa7h
compressed_dest_segment dw 0
compressed_reserved_paras dw 0
 org 8dfah
; Final placement of the compression driver, using its reserved image area.
MagicPostload proc near
        mov     ax,multMagicdrv
        mov     bx,MD_VERSION
        int     2fh
        or      ax,ax
        jz      short magic7_present
        jmp     near ptr magic7_done
magic7_present:
        test    dx,8000h
        jnz     short magic7_temporary
        jmp     near ptr magic7_done
magic7_temporary:
        mov     bx,-1
        mov     ax,multMagicdrv
        int     2fh
        cmp     ax,cs:[compressed_reserved_paras]
        ja      magic7_alloc
        mov     cx,ax
        mov     es,cs:[compressed_dest_segment]
        mov     ax,multMagicdrv
        mov     bx,-3
        int     2fh
        or      ax,ax
        jz      magic7_done
        xchg    ax,cx
magic7_alloc:
        add     ax,((offset tiny_stub_end - offset tiny_stub_start)+15)/16
        mov     cs:[DevSize],ax
        mov     byte ptr cs:[DeviceHi],0
        mov     word ptr cs:[DevSizeOption],0
        mov     byte ptr cs:[ConvLoad],1
        push    cs
        pop     ds
        mov     word ptr cs:[bpb_addr],offset MagicDDName
        mov     word ptr cs:[bpb_addr+2],cs
        call    InitDevLoad
        mov     ax,cs:[DevLoadAddr]
        add     ax,cs:[DevSize]
        mov     word ptr cs:[DevBrkAddr+2],ax
        mov     word ptr cs:[DevBrkAddr],0
        mov     es,cs:[DevLoadAddr]
        mov     si,offset tiny_stub_start
        xor     di,di
        mov     cx,offset tiny_stub_end - offset tiny_stub_start
        rep     movsb
        mov     ax,es
        add     ax,((offset tiny_stub_end - offset tiny_stub_start)+15)/16
        mov     es,ax
        mov     ax,multMagicdrv
        mov     bx,-2
        int     2fh
        call    DevSetBreak
        call    DevBreak
magic7_done:
        ret
MagicPostload endp

 org 8ee0h
tiny_stub_start db 18 dup (0)
tiny_stub_end label byte
sysinitseg ends
end
