ConfigRealloc proc far
 push bp
 mov bp,sp
 inc allocations
 cmp word ptr [bp+10],1000h
 jne failed
 cmp word ptr [bp+12],0
 jne failed
 cmp word ptr [bp+14],0A0h
 jne failed
 mov ax,[bp+6]
 mov dx,[bp+8]
 cmp allocfail,0
 je realloc_done
 xor ax,ax
 xor dx,dx
realloc_done:
 pop bp
 ret
ConfigRealloc endp
start:
 mov ax,TESTDATA
 mov ds,ax
 mov word ptr block+4,0A0h
 mov word ptr block+8,40h
 mov word ptr block+10h,30h
 mov cache+2,ax
 mov word ptr fileinfo+28h,offset cache
 mov word ptr fileinfo+2Ah,ax
 mov word ptr block+18h,offset idx
 mov word ptr block+1Ah,ax
 mov word ptr block+20h,10h
 mov word ptr block+24h,0
 mov word ptr block+30h,10h
 mov dword ptr block+34h,-1
 mov word ptr block+40h,20h
 mov word ptr block+44h,2
 mov word ptr block+4Ch,1234h
 mov word ptr block+60h,10h
 mov dword ptr block+64h,-1
 mov word ptr block+70h,10h
 mov word ptr block+74h,254
 mov word ptr block+7Ch,5678h
 mov word ptr block+80h,20h
 mov dword ptr block+84h,-1
 ; Enough free bytes: no reallocation or record movement.
 push 0
 push 30h
 push 0
 push ds
 push offset fileinfo
 push cs
 call near ptr RegGrowDataBlock
 add sp,10
 or dx,ax
 jne failed
 cmp allocations,0
 jne failed
 ; Exceed the target block-size limit: fail without allocation.
 push 0
 push 0F000h
 push 0
 push ds
 push offset fileinfo
 push cs
 call near ptr RegGrowDataBlock
 add sp,10
 cmp ax,0Eh
 jne failed
 cmp allocations,0
 jne failed
 ; Fail allocation before testing successful growth and compaction.
 mov allocfail,1
 push 0
 push 60h
 push 0
 push ds
 push offset fileinfo
 push cs
 call near ptr RegGrowDataBlock
 add sp,10
 cmp ax,0Eh
 jne failed
 cmp word ptr block+4,0A0h
 jne failed
 mov allocfail,0
 push 0
 push 60h
 push 0
 push ds
 push offset fileinfo
 push cs
 call near ptr RegGrowDataBlock
 add sp,10
 or dx,ax
 jne failed
 cmp allocations,2
 jne failed
 cmp word ptr block+4,1000h
 jne failed
 cmp cache+8,1000h
 jne failed
 cmp idx,20h
 jne failed
 cmp idx+2,0
 jne failed
 cmp idx+4,30h
 jne failed
 cmp idx+508,50h
 jne failed
 cmp word ptr block+3Ch,1234h
 jne failed
 cmp word ptr block+5Ch,5678h
 jne failed
 cmp word ptr block+10h,60h
 jne failed
 cmp word ptr block+60h,0FA0h
 jne failed
 cmp guard0,0A55Ah
 jne failed
 cmp guard1,05AA5h
 jne failed
 cmp guard2,1234h
 jne failed
 mov ax,4C00h
 int 21h
failed:
 mov ax,4C01h
 int 21h
REGFILE ends
 end start
