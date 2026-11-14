;** CRTSTART.ASM - DOS configuration C runtime startup
;
; Establish DGROUP and the runtime stack, initialize C storage, and call main.
; Configuration error handling returns through the runtime's far stub.
;
        dosseg
_TEXT segment word public 'CODE'
_TEXT ends
C_ETEXT segment word public 'ENDCODE'
C_ETEXT ends
_DATA segment word public 'DATA'
_DATA ends
XIQC segment word common 'DATA'
XIQC ends
STACK segment para stack 'STACK'
        db 800h dup (?)
STACK ends
DBDATA segment word common 'DATA'
DBDATA ends
DGROUP group _DATA,XIQC,STACK,DBDATA

        extrn __acrtmsg:far,_main:far,_exit:far,__exit:far
        extrn ___qczrinit:word,__edata:byte,__end:byte,__psp:word
        extrn ___argc:word,___argv:dword,__environ:dword
        extrn __osversion:word,__osver:word,__cinit:far
        extrn __NMSG_WRITE:far,__FF_MSGBANNER:far
        extrn __setargv:far,__setenvp:far,__farstub:far

DBDATA segment word common 'DATA'
        public ___aDBswpflg,___aDBswpchk,___aDBrterr,___aDBexit
___aDBswpflg dw 0
___aDBswpchk dw offset startup_return
___aDBrterr  dw offset startup_return
___aDBexit   dw offset startup_return,0
            dw 0
DBDATA ends

_DATA segment word public 'DATA'
        public __atopsp,__aexit_rtn,__asizds,__nheap_desc
        public __aseghi,__aseglo,__fDosExt
__atopsp    dw 0
__aexit_rtn dw offset __exit
__asizds    dw 0
__nheap_desc dw 0,5,8 dup (0)
__aseghi    dw 0
__aseglo    dw 0
__fDosExt   dw 0
_DATA ends

        public __acrtused,__aDBdoswp
__acrtused equ 9876h
__aDBdoswp equ 0D6D6h

_TEXT segment word public 'CODE'
        assume cs:_TEXT,ds:DGROUP,es:nothing,ss:DGROUP
        public __astart,__cintDIV,__amsg_exit,__dataseg
__astart proc far
        mov ah,30h
        int 21h
        cmp al,2
        jae short startup_dos
        xor ax,ax
        push es
        push ax
        ret
startup_dos:
        mov di,DGROUP
        mov si,ds:[2]
        sub si,di
        cmp si,1000h
        jb short startup_stack
        mov si,1000h
startup_stack:
        cli
        mov ss,di
        add sp,offset DGROUP:__end-2
        sti
        jnc short startup_storage
        push ss
        pop ds
        push cs
        call near ptr __FF_MSGBANNER
        xor ax,ax
        push ax
        push cs
        call near ptr __NMSG_WRITE
        mov ax,4CFFh
        int 21h
startup_storage:
        mov ss:__osversion,ax
        xchg ah,al
        mov ss:__osver,ax
        mov ax,si
        mov cl,4
        shl ax,cl
        dec ax
        mov ss:__asizds,ax
        mov bx,offset DGROUP:__nheap_desc
        mov ss:[bx],ss
        and sp,-2
        mov ss:[bx+4],sp
        mov ax,-2
        push ax
        mov ss:[bx+10],sp
        not ax
        push ax
        mov ss:[bx+6],sp
        mov ss:[bx+8],sp
        mov ss:__atopsp,sp
        add si,di
        mov ds:[2],si
        mov bx,es
        sub bx,si
        neg bx
        mov ah,4Ah
        int 21h
        mov ss:__psp,ds
        push ss
        pop es
        cld
        mov di,offset DGROUP:__edata
        mov cx,offset DGROUP:__end
        sub cx,di
        xor ax,ax
        rep stosb
        push ss
        pop ds
        mov cx,___qczrinit
        jcxz short startup_arguments
        call cx
startup_arguments:
        call __setenvp
        call __setargv
        xor bp,bp
        call __cinit
        push ss
        pop ds
        push word ptr __environ+2
        push word ptr __environ
        push word ptr ___argv+2
        push word ptr ___argv
        push ___argc
        call _main
        push ax
        push cs
        call near ptr _exit
startup_return:
        retn
__astart endp

__cintDIV proc near
        mov ax,cs:__dataseg
        mov ds,ax
        mov ax,3
        mov __aexit_rtn,offset _exit
__cintDIV endp
__amsg_exit proc near
        push ax
        mov bx,cs:__dataseg
        mov ds,bx
        call __farstub
        push cs
        call near ptr __FF_MSGBANNER
        push cs
        call near ptr __NMSG_WRITE
        cmp ___aDBswpflg,__aDBdoswp
        jne short startup_exit
        pop ax
        push ax
        call ___aDBrterr
startup_exit:
        mov ax,0FFh
        push ax
        push cs
        call __aexit_rtn
__amsg_exit endp
__dataseg dw DGROUP
_TEXT ends
        end __astart
