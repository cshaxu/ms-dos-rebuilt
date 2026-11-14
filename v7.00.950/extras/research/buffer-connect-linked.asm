sysi_buffers equ 3fh
sysi_buf equ 12h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 0eebh
dosinfo dd 0
 org 0f19h
h_buffers dw 0
 org 3881h
 lds bx,cs:dosinfo
 mov word ptr ds:[bx+sysi_buffers],cx
 mov ax,cs:[h_buffers]
 mov word ptr ds:[bx+sysi_buffers+2],ax
 lds bx,ds:[bx+sysi_buf]
sysinitseg ends
end
