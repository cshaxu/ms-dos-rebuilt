; MS-DOS BIOS compressed sector decoder.
;
	page	,160
	title	CM compressed sector decoder

CopyMatch macro
	mov	dx,si
	mov	si,di
	sub	si,bx
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
endm

; Use the accumulator encoding for these word masks.
MaskAx macro mask
	db	25h			; AND AX,imm16
	dw	mask
endm

cSeg	segment para public 'code'
	.386
	assume	cs:cSeg,ds:nothing,es:nothing,ss:nothing

cm_header	db	'CM'
		dw	offset cm_entry
		dw	0abh
cm_sectors	dw	0
cm_saved_bp	dw	0
cm_decode	label word
		dw	offset cm_token0
		dw	offset cm_token1
		dw	offset cm_token2
		dw	offset cm_token3
		dw	offset cm_token4
		dw	offset cm_token5
		dw	offset cm_token6
		dw	offset cm_token7

; CX gives the number of output sectors. DL is the initial bit phase.
cm_entry:
	mov	cs:cm_sectors,cx
	mov	cs:cm_saved_bp,bp
cm_next_sector:
	mov	bp,200h
	movzx	bx,dl
	jmp	word ptr cs:cm_decode[bx]

; Decode a literal or a backward distance at each input bit phase.
cm_token0:
	test	al,3
	jpo	near ptr cm_literal0
	test	al,2
	jnz	near ptr cm_distance_medium0
	shld	cx,ax,0eh
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match0
cm_distance_medium0:
	test	al,4
	jnz	near ptr cm_distance_far0
	shld	cx,ax,0dh
	xor	ch,ch
	lodsb
	xchg	al,ah
	add	cx,40h
	jmp	near ptr cm_match3
cm_distance_far0:
	shld	cx,ax,0dh
	and	ch,0fh
	lodsb
	xchg	al,ah
	add	cx,140h
	jmp	near ptr cm_match7
cm_literal_error0:
	jmp	near ptr cm_error
cm_literal0:
	shr	ax,1
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error0
	stosb
	add	ax,ax
	lodsb
	xchg	al,ah
cm_token1:
	test	al,6
	jpo	near ptr cm_literal1
	test	al,4
	jnz	near ptr cm_distance_medium1
	shld	cx,ax,0dh
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match1
cm_distance_medium1:
	test	al,8
	jnz	near ptr cm_distance_far1
	shld	cx,ax,0ch
	xor	ch,ch
	lodsb
	xchg	al,ah
	add	cx,40h
	jmp	near ptr cm_match4
cm_distance_far1:
	shld	cx,ax,0ch
	and	ch,0fh
	lodsw
	add	cx,140h
	jmp	near ptr cm_match0
cm_literal1:
	ror	ax,2
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error0
	stosb
	rol	ax,2
	lodsb
	xchg	al,ah
cm_token2:
	test	al,0ch
	jpo	near ptr cm_literal2
	test	al,8
	jnz	near ptr cm_distance_medium2
	shld	cx,ax,0ch
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match2
cm_distance_medium2:
	test	al,10h
	jnz	near ptr cm_distance_far2
	shld	cx,ax,0bh
	xor	ch,ch
	lodsb
	xchg	al,ah
	add	cx,40h
	jmp	near ptr cm_match5
cm_distance_far2:
	mov	cx,ax
	lodsw
	shrd	cx,ax,5
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match1
cm_literal_error2:
	jmp	near ptr cm_error
cm_literal2:
	ror	ax,3
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error2
	stosb
	rol	ax,3
	lodsb
	xchg	al,ah
cm_token3:
	test	al,18h
	jpo	near ptr cm_literal3
	test	al,10h
	jnz	near ptr cm_distance_medium3
	shld	cx,ax,0bh
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match3
cm_distance_medium3:
	test	al,20h
	jnz	near ptr cm_distance_far3
	shld	cx,ax,0ah
	xor	ch,ch
	lodsb
	xchg	al,ah
	add	cx,40h
	jmp	near ptr cm_match6
cm_distance_far3:
	mov	cx,ax
	lodsw
	shrd	cx,ax,6
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match2
cm_literal3:
	ror	ax,4
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error2
	stosb
	rol	ax,4
	lodsb
	xchg	al,ah
