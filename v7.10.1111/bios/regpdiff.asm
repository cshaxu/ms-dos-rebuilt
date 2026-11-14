;** REGPDIFF.ASM - Two FAR pointers. Return linear byte difference; callee removes arguments.
;
; FAR C entry: Two FAR pointers. Return linear byte difference; callee removes arguments.
; Uses the completed record storage and value access routines.
; Local instruction flow follows the target; final layout is linked.
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
