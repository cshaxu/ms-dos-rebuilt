DOS7_CONFIG equ 1
set_default_drive equ 0eh
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f03h
def_php dw 0
 org 0f16h
default_drive db 0
 org 0feah
memhi dw 0
 org 0ff0h
TooManyDrivesFlag db 0
 org 1419h
        cmp     byte ptr [TooManyDrivesFlag],0  ;Q: >24 partitions? M029
        je      no_err                          ;  N: continue      M029
IFDEF DOS7_CONFIG
        call    print_indexed
        dw      8012h
ELSE
        mov     dx,offset TooManyDrivesMsg      ;  Y: print error message M029
        call	print                           ;		    M029
ENDIF
no_err:						;		    M029

IFDEF DOS7_CONFIG
        assume  ds:sysinitseg
ELSE
	pop	ds			; start of free memory
	assume	ds:nothing
ENDIF

	mov	dl,[default_drive]
	or	dl,dl
	jz	nodrvset		; bios didn't say
	dec	dl			; a = 0
	mov	ah,set_default_drive
	int	21h			;select the disk

nodrvset:
IFDEF DOS7_CONFIG
        mov     ax,[def_php]
        mov     [memhi],ax
ENDIF
 org 1c14h
print_indexed proc near
 ret
print_indexed endp
sysinitseg ends
end
