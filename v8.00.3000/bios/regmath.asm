	page	,132
	title	uldiv - unsigned long divide routine
;***
;uldiv.asm - unsigned long divide routine
;
;	Copyright (c) 1985-1991, Microsoft Corporation. All rights reserved.
;
;Purpose:
;	defines the unsigned long divide routine
;
;Revision History:
;	11-29-83  DFW	initial version
;	06-01-84  RN	modified to use cmacros
;	10-23-87  SKS	fixed off-by-1 error for dividend close to 2**32.
;	05-18-89  SKS	Remove redundant "MOV SP,BP" from epilog
;	11-28-89  GJF	Fixed copyright
;
;       06-05-91  MD    Stolen from C runtime library for use with POWER.EXE
;
;*******************************************************************************

;***
;uldiv - unsigned long divide
;
;Purpose:
;	Does a unsigned long divide of the arguments.  Arguments are
;	not changed.
;
;Entry:
;	Arguments are passed on the stack:
;		1st pushed: divisor (DWORD)
;		2nd pushed: dividend (DWORD)
;
;Exit:
;	DX:AX contains the quotient (dividend/divisor)
;	NOTE: this routine removes the parameters from the stack.
;
;Uses:
;	CX
;
;Exceptions:
;
;*******************************************************************************
	.386
_TEXT	segment word public use16 'RESUME_CODE'
	assume	cs:_TEXT

	public	__aFlshl,__aFulshr
;
; Far long shifts use DX:AX as the value and CL as the count.
;
__aFlshl proc far
	xor	ch,ch
	jcxz	LshlDone
LshlLoop:
	shl	ax,1
	rcl	dx,1
	loop	LshlLoop
LshlDone:
	ret
__aFlshl endp

	db 0
; Unsigned long remainder, with the same far stack convention as ULDIV.
	public __aFulrem
__aFulrem proc far
	push	bp
	mov	bp,sp
	push	bx
	mov	ax,[bp+0ch]
	or	ax,ax
	jnz	short ulrem_wide
	mov	cx,[bp+0ah]
	mov	ax,[bp+8]
	xor	dx,dx
	div	cx
	mov	ax,[bp+6]
	div	cx
	mov	ax,dx
	xor	dx,dx
	jmp	short ulrem_done
ulrem_wide:
	mov	cx,ax
	mov	bx,[bp+0ah]
	mov	dx,[bp+8]
	mov	ax,[bp+6]
ulrem_shift:
	shr	cx,1
	rcr	bx,1
	shr	dx,1
	rcr	ax,1
	or	cx,cx
	jnz	short ulrem_shift
	div	bx
	mov	cx,ax
	mul	word ptr [bp+0ch]
	xchg	ax,cx
	mul	word ptr [bp+0ah]
	add	dx,cx
	jc	short ulrem_adjust
	cmp	dx,[bp+8]
	ja	short ulrem_adjust
	jc	short ulrem_result
	cmp	ax,[bp+6]
	jna	short ulrem_result
ulrem_adjust:
	sub	ax,[bp+0ah]
	sbb	dx,[bp+0ch]
ulrem_result:
	sub	ax,[bp+6]
	sbb	dx,[bp+8]
	neg	dx
	neg	ax
	sbb	dx,0
ulrem_done:
	pop	bx
	pop	bp
	retf	8
__aFulrem endp

__aFulshr proc far
	xor	ch,ch
	jcxz	LshrDone
LshrLoop:
	shr	dx,1
	rcr	ax,1
	loop	LshrLoop
LshrDone:
	ret
__aFulshr endp

	db 0
__aFuldiv proc far
	public	__aFuldiv

        push    bp
        mov     bp,sp

	push	bx
	push	si

; Set up the local stack and save the index registers.	When this is done
; the stack frame will look as follows (assuming that the expression a/b will
; generate a call to uldiv(a, b)):
;
;		-----------------
;		|		|
;		|---------------|
;		|		|
;		|--divisor (b)--|
;		|		|
;		|---------------|
;		|		|
;		|--dividend (a)-|
;		|		|
;		|---------------|
;		| return addr** |
;		|---------------|
;	BP----->|    old BP	|
;		|---------------|
;		|      BX	|
;		|---------------|
;	SP----->|      SI	|
;		-----------------
;
; ** - 2 bytes if small/compact model; 4 bytes if medium/large model

DVND	equ	6
DVSR	equ	10

