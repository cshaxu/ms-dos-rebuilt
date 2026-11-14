Bios_Data segment para public 'bios_data'
 org 8
IsWin386 label byte
bios_flags dw 0
Bios_Data ends
Bios_Code segment para public 'bios_code'
 org 0dch
 irp aa,<02,08,09,0a,0b,0c,0d,0e,70,72,73,74,76,77>
 db aa&h
int19old&aa dd -1
 endm
Bios_Code ends
entrysize equ 8
defaultcount equ 9
allocbyte equ 0
intlevel equ 1
savedsp equ 2
savedss equ 4
newsp equ 6
SysInitSeg segment para public 'system_init'
 assume cs:SysInitSeg,ds:nothing,es:nothing,ss:nothing
	.386

; Hardware interrupt stacks and the old interrupt vectors.

	dw	0
stack_count label word
stackcount	dw	defaultcount
stackat	dw	0
stack_size label word
stacksize	dw	100h
stack_addr label dword
stacks	dw	0,0
firstentry	dw	offset stacks
lastentry	dw	offset stacks+(defaultcount*entrysize)-entrysize
nextentry	dw	offset stacks+(defaultcount*entrysize)-entrysize
old02	dd	0
public int02,old02
int02	proc	far
	call	do_int_stacks
	dw	old02
int02	endp	
old08	dd	0
public int08,old08
int08	proc	far
	call	do_int_stacks
	dw	old08
int08	endp	
old09	dd	0
public int09,old09
int09	proc	far
	jmp	short keyboard_lbl
        nop
	db	0
keyboard_lbl label near
	call	do_int_stacks
	dw	old09
int09	endp	
old70	dd	0
public int70,old70
int70	proc	far
	call	do_int_stacks
	dw	old70
int70	endp	
	irp	a,<0a,0b,0c,0d,0e,72,73,74,76,77>
public int&a,old&a,firstflag&a
int&a proc far
	jmp	short entry_int&a&_stk
old&a   dd      0
	dw	424Bh
firstflag&a db  0
	jmp	short intret_&a
	db	7 dup (0)
entry_int&a&_stk:
	call	do_int_stacks
	dw	old&a
intret_&a:
        iret
int&a endp
        endm
; Switch stacks and call the original interrupt handler.

do_int_stacks proc near
	push	eax
	push	bp
	push	es
	mov	es,word ptr cs:[stacks+2]
	mov	bp,cs:[nextentry]
	mov	al,1
	xchg	es:byte ptr [bp],al
	cmp	al,0
	jne	short notfree02
	sub	word ptr cs:[nextentry],8
found02:
	mov	es:word ptr [bp+2],sp
	mov	es:word ptr [bp+4],ss
	mov	ax,bp
	mov	bp,es:word ptr [bp+6]
	cmp	es:[bp],ax
	jne	short foundbad02
	mov	ax,es
	mov	es,bp
	mov	bp,sp
	mov	bp,[bp+8]
	mov	ss,ax
	mov	sp,es
	mov	es,ax
	mov	bp,cs:[bp]
        pushf
	call	dword ptr cs:[bp]
	mov	bp,sp
	mov	bp,es:[bp]
	mov	ss,es:word ptr [bp+4]
	mov	sp,es:word ptr [bp+2]
	mov	es:byte ptr [bp],0
	mov	cs:[nextentry],bp
	pop	es
	pop	bp
	pop	eax
	add	sp,2
        iret
notfree02:
	cmp	al,1
	je	short findnext02
	xchg	es:byte ptr [bp],al
	jmp	short findnext02
foundbad02:
	cmp	bp,cs:[firstentry]
	jc	short findnext02
	mov	bp,ax
	mov	es:byte ptr [bp],3
findnext02:
	mov	bp,cs:[lastentry]
lploopp:
	cmp	es:byte ptr [bp],0
	jne	short inuse
	mov	al,1
	xchg	es:byte ptr [bp],al
	cmp	al,0
	je	short found02
	cmp	al,1
	je	short inuse
	mov	es:byte ptr [bp],al
inuse:
	cmp	bp,cs:[firstentry]
	je	short fatal
	sub	bp,8
	jmp	short lploopp
do_int_stacks endp
; Display the stack failure message after setting the VM focus.

