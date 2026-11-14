;** CFGMSG.ASM - Configuration selection messages
;
; Message offsets are relative to ConfigMessageText. Firmware caller
; returns a FAR pointer without copying the selected string.
;
CFGMSGS segment word public 'CODE'
        public ConfigMessageResource,ConfigMessageIndex,ConfigMessageText
        public ConfigMessageResourceEnd
ConfigMessageResource label byte
        dw 6,10,100h,0B7h
ConfigMessageIndex label word
        dw MsgNone-ConfigMessageText,MsgChoice-ConfigMessageText
        dw MsgSelect-ConfigMessageText,MsgOriginal-ConfigMessageText
        dw MsgUndocked-ConfigMessageText,MsgDock-ConfigMessageText
        dw MsgMarker-ConfigMessageText
CFGMSGS ends
CFGMSGT segment word public 'CODE'
ConfigMessageText label byte
MsgNone db 'None of the above',0
MsgChoice db 'Enter your choice:',0
MsgSelect db 'Windows cannot determine what configuration your computer is in.',13,10
          db 'Select one of the following:',13,10,13,10,0
MsgOriginal db 'Original Configuration',0
MsgUndocked db 'Undocked',0
MsgDock db 'Dock',0
MsgMarker db 'MSDCMMSG',0C3h,0
        db 43 dup ('MPAD')
        db 0
ConfigMessageResourceEnd label byte
CFGMSGT ends

CFGMSG segment word public 'CODE'
        assume cs:CFGMSG
        public ConfigGetMessage
ConfigGetMessage proc far
        push bp
        mov bp,sp
        push es
        push di
        mov ax,seg ConfigMessageIndex
        mov es,ax
        mov di,offset ConfigMessageIndex
        mov bx,[bp+6]
        add bx,bx
        mov ax,es:[bx+di]
        add ax,offset ConfigMessageText
        mov dx,seg ConfigMessageText
        pop di
        pop es
        pop bp
        ret
ConfigGetMessage endp
CFGMSG ends
        end
