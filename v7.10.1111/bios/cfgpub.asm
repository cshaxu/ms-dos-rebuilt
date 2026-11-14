;** CFGPUB.ASM - Publish configuration profile data.
;
; FAR C entry; no arguments. Request a buffer through CONFIG$ and fill
; its header, profile data and linked configuration records.
;
        extrn ConfigIOWrite:far
        extrn __close:far
        extrn __open:far
_DATA segment word public 'DATA'
        extrn ConfigInfoSize:word
        extrn ConfigRecordHead:dword
        extrn ConfigRecordCount:word
        extrn ConfigDeviceName:byte
_DATA ends
c_common segment word public 'BSS'
        extrn ConfigInfoData:dword
c_common ends
DGROUP group _DATA,c_common
CFGPUB segment word public 'CODE'
        assume cs:CFGPUB,ds:DGROUP
        public ConfigPublishData

ConfigPublishData proc far
        push bp
        mov bp,sp
        sub sp,010h
        push di
        push si
        sub ax,ax
        mov [bp-0Eh],ax
        mov [bp-010h],ax
        mov word ptr [bp-0Ch],013Ch
        mov ax,0F0h
        mul word ptr ConfigRecordCount
        mov si,ax
        add si,014Bh
        and si,0FFF0h
        mov ax,08002h
        push ax
        mov ax,offset DGROUP:ConfigDeviceName
        push ds
        push ax
        call __open
        add sp,06h
        mov [bp-02h],ax
        inc ax
        jnz short pub_loc_03F
        jmp pub_loc_13C
pub_loc_03F:
        push si
        lea ax,[bp-010h]
        push ss
        push ax
        push word ptr [bp-02h]
        call ConfigIOWrite
        add sp,08h
        or ax,ax
        jz short pub_loc_066
        push word ptr [bp-02h]
        call __close
        add sp,02h
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
        nop
pub_loc_066:
        mov [bp-06h],si
        push word ptr [bp-02h]
        call __close
        add sp,02h
        mov ax,[bp-0Eh]
        or ax,[bp-010h]
        jnz short pub_loc_07F
        jmp pub_loc_13C
pub_loc_07F:
        les bx,[bp-010h]
        mov word ptr es:[bx],05744h
        mov word ptr es:[bx+02h],04D43h
        mov ax,ConfigRecordCount
        les bx,[bp-010h]
        mov es:[bx+04h],ax
        mov word ptr es:[bx+06h],00h
        mov ax,[bp-06h]
        les bx,[bp-010h]
        mov es:[bx+08h],ax
        mov word ptr es:[bx+0Ah],00h
        les bx,[bp-010h]
        sub ax,ax
        mov es:[bx+0Eh],ax
        mov es:[bx+0Ch],ax
        les bx,[bp-010h]
        mov ax,word ptr ConfigInfoData
        mov dx,word ptr ConfigInfoData+2
        mov cx,ConfigInfoSize
        push ds
        lea di,[bx+010h]
        mov si,ax
        mov ds,dx
        shr cx,1
        rep movsw
        adc cx,cx
        rep movsb
        pop ds
        mov ax,word ptr ConfigRecordHead
        mov dx,word ptr ConfigRecordHead+2
        mov [bp-04h],ax
        mov [bp-02h],dx
        mov ax,ConfigRecordCount
        mov [bp-0Ah],ax
        or ax,ax
        jz short pub_loc_13C
pub_loc_0F0:
        mov ax,word ptr ConfigRecordHead+2
        or ax,word ptr ConfigRecordHead
        jz short pub_loc_13C
        mov ax,[bp-0Ch]
        sub dx,dx
        add ax,[bp-010h]
        adc dx,[bp-0Eh]
        mov [bp-08h],ax
        mov [bp-06h],dx
        mov bx,[bp-04h]
        mov si,[bp-02h]
        add bx,04h
        push ds
        push si
        mov di,ax
        mov si,bx
        mov es,dx
        pop ds
        mov cx,078h
        rep movsw
        pop ds
        add word ptr [bp-0Ch],0F0h
        les bx,[bp-04h]
        mov ax,es:[bx]
        mov dx,es:[bx+02h]
        mov [bp-04h],ax
        mov [bp-02h],dx
        dec word ptr [bp-0Ah]
        jnz short pub_loc_0F0
pub_loc_13C:
        pop si
        pop di
        mov sp,bp
        pop bp
        ret
ConfigPublishData endp
CFGPUB ends
        end
