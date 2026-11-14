; Startup-image MRCF decoder.
; Input: DS:SI compressed data, ES:DI destination, AX output capacity.
; Output: AX bytes decoded; carry set on invalid compressed data.

; MASM selects accumulator-immediate encodings for AX.  These macros emit
; the equivalent sign-extended immediate form present in the target.
cmp_ax_imm8 macro value
	db 83h,0f8h,value
endm
and_ax_imm8 macro value
	db 83h,0e0h,value
endm
chunk_count dw 0
decode_args db 22 dup (0)
state_table dw cmdat0,cmdat1,cmdat2,cmdat3
	dw cmdat4,cmdat5,cmdat6,cmdat7
decode_entry:
	pusha
	push ds
	push es
	mov word ptr cs:decode_args,si
	mov word ptr cs:decode_args+2,ds
	push cs
	pop ds
	mov si,offset decode_args
	mov [si+8],di
	mov [si+10],es
	mov [si+12],ax
	call decode_buffer
	cmp_ax_imm8 1
	cmc
	jnc short entry_return
	mov word ptr [si+12],0
entry_return:
	pop es
	pop ds
	popa
	mov ax,word ptr cs:decode_args+12
	ret
decode_buffer:
	push ds
	push si
	mov ax,[si+12]
	mov dx,ax
	mov cl,9
	shr ax,cl
	and dx,1ffh
	jz short count_ready
	inc ax
count_ready:
	mov word ptr cs:chunk_count,ax
	les di,[si+8]
	lds si,[si]
	cld
	xor cx,cx
	lodsw
	cmp ax,5344h
	jne short buffer_error
	lodsw
	call decode_start
	jc short buffer_error
	pop si
	pop ds
	sub di,[si+8]
	mov [si+12],di
	xor ax,ax
	ret
buffer_error:
	pop si
	pop ds
	mov ax,5
	ret
decode_start:
	xchg ax,bx
	or cx,cx
	jnz short decode_resume
	lodsw
	sub dx,dx
decode_resume:
	call decode_chunk
	xchg ax,bx
	ret
decode_chunk:
	mov bp,200h
	movzx bx,dl
	jmp word ptr cs:state_table[bx]
cmdat0:
	test al,3
	jpo short charat1
	test al,2
	jnz short offset8
	shld cx,ax,14
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length7
offset8:
	test al,4
	jnz short offset12
	shld cx,ax,13
	xor ch,ch
	lodsb
	xchg al,ah
	add cx,40h
	jmp near ptr length2
offset12:
	shld cx,ax,13
	and ch,0fh
	lodsb
	xchg al,ah
	add cx,140h
	jmp near ptr length6
error0:
	jmp near ptr decode_error
charat1:
	shr ax,1
	ror al,1
	xor al,80h
	dec bp
	js error0
	stosb
	add ax,ax
	lodsb
	xchg al,ah
cmdat1:
	test al,6
	jpo short charat2
	test al,4
	jnz short offset8_1
	shld cx,ax,13
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length_state1_7
offset8_1:
	test al,8
	jnz short offset12_1
	shld cx,ax,12
	xor ch,ch
	lodsb
	xchg al,ah
	add cx,40h
	jmp near ptr length_state1_2
offset12_1:
	shld cx,ax,12
	and ch,0fh
	lodsw
	add cx,140h
	jmp near ptr length7
charat2:
	ror ax,2
	ror al,1
	xor al,80h
	dec bp
	js short error0
	stosb
	rol ax,2
	lodsb
	xchg al,ah
cmdat2:
	test al,0ch
	jpo short charat3
	test al,8
	jnz short offset8_2
	shld cx,ax,12
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length_state2_7
offset8_2:
	test al,10h
	jnz short offset12_2
	shld cx,ax,11
	xor ch,ch
	lodsb
	xchg al,ah
	add cx,40h
	jmp near ptr length_state2_2
offset12_2:
	mov cx,ax
	lodsw
	shrd cx,ax,5
	and ch,0fh
	add cx,140h
	jmp near ptr length_state1_7
error2:
	jmp near ptr decode_error
charat3:
	ror ax,3
	ror al,1
	xor al,80h
	dec bp
	js short error2
	stosb
	rol ax,3
	lodsb
	xchg al,ah
cmdat3:
	test al,18h
	jpo short charat4
	test al,10h
	jnz short offset8_3
	shld cx,ax,11
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length2
offset8_3:
	test al,20h
	jnz short offset12_3
	shld cx,ax,10
	xor ch,ch
	lodsb
	xchg al,ah
	add cx,40h
	jmp near ptr length_state3_2
