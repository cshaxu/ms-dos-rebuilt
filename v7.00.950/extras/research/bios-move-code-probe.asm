; Move BIOS code into the requested segment.
SYSINITSEG SEGMENT
ASSUME CS:SYSINITSEG,DS:NOTHING,ES:NOTHING
        ORG 01924h
MovBIOS PROC NEAR
        mov     ds,word ptr cs:[0F40h]
        mov     si,30h
        mov     di,si
        mov     cx,2DA0h
        add     cx,word ptr cs:[0FF7h]
        sub     cx,si
        shr     cx,1
        rep     movsw
        mov     ax,es
        call    ReinitBios
        ret
MovBIOS ENDP
        ORG 01BEDh
ReinitBios:
        ret
SYSINITSEG ENDS
END