cm_token4:
	test	al,30h
	jpo	near ptr cm_literal4
	test	al,20h
	jnz	near ptr cm_distance_medium4
	shld	cx,ax,0ah
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match4
cm_distance_medium4:
	test	al,40h
	jnz	near ptr cm_distance_far4
	shld	cx,ax,9
	xor	ch,ch
	lodsb
	xchg	al,ah
	add	cx,40h
	jmp	near ptr cm_match7
cm_distance_far4:
	mov	cx,ax
	lodsw
	shrd	cx,ax,7
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match3
cm_copy_error0_1:
	jmp	near ptr cm_error
cm_literal4:
	ror	ax,5
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_copy_error0_1
	stosb
	rol	ax,5
	lodsb
	xchg	al,ah
cm_token5:
	test	al,60h
	jpo	near ptr cm_literal5
	test	al,40h
	jnz	near ptr cm_distance_medium5
	shld	cx,ax,9
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match5
cm_distance_medium5:
	test	al,80h
	jnz	near ptr cm_distance_far5
	shld	cx,ax,8
	xor	ch,ch
	lodsw
	add	cx,40h
	jmp	near ptr cm_match0
cm_distance_far5:
	mov	cx,ax
	lodsw
	shrd	cx,ax,8
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match4
cm_literal5:
	ror	ax,6
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_copy_error0_1
	stosb
	rol	ax,6
	lodsb
	xchg	al,ah
cm_token6:
	test	al,0c0h
	jpo	near ptr cm_literal6
	test	al,80h
	jnz	near ptr cm_distance_medium6
	shld	cx,ax,8
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match6
cm_distance_medium6:
	test	ah,1
	jnz	near ptr cm_distance_far6
	mov	cx,ax
	lodsw
	shrd	cx,ax,9
	xor	ch,ch
	add	cx,40h
	jmp	near ptr cm_match1
cm_distance_far6:
	mov	cx,ax
	lodsw
	shrd	cx,ax,9
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match5
cm_literal_error6:
	jmp	near ptr cm_error
cm_literal6:
	ror	ax,7
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error6
	stosb
	rol	ax,7
	lodsb
	xchg	al,ah
cm_token7:
	ror	ax,1
	test	al,0c0h
	rol	ax,1
	jpo	near ptr cm_literal7
	test	ah,1
	jnz	near ptr cm_distance_medium7
	shld	cx,ax,7
	and	cx,3fh
	lodsb
	xchg	al,ah
	jmp	near ptr cm_match7
cm_distance_medium7:
	test	ah,2
	jnz	near ptr cm_distance_far7
	mov	cx,ax
	lodsw
	shrd	cx,ax,0ah
	xor	ch,ch
	add	cx,40h
	jmp	near ptr cm_match2
cm_distance_far7:
	mov	cx,ax
	lodsw
	shrd	cx,ax,0ah
	and	ch,0fh
	add	cx,140h
	jmp	near ptr cm_match6
cm_literal7:
	mov	al,ah
	ror	al,1
	xor	al,80h
	dec	bp
	js	short cm_literal_error6
	stosb
	lodsw
	jmp	near ptr cm_token0
cm_match_error0:
	jmp	near ptr cm_error

; CX holds the distance. Decode the run length and copy within ES.
cm_match0:
	jcxz	cm_match_error0
	cmp	cx,113fh
	jz	near ptr cm_sector_end0
	test	al,1
	jz	near ptr cm_length0_1
	sub	bp,2
	js	short cm_match_error0
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token1
cm_sector_end0:
	mov	dl,0
	jmp	near ptr cm_sector_end
cm_length0_1:
	mov	bx,cx
	test	al,2
	jz	near ptr cm_length0_2
	shld	cx,ax,0eh
	and	cx,1
	add	cx,3
	sub	bp,cx
	js	short cm_match_error0
	CopyMatch
	jmp	near ptr cm_token3
cm_copy_error0_2:
	jmp	near ptr cm_error
cm_length0_2:
	test	al,4
	jz	near ptr cm_length0_3
	shld	cx,ax,0dh
	and	cx,3
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error0_2
	CopyMatch
	jmp	near ptr cm_token5
cm_length0_3:
	test	al,8
	jz	near ptr cm_length0_4
	shld	cx,ax,0ch
	and	cx,7
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error0_2
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail0_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail0_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token7
cm_match_error1:
	jmp	near ptr cm_error
cm_length0_4:
	test	al,10h
	jz	near ptr cm_length0_5
	shld	cx,ax,0bh
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail0_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail0_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token1
cm_length0_5:
	mov	cl,5
	jmp	near ptr cm_length_long
