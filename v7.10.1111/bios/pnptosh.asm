;** PNPTOSH.ASM - Query Toshiba firmware capabilities.
;
; FAR C entry; no arguments. Select the configuration ports by model.
; Return the probe result in AX: 7FFFh if not Toshiba, 0 if the model
; is unsupported, otherwise 1 or 2.
;
        extrn _strncmp:far
_DATA segment word public 'DATA'
        extrn PnPToshibaName:byte
_DATA ends
DGROUP group _DATA
PNPTOSH segment word public 'CODE'
        assume cs:PNPTOSH,ds:DGROUP
        public ConfigProbeToshiba,PnPToshCases
        public tosh_0EBA
        public tosh_0EC2
        public tosh_0ECA
        public tosh_0F1A
ConfigProbeToshiba proc far
        push bp
        mov bp,sp
        sub sp,04h
        xor ax,ax
        mov [bp-02h],ax
        mov [bp-04h],ax
        mov ax,07h
        push ax
        mov ax,offset DGROUP:PnPToshibaName
        push ds
        push ax
        mov ax,0E010h
        mov dx,0F000h
        push dx
        push ax
        call _strncmp
        add sp,0Ah
        or ax,ax
        jz short tosh_0EA8
        mov ax,07FFFh
        mov sp,bp
        pop bp
        ret
tosh_0EA8:
        mov bx,0FFFFh
        mov es,bx
        mov bx,0Ah
        sub ah,ah
; MOV AL,ES:[000Ah], retain compiler ModR/M form (MASM selects A0).
        db 26h,8Ah,06h
        dw 000Ah
        jmp short tosh_0EDA
        nop
tosh_0EBA:
        mov word ptr [bp-02h],02h
        jmp short tosh_0F34
        nop
tosh_0EC2:
        mov word ptr [bp-02h],03h
        jmp short tosh_0F34
        nop
tosh_0ECA:
        mov word ptr [bp-02h],04h
        jmp short tosh_0F34
        nop
tosh_0ED2:
        mov word ptr [bp-02h],080h
        jmp short tosh_0F34
        nop
tosh_0EDA:
        cmp ax,045h
        jz short tosh_0ECA
        jg short tosh_0F06
        sub ax,038h
        cmp ax,09h
        ja short tosh_0F1A
        add ax,ax
        xchg ax,bx
        jmp word ptr cs:PnPToshCases[bx]
        nop
PnPToshCases label word
        dw offset tosh_0EBA
        dw offset tosh_0ECA
        dw offset tosh_0F1A
        dw offset tosh_0F1A
        dw offset tosh_0EBA
        dw offset tosh_0F1A
        dw offset tosh_0EC2
        dw offset tosh_0F1A
        dw offset tosh_0ECA
        dw offset tosh_0ECA
tosh_0F06:
        cmp ax,097h
        jz short tosh_0ECA
        jg short tosh_0F20
        sub ax,05Fh
        jz short tosh_0ECA
        sub ax,01Fh
        jl short tosh_0F1A
        dec ax
        jng short tosh_0ECA
tosh_0F1A:
        xor ax,ax
        mov sp,bp
        pop bp
        ret
tosh_0F20:
        sub ax,099h
        jz short tosh_0ECA
        dec ax
        dec ax
        jz short tosh_0ECA
        sub ax,03h
        jl short tosh_0F1A
        dec ax
        jng short tosh_0ED2
        jmp short tosh_0F1A
        nop
tosh_0F34:
        cli
        mov ax,[bp-02h]
        cmp ax,080h
        jnz short tosh_0F40
        jmp near ptr tosh_0FCC
tosh_0F40:
        jna short tosh_0F45
        jmp near ptr tosh_0FDA
tosh_0F45:
        sub al,02h
        jz short tosh_0F54
        dec al
        jz short tosh_0F6C
        dec al
        jz short tosh_0FA0
        jmp near ptr tosh_0FDA
tosh_0F54:
        mov ax,0FFh
        out 0EEh,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F5C:
        in al,0EEh
        and al,088h
tosh_0F60:
        cmp al,01h
        sbb ax,ax
        neg ax
tosh_0F66:
        mov [bp-04h],ax
        jmp short tosh_0FDE
        nop
tosh_0F6C:
        mov ax,0C1h
        out 0E4h,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F74:
        mov ax,0FFh
        out 0E5h,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F7C:
        in al,0E5h
        cmp al,0DBh
        jnz short tosh_0FAE
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F85:
        mov ax,0C2h
        out 0E4h,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F8D:
        mov ax,0FFh
        out 0E5h,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0F95:
        in al,0E5h
        cmp al,024h
        jz short tosh_0FC7
tosh_0F9B:
        xor ax,ax
        jmp short tosh_0F66
        nop
tosh_0FA0:
        mov ax,094h
        out 0EEh,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0FA8:
        in al,0EFh
        cmp al,0DBh
        jz short tosh_0FB6
tosh_0FAE:
        mov word ptr [bp-04h],00h
        jmp short tosh_0FDE
        nop
tosh_0FB6:
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0FB9:
        mov ax,095h
        out 0EEh,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0FC1:
        in al,0EFh
        cmp al,034h
        jnz short tosh_0F9B
tosh_0FC7:
        mov ax,01h
        jmp short tosh_0F66
tosh_0FCC:
        mov ax,0B5h
        out 0E4h,al
; Original three-byte jump-to-next-instruction I/O delay.
        db 0E9h
        dw 0
tosh_0FD4:
        in al,0E5h
        and al,01h
        jmp short tosh_0F60
tosh_0FDA:
        sti
        jmp near ptr tosh_0F1A
tosh_0FDE:
        sti
        cmp word ptr [bp-04h],01h
        sbb ax,ax
        add ax,02h
        mov sp,bp
        pop bp
        ret
ConfigProbeToshiba endp
PNPTOSH ends
        end
