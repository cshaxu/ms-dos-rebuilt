Bios_Code segment at 1d5h
 org 30h
BCode_start label byte
 org 2da0h
BCode_end label byte
Bios_Code ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 0f07h
temp_bcode_seg dw 0
 org 0f40h
BCodeSeg dw 1d5h
 org 0ff7h
bios_extra_bytes dw 0
 org 1041h
        assume  ds:sysinitseg
        mov     ax,Bios_Code
        mov     es,ax
        assume  es:Bios_Code
        mov     ax,word ptr es:[BCode_end+6]
        add     ax,1fh
        and     ax,0fff0h
        mov     [bios_extra_bytes],ax
        add     ax,offset BCode_end
        .286
        shr     ax,4
        .8086
        sub     cx,ax
        assume  ds:nothing,es:nothing
 org 113dh
        mov     es,ax
        mov     ds,cs:[BCodeSeg]
        assume  ds:nothing
        mov     si,offset BCode_start
        mov     di,si
        mov     cx,offset BCode_end
        add     cx,cs:[bios_extra_bytes]
        sub     cx,si
        shr     cx,1
        rep     movsw
        mov     cs:[temp_bcode_seg],ax
        call    reinit_bios_code
 org 1bedh
reinit_bios_code proc near
 ret
reinit_bios_code endp
sysinitseg ends
end
