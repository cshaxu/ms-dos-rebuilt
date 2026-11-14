sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 3903h
        cld
        mov     ax,0
        test    ax,ax
        jz      stack_message_done
        mov     si,offset sysinit_msg_base
        add     si,word ptr [sysinit_stack_msg_index]
stack_message_next:
        lodsb
        test    al,al
stack_message_end:
        jz      stack_message_end
        mov     dl,al
        mov     ah,2
        int     21h
        jmp     short stack_message_next
stack_message_done:
 org 0a5e6h
sysinit_stack_msg_index dw 0
 dw 0
sysinit_msg_base label byte
sysinitseg ends
end
