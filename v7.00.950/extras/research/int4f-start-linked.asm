Bios_Data segment at 70h
 org 11ah
BiosOld4F dd 0
 org 178h
int4f_old dd 0
 org 465h
intret db 0
 org 4fch
int4f_entry db 0
Bios_Data ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:Bios_Data
 org 10d3h
        mov     cx,word ptr [BiosOld4F]
        mov     ax,word ptr [BiosOld4F+2]
        mov     word ptr [int4f_old],cx
        mov     word ptr [int4f_old+2],ax
        mov     si,offset int4f_entry
        or      ax,cx
        jnz     short int4f_vector_ready
        mov     si,offset intret
int4f_vector_ready:
        xor     ax,ax
        mov     es,ax
        cli
        mov     word ptr es:[4fh*4],si
        mov     word ptr es:[4fh*4+2],ds
        sti
sysinitseg ends
end