cm_match1:
	jcxz	cm_match_error1
	cmp	cx,113fh
	jz	near ptr cm_sector_end1
	test	al,2
	jz	near ptr cm_length1_1
	sub	bp,2
	js	short cm_match_error1
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token2
cm_sector_end1:
	mov	dl,2
	jmp	near ptr cm_sector_end
cm_length1_1:
	mov	bx,cx
	test	al,4
	jz	near ptr cm_length1_2
	shld	cx,ax,0dh
	and	cx,1
	add	cx,3
	sub	bp,cx
	js	short cm_match_error1
	CopyMatch
	jmp	near ptr cm_token4
cm_copy_error1_1:
	jmp	near ptr cm_error
cm_length1_2:
	test	al,8
	jz	near ptr cm_length1_3
	shld	cx,ax,0ch
	and	cx,3
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error1_1
	CopyMatch
	jmp	near ptr cm_token6
cm_length1_3:
	test	al,10h
	jz	near ptr cm_length1_4
	shld	cx,ax,0bh
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error1_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail1_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail1_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token0
cm_match_error2:
	jmp	near ptr cm_error
cm_length1_4:
	test	al,20h
	jz	near ptr cm_length1_5
	shld	cx,ax,0ah
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error2
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail1_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail1_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token2
cm_length1_5:
	mov	cl,6
	jmp	near ptr cm_length_long
cm_match2:
	jcxz	cm_match_error2
	cmp	cx,113fh
	jz	near ptr cm_sector_end2
	test	al,4
	jz	near ptr cm_length2_1
	sub	bp,2
	js	short cm_match_error2
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token3
cm_sector_end2:
	mov	dl,4
	jmp	near ptr cm_sector_end
cm_length2_1:
	mov	bx,cx
	test	al,8
	jz	near ptr cm_length2_2
	shld	cx,ax,0ch
	and	cx,1
	add	cx,3
	sub	bp,cx
	js	short cm_match_error2
	CopyMatch
	jmp	near ptr cm_token5
cm_copy_error2_1:
	jmp	near ptr cm_error
cm_length2_2:
	test	al,10h
	jz	near ptr cm_length2_3
	shld	cx,ax,0bh
	and	cx,3
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error2_1
	CopyMatch
	jmp	near ptr cm_token7
cm_length2_3:
	test	al,20h
	jz	near ptr cm_length2_4
	shld	cx,ax,0ah
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error2_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail2_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail2_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token1
cm_match_error3:
	jmp	near ptr cm_error
cm_length2_4:
	test	al,40h
	jz	near ptr cm_length2_5
	shld	cx,ax,9
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error3
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail2_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail2_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token3
cm_length2_5:
	mov	cl,7
	jmp	near ptr cm_length_long
cm_match3:
	jcxz	cm_match_error3
	cmp	cx,113fh
	jz	near ptr cm_sector_end3
	test	al,8
	jz	near ptr cm_length3_1
	sub	bp,2
	js	short cm_match_error3
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token4
cm_sector_end3:
	mov	dl,6
	jmp	near ptr cm_sector_end
cm_length3_1:
	mov	bx,cx
	test	al,10h
	jz	near ptr cm_length3_2
	shld	cx,ax,0bh
	and	cx,1
	add	cx,3
	sub	bp,cx
	js	short cm_match_error3
	CopyMatch
	jmp	near ptr cm_token6
cm_copy_error3_1:
	jmp	near ptr cm_error
cm_length3_2:
	test	al,20h
	jz	near ptr cm_length3_3
	shld	cx,ax,0ah
	and	cx,3
	lodsb
	xchg	al,ah
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error3_1
	CopyMatch
	jmp	near ptr cm_token0
cm_length3_3:
	test	al,40h
	jz	near ptr cm_length3_4
	shld	cx,ax,9
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error3_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail3_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail3_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token2
cm_match_error4:
	jmp	near ptr cm_error
cm_length3_4:
	test	al,80h
	jz	near ptr cm_length3_5
	shld	cx,ax,8
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error4
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail3_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail3_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token4
cm_length3_5:
	mov	cl,8
	jmp	near ptr cm_length_long
cm_match4:
	jcxz	cm_match_error4
	cmp	cx,113fh
	jz	near ptr cm_sector_end4
	test	al,10h
	jz	near ptr cm_length4_1
	sub	bp,2
	js	short cm_match_error4
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token5
cm_sector_end4:
	mov	dl,8
	jmp	near ptr cm_sector_end