offset12_3:
	mov cx,ax
	lodsw
	shrd cx,ax,6
	and ch,0fh
	add cx,140h
	jmp near ptr length_state2_7
charat4:
	ror ax,4
	ror al,1
	xor al,80h
	dec bp
	js short error2
	stosb
	rol ax,4
	lodsb
	xchg al,ah
cmdat4:
	test al,30h
	jpo short charat5
	test al,20h
	jnz short offset8_4
	shld cx,ax,10
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length_state1_2
offset8_4:
	test al,40h
	jnz short offset12_4
	shld cx,ax,9
	xor ch,ch
	lodsb
	xchg al,ah
	add cx,40h
	jmp near ptr length6
offset12_4:
	mov cx,ax
	lodsw
	shrd cx,ax,7
	and ch,0fh
	add cx,140h
	jmp near ptr length2
error4:
	jmp near ptr decode_error
charat5:
	ror ax,5
	ror al,1
	xor al,80h
	dec bp
	js short error4
	stosb
	rol ax,5
	lodsb
	xchg al,ah
cmdat5:
	test al,60h
	jpo short charat6
	test al,40h
	jnz short offset8_5
	shld cx,ax,9
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length_state2_2
offset8_5:
	test al,80h
	jnz short offset12_5
	shld cx,ax,8
	xor ch,ch
	lodsw
	add cx,40h
	jmp near ptr length7
offset12_5:
	mov cx,ax
	lodsw
	shrd cx,ax,8
	and ch,0fh
	add cx,140h
	jmp near ptr length_state1_2
charat6:
	ror ax,6
	ror al,1
	xor al,80h
	dec bp
	js short error4
	stosb
	rol ax,6
	lodsb
	xchg al,ah
cmdat6:
	test al,0c0h
	jpo short charat7
	test al,80h
	jnz short offset8_6
	shld cx,ax,8
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length_state3_2
offset8_6:
	test ah,1
	jnz short offset12_6
	mov cx,ax
	lodsw
	shrd cx,ax,9
	xor ch,ch
	add cx,40h
	jmp near ptr length_state1_7
offset12_6:
	mov cx,ax
	lodsw
	shrd cx,ax,9
	and ch,0fh
	add cx,140h
	jmp near ptr length_state2_2
error6:
	jmp near ptr decode_error
charat7:
	ror ax,7
	ror al,1
	xor al,80h
	dec bp
	js short error6
	stosb
	rol ax,7
	lodsb
	xchg al,ah
cmdat7:
	ror ax,1
	test al,0c0h
	rol ax,1
	jpo short charat8
	test ah,1
	jnz short offset8_7
	shld cx,ax,7
	and cx,3fh
	lodsb
	xchg al,ah
	jmp near ptr length6
offset8_7:
	test ah,2
	jnz short offset12_7
	mov cx,ax
	lodsw
	shrd cx,ax,10
	xor ch,ch
	add cx,40h
	jmp near ptr length_state2_7
offset12_7:
	mov cx,ax
	lodsw
	shrd cx,ax,10
	and ch,0fh
	add cx,140h
	jmp near ptr length_state3_2
charat8:
	mov al,ah
	ror al,1
	xor al,80h
	dec bp
	js short error6
	stosb
	lodsw
	jmp near ptr cmdat0
error7:
	jmp near ptr decode_error
length7:
	jcxz error7
	cmp cx,113fh
	je short done7
	test al,1
	jz short more7
	sub bp,2
	js short error7
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat1
done7:
	mov dl,0
	jmp near ptr decode_done
more7:
	mov bx,cx
	test al,2
	jz short length5_7
	shld cx,ax,14
	and cx,1
	add cx,3
	sub bp,cx
	js short error7
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat3
error7a:
	jmp near ptr decode_error
length5_7:
	test al,4
	jz short length9_7
	shld cx,ax,13
	and cx,3
	add cx,5
	sub bp,cx
	js short error7a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat5
length9_7:
	test al,8
	jz short length17_7
	shld cx,ax,12
	and cx,7
	add cx,9
	sub bp,cx
	js short error7a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_7
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_7:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat7
error7b:
	jmp near ptr decode_error
length17_7:
	test al,10h
	jz short long7
	shld cx,ax,11
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error7b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_7
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_7:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat1
long7:
	mov cl,5
	jmp near ptr long_length
length_state1_7:
	jcxz error7b
	cmp cx,113fh
	je short done1
	test al,2
	jz short more1
	sub bp,2
	js short error7b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat2
done1:
	mov dl,2
	jmp near ptr decode_done
more1:
	mov bx,cx
	test al,4
	jz short length5_1
	shld cx,ax,13
	and cx,1
	add cx,3
	sub bp,cx
	js short error7b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat4
