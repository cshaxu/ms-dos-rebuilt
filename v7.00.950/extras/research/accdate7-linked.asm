tab equ 9
cr equ 13
lf equ 10
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:nothing
 org 2d1fh
query_user proc near
 ret
query_user endp
 org 5acah
config_access_table dd 0
 org 6a6bh
multi_pass_filter:
 ret
 org 6a82h
multi_pass_coff:
 ret
 org 6a85h
; Set or clear access-date recording for each named drive.
accdate_command:
        call    query_user
        jc      multi_pass_filter
        assume  ds:sysinitseg
        lds     di,[config_access_table]
        assume  ds:nothing
        jmp     short accdate_character
accdate_next:
        call    getchr
        jc      multi_pass_coff
accdate_character:
        cmp     al,' '
        je      accdate_next
        cmp     al,tab
        je      accdate_next
        cmp     al,cr
        je      accdate_next
        cmp     al,lf
        je      multi_pass_coff
        and     al,not 20h
        sub     al,'A'
        jb      accdate_invalid
        cmp     al,26
        jae     accdate_invalid
        cbw
        xchg    ax,bx
        call    getchr
        jc      accdate_invalid
        cmp     al,'+'
        jne     accdate_minus
        or      byte ptr [bx+di],6
        jmp     short accdate_next
accdate_minus:
        cmp     al,'-'
        jne     accdate_invalid
        and     byte ptr [bx+di],not 6
        jmp     short accdate_next
accdate_invalid:
        jmp     near ptr accdate_error
 org 7533h
accdate_error:
 ret
 org 75ech
getchr proc near
 ret
getchr endp
sysinitseg ends
end