cm_length4_1:
	mov	bx,cx
	test	al,20h
	jz	near ptr cm_length4_2
	shld	cx,ax,0ah
	and	cx,1
	add	cx,3
	sub	bp,cx
	js	short cm_match_error4
	CopyMatch
	jmp	near ptr cm_token7
cm_copy_error4_1:
	jmp	near ptr cm_error
cm_length4_2:
	test	al,40h
	jz	near ptr cm_length4_3
	shld	cx,ax,9
	and	cx,3
	lodsb
	xchg	al,ah
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error4_1
	CopyMatch
	jmp	near ptr cm_token1
cm_length4_3:
	test	al,80h
	jz	near ptr cm_length4_4
	shld	cx,ax,8
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error4_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail4_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail4_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token3
cm_match_error5:
	jmp	near ptr cm_error
cm_length4_4:
	test	ah,1
	jz	near ptr cm_length4_5
	shld	cx,ax,7
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error5
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail4_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail4_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token5
cm_length4_5:
	mov	cl,9
	jmp	near ptr cm_length_long
cm_match5:
	jcxz	cm_match_error5
	cmp	cx,113fh
	jz	near ptr cm_sector_end5
	test	al,20h
	jz	near ptr cm_length5_1
	sub	bp,2
	js	short cm_match_error5
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token6
cm_sector_end5:
	mov	dl,0ah
	jmp	near ptr cm_sector_end
cm_length5_1:
	mov	bx,cx
	test	al,40h
	jz	near ptr cm_length5_2
	shld	cx,ax,9
	and	cx,1
	lodsb
	xchg	al,ah
	add	cx,3
	sub	bp,cx
	js	short cm_match_error5
	CopyMatch
	jmp	near ptr cm_token0
cm_copy_error5_1:
	jmp	near ptr cm_error
cm_length5_2:
	test	al,80h
	jz	near ptr cm_length5_3
	shld	cx,ax,8
	and	cx,3
	lodsb
	xchg	al,ah
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error5_1
	CopyMatch
	jmp	near ptr cm_token2
cm_length5_3:
	test	ah,1
	jz	near ptr cm_length5_4
	shld	cx,ax,7
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error5_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail5_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail5_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token4
cm_match_error6:
	jmp	near ptr cm_error
cm_length5_4:
	test	ah,2
	jz	near ptr cm_length5_5
	shld	cx,ax,6
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error6
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail5_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail5_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token6
cm_length5_5:
	mov	cl,0ah
	jmp	near ptr cm_length_long
cm_match6:
	jcxz	cm_match_error6
	cmp	cx,113fh
	jz	near ptr cm_sector_end6
	test	al,40h
	jz	near ptr cm_length6_1
	sub	bp,2
	js	short cm_match_error6
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token7
cm_sector_end6:
	mov	dl,0ch
	jmp	near ptr cm_sector_end
cm_length6_1:
	mov	bx,cx
	test	al,80h
	jz	near ptr cm_length6_2
	shld	cx,ax,8
	and	cx,1
	lodsb
	xchg	al,ah
	add	cx,3
	sub	bp,cx
	js	short cm_match_error6
	CopyMatch
	jmp	near ptr cm_token1
cm_copy_error6_1:
	jmp	near ptr cm_error
cm_length6_2:
	test	ah,1
	jz	near ptr cm_length6_3
	shld	cx,ax,7
	and	cx,3
	lodsb
	xchg	al,ah
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error6_1
	CopyMatch
	jmp	near ptr cm_token3
cm_length6_3:
	test	ah,2
	jz	near ptr cm_length6_4
	shld	cx,ax,6
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error6_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail6_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail6_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token5
cm_match_error7:
	jmp	near ptr cm_error
cm_length6_4:
	test	ah,4
	jz	near ptr cm_length6_5
	shld	cx,ax,5
	and	cx,0fh
	lodsb
	xchg	al,ah
	add	cx,11h
	sub	bp,cx
	js	short cm_match_error7
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail6_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail6_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token7
cm_length6_5:
	mov	cl,0bh
	jmp	near ptr cm_length_long
cm_match7:
	jcxz	cm_match_error7
	cmp	cx,113fh
	jz	near ptr cm_sector_end7
	test	al,80h
	jz	near ptr cm_length7_1
	sub	bp,2
	js	short cm_match_error7
	mov	dx,si
	mov	si,di
	sub	si,cx
	movs	byte ptr es:[di],byte ptr es:[si]
	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	lodsb
	xchg	al,ah
	jmp	near ptr cm_token0