error1a:
	jmp near ptr decode_error
length5_1:
	test al,8
	jz short length9_1
	shld cx,ax,12
	and cx,3
	add cx,5
	sub bp,cx
	js short error1a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat6
length9_1:
	test al,10h
	jz short length17_1
	shld cx,ax,11
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error1a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_1
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_1:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat0
error1b:
	jmp near ptr decode_error
length17_1:
	test al,20h
	jz short long1
	shld cx,ax,10
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error1b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_1
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_1:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat2
long1:
	mov cl,6
	jmp near ptr long_length
length_state2_7:
	jcxz error1b
	cmp cx,113fh
	je short done2
	test al,4
	jz short more2
	sub bp,2
	js short error1b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat3
done2:
	mov dl,4
	jmp near ptr decode_done
more2:
	mov bx,cx
	test al,8
	jz short length5_2
	shld cx,ax,12
	and cx,1
	add cx,3
	sub bp,cx
	js short error1b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat5
error2a:
	jmp near ptr decode_error
length5_2:
	test al,10h
	jz short length9_2
	shld cx,ax,11
	and cx,3
	add cx,5
	sub bp,cx
	js short error2a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat7
length9_2:
	test al,20h
	jz short length17_2
	shld cx,ax,10
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error2a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_2
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_2:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat1
error2b:
	jmp near ptr decode_error
length17_2:
	test al,40h
	jz short long2
	shld cx,ax,9
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error2b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_2
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_2:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat3
long2:
	mov cl,7
	jmp near ptr long_length
length2:
	jcxz error2b
	cmp cx,113fh
	je short done3
	test al,8
	jz short more3
	sub bp,2
	js short error2b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat4
done3:
	mov dl,6
	jmp near ptr decode_done
more3:
	mov bx,cx
	test al,10h
	jz short length5_3
	shld cx,ax,11
	and cx,1
	add cx,3
	sub bp,cx
	js short error2b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat6
error3a:
	jmp near ptr decode_error
length5_3:
	test al,20h
	jz short length9_3
	shld cx,ax,10
	and cx,3
	lodsb
	xchg al,ah
	add cx,5
	sub bp,cx
	js short error3a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat0
length9_3:
	test al,40h
	jz short length17_3
	shld cx,ax,9
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error3a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_3
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_3:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat2
error3b:
	jmp near ptr decode_error
length17_3:
	test al,80h
	jz short long3
	shld cx,ax,8
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error3b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_3
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_3:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat4
long3:
	mov cl,8
	jmp near ptr long_length
length_state1_2:
	jcxz error3b
	cmp cx,113fh
	je short done4
	test al,10h
	jz short more4
	sub bp,2
	js short error3b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat5
done4:
	mov dl,8
	jmp near ptr decode_done
more4:
	mov bx,cx
	test al,20h
	jz short length5_4
	shld cx,ax,10
	and cx,1
	add cx,3
	sub bp,cx
	js short error3b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat7
error4a:
	jmp near ptr decode_error
length5_4:
	test al,40h
	jz short length9_4
	shld cx,ax,9
	and cx,3
	lodsb
	xchg al,ah
	add cx,5
	sub bp,cx
	js short error4a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat1
length9_4:
	test al,80h
	jz short length17_4
	shld cx,ax,8
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error4a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_4
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_4:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat3
error4b:
	jmp near ptr decode_error
length17_4:
	test ah,1
	jz short long4
	shld cx,ax,7
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error4b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_4
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_4:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat5
long4:
	mov cl,9
	jmp near ptr long_length
length_state2_2:
	jcxz error4b
	cmp cx,113fh
	je short done5
	test al,20h
	jz short more5
	sub bp,2
	js short error4b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat6
done5:
	mov dl,10
	jmp near ptr decode_done
more5:
	mov bx,cx
	test al,40h
	jz short length5_5
	shld cx,ax,9
	and cx,1
	lodsb
	xchg al,ah
	add cx,3
	sub bp,cx
	js short error4b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat0
error5a:
	jmp near ptr decode_error
length5_5:
	test al,80h
	jz short length9_5
	shld cx,ax,8
	and cx,3
	lodsb
	xchg al,ah
	add cx,5
	sub bp,cx
	js short error5a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat2
length9_5:
	test ah,1
	jz short length17_5
	shld cx,ax,7
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error5a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_5
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_5:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat4
error5b:
	jmp near ptr decode_error
length17_5:
	test ah,2
	jz short long5
	shld cx,ax,6
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error5b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_5
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_5:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat6
long5:
	mov cl,10
	jmp near ptr long_length
