ConfigRealloc proc far
 push bp
 mov bp,sp
 cmp word ptr [bp+10],18h
 jne failed
 mov ax,offset cache
 mov dx,ds
 pop bp
 ret
ConfigRealloc endp
ConfigAlloc proc far
 push bp
 mov bp,sp
 inc allocs
 mov ax,allocs
 cmp ax,failat
 jne ca_size
 xor ax,ax
 xor dx,dx
 jmp short ca_done
ca_size:
 mov ax,offset block
 cmp word ptr [bp+6],1000h
 je ca_result
 cmp word ptr [bp+6],1FEh
 jne failed
 mov ax,offset idx
ca_result:
 mov dx,ds
ca_done:
 pop bp
 ret
ConfigAlloc endp
ConfigFree proc far
 inc frees
 ret
ConfigFree endp
; Used only by the pre-change negative control.
RegValidateDataBlock proc near
 mov ax,1
 ret 4
RegValidateDataBlock endp
newblock proc near
 push 0
 push 1000h
 push ds
 push offset result
 push ds
 push offset fileinfo
 push cs
 call near ptr RegNewDataBlock
 add sp,12
 ret
newblock endp
start:
 mov ax,TESTDATA
 mov ds,ax
 mov word ptr fileinfo+20h,offset header
 mov word ptr fileinfo+22h,ax
 mov word ptr header+8,1000h
 mov failat,1
 call newblock
 cmp ax,0Eh
 jne failed
 cmp frees,0
 jne failed
 mov allocs,0
 mov failat,2
 call newblock
 cmp ax,0Eh
 jne failed
 cmp frees,1
 jne failed
 mov allocs,0
 mov frees,0
 mov failat,0
 push 60h
 push ds
 push offset fileinfo
 push cs
 call near ptr RegAppendDataBlock
 add sp,6
 or dx,ax
 jne failed
 cmp allocs,2
 jne failed
 cmp word ptr block+4,1000h
 jne failed
 cmp word ptr block+8,0FE0h
 jne failed
 cmp word ptr block+20h,0FE0h
 jne failed
 cmp word ptr block+10h,20h
 jne failed
 cmp word ptr fileinfo+0Eh,1
 jne failed
 cmp word ptr header+10h,1
 jne failed
 cmp word ptr cache+8,1000h
 jne failed
 mov si,offset idx
 mov cx,255
check_index:
 cmp word ptr [si],0
 jne failed
 add si,2
 loop check_index
 cmp guard0,0A55Ah
 jne failed
 cmp guard1,05AA5h
 jne failed
 cmp guard2,1234h
 jne failed
 push ds
 push offset block
 push cs
 call near ptr RegFreeDataBlock
 add sp,4
 cmp frees,2
 jne failed
 mov ax,4C00h
 int 21h
failed:
 mov ax,4C01h
 int 21h
REGFILE ends
 end start