fatal	proc	near
	cli	; disable and mask interrupts
	mov	al,0ffh
	out	021h,al
	out	0a1h,al
	mov	ax,Bios_Data
	mov	ds,ax
	test	byte ptr ds:[IsWin386],40h
	jz	short fatal_loop_setup
	sub	di,di
	mov	es,di
	mov	bx,15h
	mov	ax,1684h
	int	2fh                     ; get V86 API entry
	mov	ax,es
	or	ax,di
	jz	short fatal_loop_setup
	push	cs
	mov	ax,offset fatal_loop_setup
	push	ax
	push	es
	push	di
	mov	ax,1                    ; set focus
        retf
fatal_loop_setup:
	push	cs
	pop	ds
	mov	si,offset endstackcode
fatal_loop:
        lodsb
	or	al,al
	jz	short fatal_done
	mov	bl,7
	mov	ah,14
	int	010h
	jmp	short fatal_loop
fatal_done:
        hlt
	jmp	short fatal_done
fatal	endp	
	.8086
endstackcode label byte

 org 0f40h
temp_bcode_seg dw 0
 org 3d0eh
 assume ds:SysInitSeg
stackinit	proc near

IFDEF DOS7_CONFIG
; Initialize the stack table and clear the stack area.
	push	cs
	pop	ds
	mov	bp,word ptr [stack_addr]
	mov	es:firstentry,bp
	mov	ax,entrysize
	mov	cx,[stack_count]
	mul	cx
	add	ax,bp
	mov	es:stackat,ax
	mov	bx,ax
	sub	bx,2
	mov	di,es:stackat
	mov	ax,[stack_size]
	mul	cx
	mov	cx,ax
	xor	ax,ax
	push	es
	pop	ds
	assume	ds:sysinitseg
	mov	es,word ptr [stacks+2]
	cld
	rep	stosb
	mov	cx,stackcount
buildloop7:
	mov	es:byte ptr allocbyte[bp],al
	mov	es:byte ptr intlevel[bp],al
	mov	es:word ptr savedsp[bp],ax
	mov	es:word ptr savedss[bp],ax
	add	bx,stacksize
	mov	es:word ptr newsp[bp],bx
	mov	es:[bx],bp
	add	bp,entrysize
	loop	buildloop7
	sub	bp,entrysize
	mov	lastentry,bp
	mov	nextentry,bp
	xor	ax,ax
	mov	es,ax
	cli
ELSE

	push	ax
	push	ds
	push	es
	push	bx
	push	cx
	push	dx
	push	di
	push	si
	push	bp

;currently es -> stack code area

	mov	ax, cs:[stack_count]		;defined in cs
	mov	es:[stackcount], ax		;defined in stack code area
	mov	ax, [stack_size]		;in cs
	mov	es:[stacksize], ax
	mov	ax, word ptr cs:[stack_addr]	; offset
	mov	word ptr es:[stacks], ax
	mov	ax, word ptr cs:[stack_addr+word] ; segment
	mov	word ptr es:[stacks+word], ax

; initialize the data fields with the parameters

; "firstentry" will always be at stacks

	mov	bp, word ptr es:stacks		; get offset of stack
	mov	es:firstentry,bp

; the stacks will always immediately follow the table entries

	mov	ax,entrysize
	mov	cx,es:stackcount
	mul	cx
	add	ax,bp
	mov	es:stackat,ax
	mov	bx,ax
	sub	bx,2

; zero the entire stack area to start with

	mov	di,es:stackat
	mov	ax,es:stacksize
	mul	cx
	mov	cx,ax
	xor	ax,ax
	push	es
	pop	ds				;ds = relocated stack code seg.
	assume	ds:nothing

;now, ds -> stack code area

	mov	es, word ptr ds:[stacks+2]	; get segment of stack area.
	cld
	rep	stosb

	mov	cx, ds:stackcount

; loop for "count" times, building a table entry
;  cs = sysinitseg, ds = relocated stack code seg , es = segment of stack space
;  cx = number of entries
;  es:bp => base of stacks - 2
;  es:bx => first table entry

buildloop:
	mov	es:byte ptr allocbyte[bp],free
	mov	es:byte ptr intlevel[bp],al	;ax = 0
	mov	es:word ptr savedsp[bp],ax
	mov	es:word ptr savedss[bp],ax
	add	bx,ds:stacksize
	mov	es:word ptr newsp[bp],bx
	mov	es:[bx],bp
	add	bp,entrysize

	loop	buildloop

	sub	bp,entrysize
	mov	ds:lastentry,bp
	mov	ds:nextentry,bp

	push	ds
	mov	ax, 0f000h			;look at the model byte
	mov	ds, ax
	cmp	ds:byte ptr [0fffeh], mdl_convert ;convertible?
	pop	ds
	jne	skip_disablenmis

	mov	al,07h				; disable convertible nmis
	out	72h,al

