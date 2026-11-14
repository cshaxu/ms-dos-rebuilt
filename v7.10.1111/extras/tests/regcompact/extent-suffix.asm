start:
 mov ax,TESTDATA
 mov ds,ax
 mov word ptr block+4,0A0h
 mov word ptr block+8,40h
 mov word ptr block+10h,30h
 mov word ptr block+18h,offset idx
 mov word ptr block+1Ah,ax
 mov word ptr block+20h,10h
 mov word ptr block+24h,0
 mov word ptr block+30h,10h
 mov dword ptr block+34h,-1
 mov dword ptr block+38h,60h
 mov word ptr block+40h,20h
 mov word ptr block+44h,2
 mov word ptr block+4Ch,1234h
 mov word ptr block+60h,10h
 mov dword ptr block+64h,-1
 mov dword ptr block+68h,80h
 mov word ptr block+70h,10h
 mov word ptr block+74h,254
 mov word ptr block+7Ch,5678h
 mov word ptr block+80h,20h
 mov dword ptr block+84h,-1
 mov dword ptr block+88h,-1
 push 30h
 push ds
 push offset block
 push cs
 call near ptr RegTakeFreeSpace
 add sp,6
 cmp ax,offset block+60h
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
 cmp word ptr block+10h,-1
 jne failed
 cmp word ptr block+60h,40h
 jne failed
 cmp guard0,0A55Ah
 jne failed
 cmp guard1,05AA5h
 jne failed
 cmp guard2,1234h
 jne failed
 ; A single free extent: exact fit, split boundary and insufficient space.
 call reset_block
 mov ax,80h
 call take_block
 cmp ax,offset block+20h
 jne failed
 cmp word ptr block+8,0
 jne failed
 call reset_block
 mov ax,5Eh
 call take_block
 cmp ax,offset block+20h
 jne failed
 cmp word ptr block+8,22h
 jne failed
 cmp word ptr block+10h,7Eh
 jne failed
 cmp word ptr block+7Eh,22h
 jne failed
 call reset_block
 mov ax,5Fh
 call take_block
 cmp ax,offset block+20h
 jne failed
 cmp word ptr block+8,0
 jne failed
 call reset_block
 mov ax,81h
 call take_block
 cmp ax,-1
 jne failed
 cmp dx,-1
 jne failed
 cmp word ptr block+8,80h
 jne failed
 mov ax,4C00h
 int 21h
failed:
 mov ax,4C01h
 int 21h
reset_block proc near
 mov word ptr block+8,80h
 mov word ptr block+0Ah,0
 mov word ptr block+10h,20h
 mov word ptr block+12h,0
 mov word ptr block+20h,80h
 mov word ptr block+22h,0
 mov dword ptr block+24h,-1
 mov dword ptr block+28h,-1
 ret
reset_block endp
take_block proc near
 push ax
 push ds
 push offset block
 push cs
 call near ptr RegTakeFreeSpace
 add sp,6
 ret
take_block endp
REGFILE ends
 end start
