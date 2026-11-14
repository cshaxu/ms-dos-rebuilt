pdb_jfn_pointer equ 34h
set_current_pdb equ 50h
set_dma equ 1ah
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0ff5h
new_psp_segment dw 0
 org 13f8h
	mov	word ptr es:[pdb_jfn_pointer + 2],es ; relocate
        mov     cs:[new_psp_segment],bx
        mov     ah,set_current_pdb
        int     21h
        mov     ds,bx
        mov     dx,80h
        mov     ah,set_dma
        int     21h
        push    cs
        pop     ds
        mov     dx,offset int24
        mov     ax,2524h
        int     21h
 org 3246h
int24 proc near
 ret
int24 endp
sysinitseg ends
end
