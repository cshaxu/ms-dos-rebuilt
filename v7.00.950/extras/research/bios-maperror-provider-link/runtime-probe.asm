BIOS_DATA SEGMENT
TestStack db 256 dup (0)
StackTop LABEL BYTE
BIOS_DATA ENDS
BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
ASSUME CS:BIOS_CODE,DS:NOTHING,ES:NOTHING
EXTRN maperror:NEAR
TestStart PROC FAR
        mov ax,BIOS_DATA
        cli
        mov ss,ax
        mov sp,OFFSET StackTop
        sti
        mov si,OFFSET ErrorPairs
        mov cx,9
NextError:
        mov ah,cs:[si]
        call maperror
        jnc Bad
        cmp al,cs:[si+1]
        jne Bad
        add si,2
        loop NextError
        mov ax,4C00h
        int 21h
Bad:    mov ax,4C01h
        int 21h
TestStart ENDP
ErrorPairs db 0CCh,10,80h,2,40h,6,10h,4,8,4,6,15,4,8,3,0,0FFh,12
BIOS_CODE ENDS
END TestStart
