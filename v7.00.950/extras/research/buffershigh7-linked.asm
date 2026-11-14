DOS7_CONFIG equ 1
MULTI_CONFIG equ 1
CONFIG_BUFFERS equ 'B'
CONFIG_BUFFERSHIGH equ 'b'
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 648dh
p_buffer_slash_x db 0
p_buffers_high db 0
 org 6acbh
tryb:
        cmp     ah,CONFIG_BUFFERS
IFDEF DOS7_CONFIG
        jne     try_buffershigh
ELSE
	jnz	tryc
ENDIF
ifdef   MULTI_CONFIG
        call    query_user              ; query the user if config_cmd
IFDEF DOS7_CONFIG
        jc      try_buffershigh
ELSE
        jc      tryc                    ; has the CONFIG_OPTION_QUERY bit set
ENDIF
endif
IFDEF DOS7_CONFIG
parse_buffers:
ENDIF
	mov	p_buffer_slash_x,0
 org 6b31h
try_buffershigh:
        cmp     ah,CONFIG_BUFFERSHIGH
        jne     tryc
        call    query_user
        jc      tryc
        mov     byte ptr [p_buffers_high],1
        jmp     short parse_buffers
tryc:
 ret
sysinitseg ends
end
