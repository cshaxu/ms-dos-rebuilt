;** REGPDIFF - Linear difference between two far pointers
;
; ENTRY: [BP+6] = first FAR pointer, [BP+0Ah] = second FAR pointer.
; EXIT:  DX:AX = signed byte difference (first minus second).
;        Callee removes both pointers from the stack.
;
_DATA segment word public 'DATA'
; No private initialized data.
_DATA ends
DGROUP group _DATA
_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP
        public RegPointerDifference

RegPointerDifference proc far
        push bp
        mov bp,sp
        mov ax,[bp+08h]
        sub ax,[bp+0Ch]
        sbb dx,dx
        add ax,ax
        adc dx,dx
        add ax,ax
        adc dx,dx
        add ax,ax
        adc dx,dx
        add ax,ax
        adc dx,dx
        add ax,[bp+06h]
        adc dx,00h
        sub ax,[bp+0Ah]
        sbb dx,00h
        pop bp
        ret 8
RegPointerDifference endp
_TEXT ends
        end
