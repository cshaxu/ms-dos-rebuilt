;** REGSTR.ASM - Registry path and string primitives
;
; FAR C entries operate on FAR strings without external dependencies.
; Preserve the target's ASCII folding, length limits and count semantics.
;
REGSTR segment word public 'CODE'
        assume cs:REGSTR
        public RegPathPart,RegCopyPart,RegCompareN,RegStringLength
        public RegCopyBytes,RegAppendBytes,RegUpperCopy,RegNameSum

; Source, destination. Return pointer to separator/terminator, or -1
; for controls, doubled separators or a component of 256 characters.
;
RegPathPart proc far
        push bp
        mov bp,sp
        sub sp,4
        mov word ptr [bp-4],0
        jmp short rp_test
rp_char:
        cmp al,5Ch
        jnz short rp_check
        cmp es:[bx+1],al
        jnz short rp_done
rp_bad:
        mov ax,-1
        cwd
        jmp short rp_exit
rp_check:
        cmp byte ptr [bp-2],20h
        jc short rp_bad
        cmp byte ptr [bp-2],'a'
        jc short rp_plain
        cmp byte ptr [bp-2],'z'
        ja short rp_plain
        mov al,[bp-2]
        sub al,20h
        jmp short rp_store
rp_plain:
        mov al,[bp-2]
rp_store:
        les bx,[bp+10]
        inc word ptr [bp+10]
        mov es:[bx],al
        inc word ptr [bp+6]
        inc word ptr [bp-4]
        cmp word ptr [bp-4],100h
        jge short rp_bad
rp_test:
        les bx,[bp+6]
        mov al,es:[bx]
        mov [bp-2],al
        or al,al
        jnz short rp_char
rp_done:
        les bx,[bp+10]
        mov byte ptr es:[bx],0
        mov ax,[bp+6]
        mov dx,[bp+8]
rp_exit:
        mov sp,bp
        pop bp
        ret
RegPathPart endp
        even

RegCopyPart proc far
        push bp
        mov bp,sp
        sub sp,2
        jmp short rcp_test
rcp_char:
        cmp al,5Ch
        jz short rcp_done
        mov al,[bp-2]
        les bx,[bp+10]
        inc word ptr [bp+10]
        mov es:[bx],al
rcp_test:
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov al,es:[bx]
        mov [bp-2],al
        or al,al
        jnz short rcp_char
rcp_done:
        les bx,[bp+10]
        mov sp,bp
        mov byte ptr es:[bx],0
        pop bp
        ret
RegCopyPart endp
        even

; Compare count characters after ASCII folding. Return second minus
; first at the last compared byte, preserving the original convention.
;
RegCompareN proc far
        push bp
        mov bp,sp
        sub sp,4
rcn_loop:
        les bx,[bp+6]
        cmp byte ptr es:[bx],'a'
        jl short rcn_first
        cmp byte ptr es:[bx],'z'
        jg short rcn_first
        mov al,es:[bx]
        cbw
        sub ax,20h
        jmp short rcn_first_save
rcn_first:
        mov al,es:[bx]
        cbw
rcn_first_save:
        mov [bp-2],ax
        les bx,[bp+10]
        cmp byte ptr es:[bx],'a'
        jl short rcn_second
        cmp byte ptr es:[bx],'z'
        jg short rcn_second
        mov al,es:[bx]
        cbw
        sub ax,20h
        jmp short rcn_second_save
rcn_second:
        mov al,es:[bx]
        cbw
rcn_second_save:
        mov [bp-4],ax
        mov al,[bp-4]
        cmp [bp-2],al
        jnz short rcn_result
        dec word ptr [bp+14]
        jnz short rcn_next
rcn_result:
        cmp byte ptr es:[bx],'a'
        jl short rcn_raw_second
        cmp byte ptr es:[bx],'z'
        jg short rcn_raw_second
        mov al,es:[bx]
        cbw
        sub ax,20h
        jmp short rcn_save_second
rcn_next:
        inc word ptr [bp+6]
        inc word ptr [bp+10]
        jmp short rcn_loop
rcn_raw_second:
        mov al,es:[bx]
        cbw
rcn_save_second:
        mov [bp-4],ax
        les bx,[bp+6]
        cmp byte ptr es:[bx],'a'
        jl short rcn_raw_first
        cmp byte ptr es:[bx],'z'
        jg short rcn_raw_first
        mov al,es:[bx]
        cbw
        sub ax,20h
        jmp short rcn_save_first