skip_disablenmis:
	xor	ax,ax
	mov	es,ax				;es - segid of vector table at 0
	assume	es:nothing			;ds - relocated stack code segment

	cli

ENDIF

	irp	aa,<02,08,09,70>

	mov	si,aa&h*4		;pass where vector is to be adjusted
	mov	di, offset int19old&aa	;we have to set old&aa for int19 handler too.
	mov	bx,offset old&aa	;pass where to save original owner pointer
	mov	dx,offset int&aa	;pass where new handler is
	call	new_init_loop		;adjust the vector to new handler,
					;  saving pointer to original owner
	endm

	irp	aa,<0a,0b,0c,0d,0e,72,73,74,76,77>	;shared interrupts

	mov	si,aa&h*4		;pass where vector is to be adjusted
	push	ds			;save relocated stack code segment
	lds	bx, es:[si]		;ds:bx -> original interrupt handler
	push	ds
	pop	dx			;dx = segment value

	cmp	dx,0
	jz	int&aa&_first

	cmp	byte ptr ds:[bx],0cfh	;does vector point to an iret?
	jz	int&aa&_first

	cmp	word ptr ds:[bx.6],424bh ;magic offset (see int&aa, msstack.inc)
	jz	int&aa&_not_first

	cmp	dx,0f000h		;rom bios segment
	jnz	int&aa&_not_first

	push	es
	push	dx
	mov	dx,0f000h
	mov	es,dx
	cmp	bx,word ptr es:0ff01h
       	pop	dx
	pop	es
	jz	int&aa&_first

int&aa&_not_first:			;not the first. we are going to hook vector.
	pop	ds
	mov	di, offset int19old&aa	;we have to set old&aa for int19 handler too.
	mov	bx, offset old&aa	;pass where to save original owner pointer
	mov	dx, offset int&aa	;pass where new handler is
	call	new_init_loop		;adjust the vector to new handler, saving
					;pointer to original owner.
	jmp	short int&aa&_end
int&aa&_first:				 ;the first. don't have to hook stack code.
	pop	ds
int&aa&_end:

	endm

IFDEF DOS7_CONFIG
	sti
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data
	or	byte ptr [bios_flags+1],1
	ret
ELSE
	push	ds
	mov	ax, 0f000h		;loook at the model byte
	mov	ds, ax
	cmp	ds:byte ptr [0fffeh], mdl_convert	;pc convertible?
	pop	ds
	jne	skip_enablenmis

	mov	al,27h				; enable convertible nmis
	out	72h,al

skip_enablenmis:
	sti
	mov	ax,Bios_Data
	mov	ds,ax
	assume	ds:Bios_Data


	mov	[int19sem],1		; indicate that int 19
					; initialization is complete

	pop	bp			; restore all
	pop	si
	pop	di
	pop	dx
	pop	cx
	pop	bx

	pop	es
	pop	ds
	assume	ds:sysinitseg

	pop	ax
	ret
ENDIF
stackinit	endp

new_init_loop proc near

;input: si=ofset into vector table of the particular int vector being adjusted
;	bx=ds:offset of oldxx, where will be saved the pointer to original owner
;	dx=ds:offset of intxx, the new interrupt handler
;	di=offset value of int19old&aa variable in bios.
;	es=zero, segid of vector table
;	ds=relocated stack code segment

IFDEF DOS7_CONFIG
	mov	ax,es:[si]
	mov	word ptr ds:[bx],ax
	mov	cx,es:[si+2]
	mov	word ptr ds:[bx+2],cx
	push	ds
	mov	ds,cs:temp_bcode_seg
	mov	word ptr ds:[di],ax
	mov	word ptr ds:[di+2],cx
	pop	ds
	mov	word ptr es:[si],dx
	mov	word ptr es:[si+2],ds
	ret
ELSE
	mov	ax,es:[si+0]		;remember offset in vector
	mov	word ptr ds:[bx],ax	; to original owner in ds
	mov	ax,es:[si+2]		;remember segid in vector
	mov	word ptr ds:[bx]+2,ax	; to original owner in ds

	push	ds
	mov	ax,Bios_Data
	mov	ds,ax			;set int19oldxx value in bios for
	mov	ax,es:[si+0]		;int 19 handler
	mov	word ptr ds:[di],ax
	mov	ax,es:[si+2]
	mov	word ptr ds:[di]+2,ax
	pop	ds

	mov	word ptr es:[si+0],dx  ;set vector to point to new int handler
	mov	es:[si+2],ds
	ret
ENDIF
new_init_loop endp
SysInitSeg ends
 end stackinit
