; Hardware interrupt entry table, isolated target-layout experiment.
SysInitSeg segment word public 'system_init'
        assume cs:SysInitSeg
        org 0012h
old02   dd      0
int02 proc far
        call    do_int_stacks
        dw      old02
int02 endp
old08   dd      0
int08 proc far
        call    do_int_stacks
        dw      old08
int08 endp
old09   dd      0
int09 proc far
        jmp     short keyboard_lbl
        nop
        db      0
keyboard_lbl label near
        call    do_int_stacks
        dw      old09
int09 endp
old70   dd      0
int70 proc far
        call    do_int_stacks
        dw      old70
int70 endp
        irp     a,<0a,0b,0c,0d,0e,72,73,74,76,77>
int&a proc far
        jmp     short entry_int&a&_stk
old&a   dd      0
        dw      424Bh
firstflag&a db  0
        jmp     short intret_&a
        db      7 dup (0)
entry_int&a&_stk:
        call    do_int_stacks
        dw      old&a
intret_&a:
        iret
int&a endp
        endm
do_int_stacks proc near
        ret                     ; isolated placeholder, excluded from comparison
do_int_stacks endp
SysInitSeg ends
        end int02