length_state3_2:
	jcxz error5b
	cmp cx,113fh
	je short done6
	test al,40h
	jz short more6
	sub bp,2
	js short error5b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat7
done6:
	mov dl,12
	jmp near ptr decode_done
more6:
	mov bx,cx
	test al,80h
	jz short length5_6
	shld cx,ax,8
	and cx,1
	lodsb
	xchg al,ah
	add cx,3
	sub bp,cx
	js short error5b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat1
error6a:
	jmp near ptr decode_error
length5_6:
	test ah,1
	jz short length9_6
	shld cx,ax,7
	and cx,3
	lodsb
	xchg al,ah
	add cx,5
	sub bp,cx
	js short error6a
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat3
length9_6:
	test ah,2
	jz short length17_6
	shld cx,ax,6
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error6a
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_6
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_6:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat5
error6b:
	jmp near ptr decode_error
length17_6:
	test ah,4
	jz short long6
	shld cx,ax,5
	and cx,0fh
	lodsb
	xchg al,ah
	add cx,17
	sub bp,cx
	js short error6b
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_6
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_6:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat7
long6:
	mov cl,11
	jmp near ptr long_length
length6:
	jcxz error6b
	cmp cx,113fh
	je short done_last
	test al,80h
	jz short more_last
	sub bp,2
	js short error6b
	mov dx,si
	mov si,di
	sub si,cx
	movs byte ptr es:[di],byte ptr es:[si]
	movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	lodsb
	xchg al,ah
	jmp near ptr cmdat0
done_last:
	mov dl,14
	jmp near ptr decode_done
more_last:
	mov bx,cx
	test ah,1
	jz short length5_last
	shld cx,ax,7
	and cx,1
	lodsb
	xchg al,ah
	add cx,3
	sub bp,cx
	js short error6b
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat2
error_lasta:
	jmp near ptr decode_error
length5_last:
	test ah,2
	jz short length9_last
	shld cx,ax,6
	and cx,3
	lodsb
	xchg al,ah
	add cx,5
	sub bp,cx
	js short error_lasta
	mov dx,si
	mov si,di
	sub si,bx
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat4
length9_last:
	test ah,4
	jz short length17_last
	shld cx,ax,5
	and cx,7
	lodsb
	xchg al,ah
	add cx,9
	sub bp,cx
	js short error_lasta
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy9_last
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy9_last:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat6
error_lastb:
	jmp near ptr decode_error
length17_last:
	test ah,8
	jz short long_last
	shld cx,ax,4
	and cx,0fh
	lodsw
	add cx,17
	sub bp,cx
	js short error_lastb
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short copy17_last
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
copy17_last:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	jmp near ptr cmdat0
long_last:
	mov cl,12
long_length:
	shr ax,cl
	push cx
	mov dx,[si]
	neg cl
	add cl,16
	shl dx,cl
	or ax,dx
	shr ax,1
	jnc short long64
	and_ax_imm8 1fh
	add al,33
	xchg ax,cx
	mov al,6
long_copy:
	sub bp,cx
	js short long_error
	mov dx,si
	mov si,di
	sub si,bx
	cmp bx,1
	je short long_copy_bytes
	shr cx,1
	rep movs word ptr es:[di],word ptr es:[si]
	adc cx,cx
long_copy_bytes:
	rep movs byte ptr es:[di],byte ptr es:[si]
	mov si,dx
	pop dx
	add dl,al
	cmp dl,24
	jb short long_less24
	inc si
	lodsw
	sub dl,24
	add dl,dl
	movzx bx,dl
	jmp word ptr cs:state_table[bx]
long_less24:
	cmp dl,16
	jae short long_atleast16
	dec si
	add dl,8
long_atleast16:
	lodsw
	sub dl,16
	add dl,dl
	movzx bx,dl
	jmp word ptr cs:state_table[bx]
long_error:
	pop cx
	jmp short decode_error
long64:
	shr ax,1
	jnc short long128
	and_ax_imm8 3fh
	add al,65
	xchg ax,cx
	mov al,8
	jmp short long_copy
long128:
	shr ax,1
	jnc short long256
	and_ax_imm8 7fh
	add ax,129
	xchg ax,cx
	mov al,10
	jmp short long_copy
long256:
	shr ax,1
	jnc short long_error
	mov ah,0
	add ax,257
	xchg ax,cx
	mov al,12
	jmp short long_copy
decode_done:
	test bp,bp
	jnz short partial_chunk
	dec word ptr cs:chunk_count
	jz short decode_success
	jmp near ptr decode_chunk
partial_chunk:
	dec word ptr cs:chunk_count
	jnz short decode_error
decode_success:
	mov dh,1
	ret
decode_error:
	stc
	ret
