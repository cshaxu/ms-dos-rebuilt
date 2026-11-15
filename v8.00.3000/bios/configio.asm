;** CONFIGIO.ASM - Configuration program DOS file services
;
; FAR C entries. Arguments begin at BP+6; caller removes arguments.
; Registry NEAR entries begin at BP+4 and remove their arguments.
;
	.386
_DATA segment word public use16 'RESUME_DATA'
_DATA ends
DGROUP group _DATA
SysResume segment byte public use16 'RESUME_CODE'
SysResume ends
_TEXT segment word public use16 'RESUME_CODE'
CGROUP group SysResume,_TEXT
	assume cs:CGROUP,ds:DGROUP
	public RegDosCreate
RegDosCreate proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds si,[bp+4]
        mov bx,1
        xor cx,cx
        mov dx,12h
        mov ah,6Ch
        int 21h
        jnc short rdc_done
        mov ax,-1
rdc_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 4
RegDosCreate endp
	public RegDosOpen
RegDosOpen proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds dx,[bp+6]
        mov ax,[bp+4]
        mov ah,3Dh
        int 21h
        jnc short rdo_done
        mov ax,-1
rdo_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 6
RegDosOpen endp
	public RegDosWrite
RegDosWrite proc near
        mov ah,40h
        jmp short rdr_common
RegDosWrite endp
	public RegDosRead
RegDosRead proc near
        mov ah,3Fh
rdr_common:
        push bp
        mov bp,sp
        push ds
        push si
        push di
        mov bx,[bp+10]
        mov cx,[bp+4]
        lds dx,[bp+6]
        int 21h
        jc short rdr_error
        cmp ax,[bp+4]
        jz short rdr_done
rdr_error:
        xor ax,ax
rdr_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 8
RegDosRead endp
	public RegDosSeek
RegDosSeek proc near
        push bp
        mov bp,sp
        push si
        push di
        mov bx,[bp+8]
        mov dx,[bp+4]
        mov cx,[bp+6]
        mov ax,4200h
        int 21h
        jc short rds_error
        cmp ax,[bp+4]
        jnz short rds_error
        cmp dx,[bp+6]
        jnz short rds_error
        mov ax,1
        jmp short rds_done
rds_error:
        xor ax,ax
rds_done:
        pop di
        pop si
        pop bp
        ret 6
RegDosSeek endp
; Commit pending registry file writes through DOS.
	public RegDosCommit
RegDosCommit proc near
        push bp
        mov bp,sp
        push si
        push di
        mov bx,[bp+4]
        mov ah,68h
        int 21h
        cmc
        sbb ax,ax
        pop di
        pop si
        pop bp
        ret 2
RegDosCommit endp
	public RegDosClose
RegDosClose proc near
        push bp
        mov bp,sp
        push si
        push di
        mov bx,[bp+4]
        mov ah,3Eh
        int 21h
        pop di
        pop si
        pop bp
        ret 2
RegDosClose endp
        db 0                    ; Align the memory helpers.
	public RegMoveMemory
RegMoveMemory proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds si,[bp+6]
        les di,[bp+10]
        mov cx,[bp+4]
        mov ax,ds
        cmp ax,[bp+12]
        jnz short rmm_forward
        cmp si,di
        jnc short rmm_forward
        mov ax,si
        add ax,cx
        cmp ax,di
        jc short rmm_forward
        add si,cx
        sub si,4
        add di,cx
        sub di,4
        std
        mov dx,cx
        shr cx,2
        rep movsd
        mov cx,dx
        and cx,3
        add si,3
        add di,3
        rep movsb
        cld
        jmp short rmm_done
rmm_forward:
        cld
        push cx
        shr cx,2
        rep movsd
        pop cx
        and cx,3
        rep movsb
rmm_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 10
RegMoveMemory endp
	public RegZeroMemory
RegZeroMemory proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        les di,[bp+6]
        mov cx,[bp+4]
        cld
        xor eax,eax
        mov dx,cx
        shr cx,2
        rep stosd
        mov cx,dx
        and cx,3
        rep stosb
        pop di
        pop si
        pop ds
        pop bp
        ret 6
RegZeroMemory endp
	public RegDosAlloc
RegDosAlloc proc near
        push bp
        mov bp,sp
        push si
        push di
        mov bx,[bp+4]
        add bx,15
        jnc short rda_paragraphs
        mov bx,1000h
        jmp short rda_allocate
rda_paragraphs:
        shr bx,4
rda_allocate:
        mov ah,48h
        int 21h
        jnc short rda_done
rda_error:
        xor ax,ax
rda_done:
        mov dx,ax
        xor ax,ax
        pop di
        pop si
        pop bp
        ret 2
RegDosAlloc endp
	public RegDosFree
RegDosFree proc near
        push bp
        mov bp,sp
        push si
        push di
        mov es,word ptr [bp+6]
        mov ah,49h
        int 21h
        pop di
        pop si
        pop bp
        ret 4
RegDosFree endp
	public RegDosRealloc
RegDosRealloc proc near
        push bp
        mov bp,sp
        push si
        push di
        xor dx,dx
        mov bx,[bp+4]
        add bx,15
        jo short rdra_result
        shr bx,4
        mov es,word ptr [bp+8]
        push es
        mov ah,4Ah
        int 21h
        pop dx
        jnc short rdra_result
        mov si,dx
        push word ptr [bp+4]
        call RegDosAlloc
        or dx,dx
        jz short rdra_done
        push dx
        xor di,di
        dec si
        mov es,si
        inc si
        mov cx,es:[3]
        shl cx,4
        push dx
        push di
        push si
        push di
        push cx
        call RegMoveMemory
        push si
        push di
        call RegDosFree
        pop dx
rdra_result:
        xor ax,ax
rdra_done:
        pop di
        pop si
        pop bp
        ret 6
RegDosRealloc endp
        db 0                    ; Align the attribute helpers.
	public RegDosGetAttr
RegDosGetAttr proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds dx,[bp+4]
        mov ax,4300h
        int 21h
        jc short rdga_error
        mov ax,cx
        xor dx,dx
rdga_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 4
rdga_error:
        mov ax,-1
        mov dx,ax
        jmp short rdga_done
RegDosGetAttr endp
	public RegDosSetAttr
RegDosSetAttr proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        mov cx,[bp+4]
        lds dx,[bp+6]
        mov ax,4301h
        int 21h
        cmc
        sbb ax,ax
        pop di
        pop si
        pop ds
        pop bp
        ret 6
RegDosSetAttr endp
	public RegDosDelete
RegDosDelete proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds dx,[bp+4]
        mov ah,41h
        int 21h
        cmc
        sbb ax,ax
        pop di
        pop si
        pop ds
        pop bp
        ret 4
RegDosDelete endp
	public RegDosRename
RegDosRename proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        lds dx,[bp+8]
        les di,[bp+4]
        mov ah,56h
        int 21h
        cmc
        sbb ax,ax
        pop di
        pop si
        pop ds
        pop bp
        ret 8
RegDosRename endp
	public RegDosTempFile
RegDosTempFile proc near
        push bp
        mov bp,sp
        push ds
        push si
        push di
        xor cx,cx
        lds dx,[bp+4]
        mov ah,5Ah
        int 21h
        jnc short rdt_done
        mov ax,-1
rdt_done:
        pop di
        pop si
        pop ds
        pop bp
        ret 4
RegDosTempFile endp
_TEXT ends
	end
