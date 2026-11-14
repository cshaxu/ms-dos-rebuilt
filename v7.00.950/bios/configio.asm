;** CONFIGIO.ASM - Configuration program DOS file services
;
; FAR C entries. Arguments begin at BP+6; caller removes arguments.
; Names describe recovered operations and are not original debug symbols.
; Preserve the target's DOS service modes and error-return conventions.
;

REGIO segment word public 'CODE'
        .386
        assume cs:REGIO
        public ConfigOpen,ConfigClose,ConfigReadAll,ConfigRead
        public ConfigWriteAll,ConfigSeek,ConfigCreate,ConfigDelete
        public ConfigRename,ConfigGetAttr

; Open: path FAR pointer, reserved DWORD, flags DWORD, status FAR pointer.
; Flag bit 0 requests write access and clearing the read-only attribute.
;
ConfigOpen proc far
        enter 0,0
        push si
        push di
        push ds
        xor si,si
        test byte ptr [bp+14],3
        jz short co_open
        lds dx,[bp+6]
        mov ax,4300h
        int 21h
        jc short co_open
        test byte ptr [bp+14],1
        jz short co_attr
        and cl,0FEh
co_attr:
        lds dx,[bp+6]
        mov ax,4301h
        int 21h
        jnc short co_open
        inc si
co_open:
        mov ax,3DA0h
        test byte ptr [bp+14],1
        jz short co_ready
        mov al,92h
co_ready:
        lds dx,[bp+6]
        int 21h
        jnc short co_status
        mov ax,-1
        mov dx,ax
co_status:
        lds bx,[bp+18]
        mov [bx],si
        pop ds
        pop di
        pop si
        leave
        ret
ConfigOpen endp

; Close: path FAR pointer, handle WORD, reserved DWORD, flags DWORD.
; Nonzero flags request commit and restore hidden/system/read-only bits.
;
ConfigClose proc far
        enter 0,0
        push ebx
        xor ax,ax
        test dword ptr [bp+12],-1
        jnz short cc_exit
        test dword ptr [bp+16],-1
        jz short cc_close
        mov ax,6800h
        movzx ebx,word ptr [bp+10]
        int 21h
cc_close:
        mov ax,3E00h
        movzx ebx,word ptr [bp+10]
        int 21h
        test dword ptr [bp+16],-1
        jz short cc_exit
        push eax
        push ds
        lds dx,[bp+6]
        mov ax,4300h
        int 21h
        jc short cc_restore
        or cx,7
        lds dx,[bp+6]
        mov ax,4301h
        int 21h
cc_restore:
        pop ds
        pop eax
cc_exit:
        pop ebx
        leave
        ret
ConfigClose endp

; ReadAll: handle WORD, buffer FAR pointer, count DWORD, reserved DWORD.
; Transfer paragraph-sized chunks across segment boundaries. Return zero
; in DX:AX on complete transfer, -1 on an error or short transfer.
;
ConfigReadAll proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        test dword ptr [bp+16],-1
        jnz short cra_reject
cra_next:
        movzx ebx,word ptr [bp+6]
        mov eax,3F00h
        mov ecx,[bp+12]
        cmp ecx,0FFFFh
        jbe short cra_count
        mov ecx,0F000h
cra_count:
        sub [bp+12],ecx
        push ds
        lds dx,[bp+8]
        push ecx
        int 21h
        pop ecx
        pop ds
        jc short cra_fail
        movzx eax,ax
        sub eax,ecx
        jnz short cra_fail
        shr cx,4
        add [bp+10],cx
        cmp dword ptr [bp+12],0
        jnz short cra_next
        xor eax,eax
        jmp short cra_exit
cra_reject:
        stc
cra_fail:
        mov eax,-1
cra_exit:
        push eax
        pop ax
        pop dx
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ConfigReadAll endp

; Read: handle WORD, buffer FAR pointer, count WORD, reserved WORD.
; Return the DOS byte count in AX, or -1 on error.
;
ConfigRead proc far
        enter 0,0
        push bx
        push si
        push di
        push ds
        push es
        mov bx,[bp+6]
        mov ax,3F00h
        cmp word ptr [bp+14],0
        jnz short cr_fail
        mov cx,[bp+12]
        lds dx,[bp+8]
        int 21h
        jc short cr_fail
