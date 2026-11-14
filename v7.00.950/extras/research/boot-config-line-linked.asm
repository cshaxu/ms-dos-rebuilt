sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg,es:sysinitseg
 org 0f21h
confbot dw 0
 org 0f2dh
linecount dw 0
 org 0f52h
multi_pass_id db 0
 org 0fdah
count dw 0
 org 0fdeh
chrptr dw 0
 org 3374h
bQueryOpt db 0
 org 4f38h
; Execute one synthesized CONFIG.SYS command at ES:SI, length CX.
; AL is the command code and DH is the temporary query state.
boot_execute_config_line proc near
        push    bx
        mov     [si],al
        mov     word ptr [si+1],0
        push    word ptr [confbot]
        push    word ptr [chrptr]
        push    word ptr [count]
        push    word ptr [linecount]
        push    word ptr [config_multi]
        mov     word ptr [config_multi],1
        mov     [confbot],es
        mov     [chrptr],si
        mov     [count],cx
        xchg    dh,[bQueryOpt]
        mov     dl,[multi_pass_id]
        push    dx
        mov     byte ptr [multi_pass_id],2
        push    ds
        push    es
        call    multi_pass_config_line
        pop     es
        pop     ds
        pop     dx
        mov     [multi_pass_id],dl
        mov     [bQueryOpt],dh
        pop     word ptr [config_multi]
        pop     word ptr [linecount]
        pop     word ptr [count]
        pop     word ptr [chrptr]
        pop     word ptr [confbot]
        pop     bx
        ret
boot_execute_config_line endp
 org 5ad3h
config_multi db 0,0
 org 6942h
multi_pass_config_line proc near
 ret
multi_pass_config_line endp
sysinitseg ends
end
