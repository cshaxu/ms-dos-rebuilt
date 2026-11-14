MULTI_CONFIG equ 1
CONFIG_OPTION_QUERY equ 80h
have_install_cmd equ 1
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 0f2dh
linecount dw 0
 org 0f52h
multi_pass_id db 0
install_flag db 0
config_size dw 0
 org 5ad3h
config_multi db 0
 org 696ah
ifdef MULTI_CONFIG
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     [config_multi],0        ; is this a multi-config config.sys?
        je      not_final               ; no, line number is not embedded

        push    ax                      ;
        call    getchr                  ; ignore end-of-image errors,
        mov     ah,al                   ; because if there's an error
        call    getchr                  ; fetching the line number that's
        xchg    al,ah                   ; supposed to be there, the next
        mov     [linecount],ax          ; getchr call will get the same error
        pop     ax
;
;   HACK: when 4DOS.COM is the shell and it doesn't have an environment from
;   which to obtain its original program name, it grovels through all of
;   memory to find the filename that was used to exec it;  it wants to find
;   the SHELL= line in the in-memory copy of CONFIG.SYS, and it knows that
;   sysinit converts the SHELL= keyword to an 'S', so it expects to find an 'S'
;   immediately before the filename, but since we are now storing line # info
;   in the config.sys memory image, 4DOS fails to find the 'S' in the right
;   spot.
;
;   So, on the final pass of CONFIG.SYS, copy the command code (eg, 'S')
;   over the line number info, since we no longer need that info anyway.  This
;   relies on the fact that getchr leaves ES:SI pointing to the last byte
;   retrieved.
;
        cmp     multi_pass_id,2         ; final pass?
        jb      not_final               ; no
        test    install_flag,have_install_cmd
        jz      final                   ; no install cmds, so yes it is
        cmp     multi_pass_id,3         ; final pass?
        jb      not_final               ; no
final:                                  ;
        mov     es:[si],al              ; save backward-compatible command code

not_final:                              ;
endif
	mov	ah,al
	call	getchr
	jnc	tryi
 org 69b9h
tryi:
 ret
 org 75ech
getchr proc near
 ret
getchr endp
sysinitseg ends
end