rcn_raw_first:
        mov al,es:[bx]
        cbw
rcn_save_first:
        mov [bp-2],ax
        mov al,[bp-4]
        sub ah,ah
        mov cl,[bp-2]
        sub ch,ch
        sub ax,cx
        mov sp,bp
        pop bp
        ret
RegCompareN endp

RegStringLength proc far
        push bp
        mov bp,sp
        sub sp,6
        mov word ptr [bp-2],0
        jmp short rsl_test
rsl_next:
        inc word ptr [bp-2]
rsl_test:
        les bx,[bp+6]
        inc word ptr [bp+6]
        cmp byte ptr es:[bx],0
        jnz short rsl_next
        mov ax,[bp-2]
        mov sp,bp
        pop bp
        ret
RegStringLength endp
        even

; Copy/append take destination, source and DWORD byte count. They copy
; exactly that count, with no extra terminator or segment adjustment.
;
RegCopyBytes proc far
        push bp
        mov bp,sp
        sub sp,4
rcb_count:
        mov ax,[bp+14]
        mov dx,[bp+16]
        sub word ptr [bp+14],1
        sbb word ptr [bp+16],0
        or dx,ax
        jz short rcb_exit
        les bx,[bp+10]
        inc word ptr [bp+10]
        mov al,es:[bx]
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov es:[bx],al
        jmp short rcb_count
rcb_exit:
        mov sp,bp
        pop bp
        ret
RegCopyBytes endp

RegAppendBytes proc far
        push bp
        mov bp,sp
        sub sp,4
        jmp short rab_end
rab_next:
        inc word ptr [bp+6]
rab_end:
        les bx,[bp+6]
        cmp byte ptr es:[bx],0
        jnz short rab_next
rab_count:
        mov ax,[bp+14]
        mov dx,[bp+16]
        sub word ptr [bp+14],1
        sbb word ptr [bp+16],0
        or dx,ax
        jz short rab_exit
        les bx,[bp+10]
        inc word ptr [bp+10]
        mov al,es:[bx]
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov es:[bx],al
        jmp short rab_count
rab_exit:
        mov sp,bp
        pop bp
        ret
RegAppendBytes endp

; UpperCopy takes source then destination and includes the terminator.
;
RegUpperCopy proc far
        push bp
        mov bp,sp
        sub sp,4
ruc_loop:
        mov ax,[bp+10]
        mov dx,[bp+12]
        inc word ptr [bp+10]
        mov [bp-4],ax
        mov [bp-2],dx
        les bx,[bp+6]
        cmp byte ptr es:[bx],'a'
        jl short ruc_plain
        cmp byte ptr es:[bx],'z'
        jg short ruc_plain
        mov al,es:[bx]
        sub al,20h
        jmp short ruc_store
ruc_plain:
        mov al,es:[bx]
ruc_store:
        les bx,[bp-4]
        mov es:[bx],al
        or al,al
        jz short ruc_exit
        inc word ptr [bp+6]
        jmp short ruc_loop
ruc_exit:
        mov sp,bp
        pop bp
        ret
RegUpperCopy endp
        even

; Sum folded ASCII characters into DX:AX; ignore bytes >= 80h.
;
RegNameSum proc far
        push bp
        mov bp,sp
        sub sp,6
        sub ax,ax
        mov [bp-2],ax
        mov [bp-4],ax
        jmp short rns_test
rns_char:
        cmp al,80h
        jnc short rns_test
        cmp al,'a'
        jc short rns_plain
        cmp al,'z'
        ja short rns_plain
        sub ah,ah
        sub ax,20h
        cwd
        jmp short rns_add
rns_plain:
        mov al,[bp-6]
        sub ah,ah
        sub dx,dx
rns_add:
        add [bp-4],ax
        adc [bp-2],dx
rns_test:
        les bx,[bp+6]
        inc word ptr [bp+6]
        mov al,es:[bx]
        mov [bp-6],al
        or al,al
        jnz short rns_char
        mov ax,[bp-4]
        mov dx,[bp-2]
        mov sp,bp
        pop bp
        ret
RegNameSum endp
        even
REGSTR ends
        end