cm_sector_end7:
	mov	dl,0eh
	jmp	near ptr cm_sector_end
cm_length7_1:
	mov	bx,cx
	test	ah,1
	jz	near ptr cm_length7_2
	shld	cx,ax,7
	and	cx,1
	lodsb
	xchg	al,ah
	add	cx,3
	sub	bp,cx
	js	near ptr cm_match_error7
	CopyMatch
	jmp	near ptr cm_token2
cm_copy_error7_1:
	jmp	near ptr cm_error
cm_length7_2:
	test	ah,2
	jz	near ptr cm_length7_3
	shld	cx,ax,6
	and	cx,3
	lodsb
	xchg	al,ah
	add	cx,5
	sub	bp,cx
	js	short cm_copy_error7_1
	CopyMatch
	jmp	near ptr cm_token4
cm_length7_3:
	test	ah,4
	jz	near ptr cm_length7_4
	shld	cx,ax,5
	and	cx,7
	lodsb
	xchg	al,ah
	add	cx,9
	sub	bp,cx
	js	short cm_copy_error7_1
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail7_1
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail7_1:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token6
cm_copy_error7_2:
	jmp	near ptr cm_error
cm_length7_4:
	test	ah,8
	jz	near ptr cm_length7_5
	shld	cx,ax,4
	and	cx,0fh
	lodsw
	add	cx,11h
	sub	bp,cx
	js	short cm_copy_error7_2
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_copy_tail7_2
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_copy_tail7_2:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	jmp	near ptr cm_token0
cm_length7_5:
	mov	cl,0ch

; Longer lengths use the common decoder instead of the phase tables.
cm_length_long:
	shr	ax,cl
	push	cx
	mov	dx,[si]
	neg	cl
	add	cl,10h
	shl	dx,cl
	or	ax,dx
	shr	ax,1
	jnc	near ptr cm_length_65
	MaskAx	1fh
	add	al,21h
	xchg	ax,cx
	mov	al,6
cm_long_copy:
	sub	bp,cx
	js	near ptr cm_long_error
	mov	dx,si
	mov	si,di
	sub	si,bx
	cmp	bx,1
	jz	near ptr cm_long_copy_bytes
	shr	cx,1
	rep	movs	word ptr es:[di],word ptr es:[si]
	adc	cx,cx
cm_long_copy_bytes:
	rep	movs	byte ptr es:[di],byte ptr es:[si]
	mov	si,dx
	pop	dx
	add	dl,al
	cmp	dl,18h
	jc	near ptr cm_long_load_word
	inc	si
	lodsw
	sub	dl,18h
	add	dl,dl
	movzx	bx,dl
	jmp	word ptr cs:cm_decode[bx]
cm_long_load_word:
	cmp	dl,10h
	jnc	near ptr cm_long_realign
	dec	si
	add	dl,8
cm_long_realign:
	lodsw
	sub	dl,10h
	add	dl,dl
	movzx	bx,dl
	jmp	word ptr cs:cm_decode[bx]
cm_long_error:
	pop	cx
	jmp	short cm_error
cm_length_65:
	shr	ax,1
	jnc	near ptr cm_length_129
	MaskAx	3fh
	add	al,41h
	xchg	ax,cx
	mov	al,8
	jmp	short cm_long_copy
cm_length_129:
	shr	ax,1
	jnc	near ptr cm_length_257
	MaskAx	7fh
	add	ax,81h
	xchg	ax,cx
	mov	al,0ah
	jmp	short cm_long_copy
cm_length_257:
	shr	ax,1
	jnc	short cm_long_error
	mov	ah,0
	add	ax,101h
	xchg	ax,cx
	mov	al,0ch
	jmp	near ptr cm_long_copy

; A reserved distance marks the end of a 512-byte output sector.
cm_sector_end:
	test	bp,bp
	jnz	near ptr cm_short_sector
	dec	word ptr cs:cm_sectors
	jz	near ptr cm_done
	jmp	near ptr cm_next_sector
cm_short_sector:
	pop	cx
	pop	bp
	dec	word ptr cs:cm_sectors
	jnz	near ptr cm_error
cm_done:
	mov	dh,1
	clc
	mov	bp,cs:cm_saved_bp
	retf
cm_error:
	stc
	mov	bp,cs:cm_saved_bp
	retf

cSeg	ends
	end	cm_entry
