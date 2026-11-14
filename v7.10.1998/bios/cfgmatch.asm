;** CFGMATCH.ASM - Collect matching configuration profile IDs.
;
; FAR C arguments: output buffer, mapping table and two DWORD identifiers.
; Stores up to nine profile IDs, their count and a multiple-match flag.
; Returns DX:AX = 0 and restores DS from SS.
;
_DATA segment word public 'DATA'
; No private data dependencies.
_DATA ends
DGROUP group _DATA
CFGPNP segment word public 'CODE'
        assume cs:CFGPNP,ds:DGROUP
        public ConfigMatchProfiles

ConfigMatchProfiles proc far
        push bp
        mov bp,sp
        sub sp,04h
        push di
        push si
        mov di,[bp+06h]
        mov bx,[bp+0Ah]
        xor ax,ax
        mov es,word ptr [bp+08h]
        mov es:[di+012h],ax
        xor cx,cx
        mov es:[di+014h],ax
        mov es,word ptr [bp+0Ch]
        cmp es:[bx],ax
        jnz short match_loc_02A
        mov ds,word ptr [bp+08h]
        jmp short match_loc_07D
match_loc_02A:
        lea ax,[bx+02h]
        mov word ptr [bp-02h],es
        mov bx,ax
        mov ds,word ptr [bp+08h]
match_loc_035:
        mov ax,[bp+0Eh]
        mov dx,[bp+010h]
        mov es,word ptr [bp-02h]
        cmp es:[bx],ax
        jnz short match_loc_071
        cmp es:[bx+02h],dx
        jnz short match_loc_071
        mov ax,[bp+012h]
        mov dx,[bp+014h]
        cmp es:[bx+04h],ax
        jnz short match_loc_071
        cmp es:[bx+06h],dx
        jnz short match_loc_071
        cmp word ptr [di+012h],09h
        jz short match_loc_07D
        mov ax,es:[bx+0Ah]
        mov si,[di+012h]
        add si,si
        add si,di
        mov [si],ax
        inc word ptr [di+012h]
match_loc_071:
        add bx,0Ch
        inc cx
        les si,[bp+0Ah]
        cmp es:[si],cx
        ja short match_loc_035
match_loc_07D:
        cmp word ptr [di+012h],00h
        jz short match_loc_093
        cmp word ptr [di+012h],01h
        jng short match_loc_08E
        mov ax,01h
        jmp short match_loc_090
match_loc_08E:
        xor ax,ax
match_loc_090:
        mov [di+014h],ax
match_loc_093:
        xor ax,ax
        cwd
        push ss
        pop ds
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigMatchProfiles endp
CFGPNP ends
        end