cr_exit:
        pop es
        pop ds
        pop di
        pop si
        pop bx
        leave
        ret
cr_fail:
        mov ax,-1
        jmp short cr_exit
ConfigRead endp

; WriteAll uses the same arguments and result as ReadAll.
;
ConfigWriteAll proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        test dword ptr [bp+16],-1
        jnz short cwa_fail
cwa_next:
        movzx ebx,word ptr [bp+6]
        mov eax,4000h
        mov ecx,[bp+12]
        cmp ecx,0FFFFh
        jbe short cwa_count
        mov ecx,0F000h
cwa_count:
        sub [bp+12],ecx
        push ds
        lds dx,[bp+8]
        push ecx
        int 21h
        pop ecx
        pop ds
        jc short cwa_fail
        movzx eax,ax
        sub eax,ecx
        jnz short cwa_fail
        shr cx,4
        add [bp+10],cx
        cmp dword ptr [bp+12],0
        jnz short cwa_next
        xor eax,eax
        jmp short cwa_exit
cwa_fail:
        mov eax,-1
cwa_exit:
        push eax
        pop ax
        pop dx
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ConfigWriteAll endp

; Seek: handle WORD, displacement DWORD, origin DWORD, reserved DWORD.
;
ConfigSeek proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        movzx ebx,word ptr [bp+6]
        mov eax,[bp+12]
        mov ecx,[bp+8]
        test dword ptr [bp+16],-1
        jnz short cs_exit
        mov ah,42h
        movzx edx,cx
        shr ecx,16
        int 21h
cs_exit:
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ConfigSeek endp

; Create/Delete/GetAttr: path FAR pointer and reserved DWORD.
;
ConfigCreate proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        test dword ptr [bp+10],-1
        jnz short ccr_fail
        push ds
        lds dx,[bp+6]
        mov ax,3C00h
        mov cx,6
        int 21h
        pop ds
        movzx eax,ax
        jc short ccr_fail
        movzx eax,ax
ccr_exit:
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ccr_fail:
        mov eax,-1
        jmp short ccr_exit
ConfigCreate endp

ConfigDelete proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        test dword ptr [bp+10],-1
        jnz short cd_exit
        lds dx,[bp+6]
        mov ax,4300h
        int 21h
        jc short cd_exit
        and cx,-8
        lds dx,[bp+6]
        mov ax,4301h
        int 21h
        lds dx,[bp+6]
        mov ax,4100h
        int 21h
cd_exit:
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ConfigDelete endp

; Rename: old/new FAR path pointers, reserved DWORD. The original
; register-save and error paths are retained without behavioral changes.
;
ConfigRename proc far
        enter 0,0
        push si
        push di
        push ds
        push bx
        xor eax,eax
        test dword ptr [bp+14],-1
        jnz short cn_exit
        push ds
        push es
        push di
        lds dx,[bp+6]
        mov ax,4300h
        int 21h
        jc short cn_rename
        and cx,-8
        lds dx,[bp+6]
        mov ax,4301h
        int 21h
cn_rename:
        lds dx,[bp+6]
        les di,[bp+10]
        mov ax,5600h
        int 21h
        mov eax,0
        jc short cn_exit
        lds dx,[bp+10]
        mov ax,4300h
        int 21h
        jc short cn_restore
        or cx,7
        lds dx,[bp+10]
        mov ax,4301h
        int 21h
cn_restore:
        pop di
        pop es
        pop ds
        mov eax,-1
cn_exit:
        pop bx
        pop ds
        pop di
        pop si
        leave
        ret
ConfigRename endp

ConfigGetAttr proc far
        enter 0,0
        test dword ptr [bp+10],-1
        jnz short cg_fail
        push ds
        lds dx,[bp+6]
        mov ax,4300h
        int 21h
        pop ds
        jc short cg_fail
        mov ax,cx
        or ax,8000h
        jmp short cg_exit
cg_fail:
        xor eax,eax
cg_exit:
        push eax
        pop ax
        pop dx
        leave
        ret
ConfigGetAttr endp

REGIO ends
        end
