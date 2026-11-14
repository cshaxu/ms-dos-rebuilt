; Isolated reconstruction of the hardware interrupt stack switch.
.386
SysInitSeg segment word public 'system_init' use16
        assume cs:SysInitSeg
        org     0008h
stacks  dd      0
firstentry dw   8
lastentry  dw   48h
nextentry  dw   48h
        org     012ah
do_int_stacks proc near
        push    eax
        push    bp
        push    es
        mov     es,word ptr cs:[stacks+2]
        mov     bp,cs:[nextentry]
        mov     al,1
        xchg    es:byte ptr [bp],al
        cmp     al,0
        jne     short notfree02
        sub     cs:[nextentry],8
found02:
        mov     es:word ptr [bp+2],sp
        mov     es:word ptr [bp+4],ss
        mov     ax,bp
        mov     bp,es:word ptr [bp+6]
        cmp     es:[bp],ax
        jne     short foundbad02
        mov     ax,es
        mov     es,bp
        mov     bp,sp
        mov     bp,[bp+8]
        mov     ss,ax
        mov     sp,es
        mov     es,ax
        mov     bp,cs:[bp]
        pushf
        call    dword ptr cs:[bp]
        mov     bp,sp
        mov     bp,es:[bp]
        mov     ss,es:word ptr [bp+4]
        mov     sp,es:word ptr [bp+2]
        mov     es:byte ptr [bp],0
        mov     cs:[nextentry],bp
        pop     es
        pop     bp
        pop     eax
        add     sp,2
        iret
notfree02:
        cmp     al,1
        je      short findnext02
        xchg    es:byte ptr [bp],al
        jmp     short findnext02
foundbad02:
        cmp     bp,cs:[firstentry]
        jc      short findnext02
        mov     bp,ax
        mov     es:byte ptr [bp],3
findnext02:
        mov     bp,cs:[lastentry]
lploopp:
        cmp     es:byte ptr [bp],0
        jne     short inuse
        mov     al,1
        xchg    es:byte ptr [bp],al
        cmp     al,0
        je      short found02
        cmp     al,1
        je      short inuse
        mov     es:byte ptr [bp],al
inuse:
        cmp     bp,cs:[firstentry]
        je      short fatal
        sub     bp,8
        jmp     short lploopp
fatal:
        ret                     ; excluded placeholder
 do_int_stacks endp
SysInitSeg ends
        end do_int_stacks