;
; Now do the divide.  First look to see if the divisor is less than 64K.
; If so, then we can use a simple algorithm with word divides, otherwise
; things get a little more complex.
;

	mov	ax,[bp+DVSR+2] ; check to see if divisor < 64K
	or	ax,ax
	jnz	short L1		; nope, gotta do this the hard way
	mov	cx,[bp+DVSR] ; load divisor
	mov	ax,[bp+DVND+2] ; load high word of dividend
	xor	dx,dx
	div	cx		; get high order bits of quotient
	mov	bx,ax		; save high bits of quotient
	mov	ax,[bp+DVND] ; dx:ax <- remainder:lo word of dividend
	div	cx		; get low order bits of quotient
	mov	dx,bx		; dx:ax <- quotient hi:quotient lo
	jmp	short L2	; restore stack and return

;
; Here we do it the hard way.  Remember, ax contains DVSRHI
;

L1:
	mov	cx,ax		; cx:bx <- divisor
	mov	bx,[bp+DVSR]
	mov	dx,[bp+DVND+2] ; dx:ax <- dividend
	mov	ax,[bp+DVND]
L3:
	shr	cx,1		; shift divisor right one bit; hi bit <- 0
	rcr	bx,1
	shr	dx,1		; shift dividend right one bit; hi bit <- 0
	rcr	ax,1
	or	cx,cx
	jnz	short L3		; loop until divisor < 64K
	div	bx		; now divide, ignore remainder
	mov	si,ax		; save quotient

;
; We may be off by one, so to check, we will multiply the quotient
; by the divisor and check the result against the orignal dividend
; Note that we must also check for overflow, which can occur if the
; dividend is close to 2**32 and the quotient is off by 1.
;

	mul	word ptr [bp+DVSR+2] ; QUOT * [bp+DVSR+2]
	xchg	ax,cx		; "mov cx,ax" but only 1 byte
	mov	ax,[bp+DVSR]
	mul	si		; QUOT * [bp+DVSR]
	add	dx,cx		; DX:AX = QUOT * DVSR
	jc	short L4		; carry means Quotient is off by 1

;
; do long compare here between original dividend and the result of the
; multiply in dx:ax.  If original is larger or equal, we are ok, otherwise
; subtract one (1) from the quotient.
;

	cmp	dx,[bp+DVND+2] ; compare hi words of result and original
	ja	short L4		; if result > original, do subtract
	jb	short L5		; if result < original, we are ok
	cmp	ax,[bp+DVND] ; hi words are equal, compare lo words
	jbe	short L5		; if less or equal we are ok, else subtract
L4:
	dec	si		; subtract 1 from quotient
L5:
	xor	dx,dx		; dx:ax <- quotient
	xchg	ax,si		; "mov ax,si" but only 1 byte

;
; Just the cleanup left to do.	dx:ax contains the quotient.
; Restore the saved registers and return.
;

L2:

	pop	si
	pop	bx

        pop     bp
	ret	8
__aFuldiv endp

	db 0
__aFlmul proc far
        public  __aFlmul

MUL_A equ 6
MUL_B equ 10

;
;	AHI, BHI : upper 16 bits of A and B
;	ALO, BLO : lower 16 bits of A and B
;
;	      ALO * BLO
;	ALO * BHI
; +	BLO * AHI
; ---------------------

        push    bp
        mov     bp,sp

	mov	ax,[bp+MUL_A+2]
	mov	cx,[bp+MUL_B+2]
	or	cx,ax		;test for both hiwords zero.
	mov	cx,[bp+MUL_B]
	jnz	short lmul_wide		;both are zero, just mult ALO and BLO

	mov	ax,[bp+MUL_A]
	mul	cx

	pop	bp
	ret 8

lmul_wide:
	push	bx

	mul	cx		;ax has AHI, cx has BLO, so AHI * BLO
	mov	bx,ax		;save result

	mov	ax,[bp+MUL_A]
	mul	word ptr [bp+MUL_B+2] ;ALO * BHI
	add	bx,ax		;bx = ((ALO * BHI) + (AHI * BLO))

	mov	ax,[bp+MUL_A]	;cx = BLO
	mul	cx		;so dx:ax = ALO*BLO
	add	dx,bx		;now dx has all the LO*HI stuff

	pop	bx
        pop     bp
        ret 8
__aFlmul endp

_TEXT	ends
	end
