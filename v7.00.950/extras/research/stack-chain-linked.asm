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
 org 1fa6h
 dw 0
win386_stack_seg dw 0
win386_stack_size dw 0
win386_nextstack dw 0,0
 dw 0,0,0
 dw 0,50h,200h,0,0,540h
 dw 0
win386_stack_code_seg dw 0
win386_stack_code_size dw 0
Bios_Code ends
entrysize equ 8
defaultcount equ 9
allocbyte equ 0
intlevel equ 1
savedsp equ 2
savedss equ 4
newsp equ 6
devmark_id equ 0
devmark_seg equ 1
devmark_size equ 3
devmark_dum equ 5
arena_owner equ 1
arena_name equ 8
devmark_stk equ 'S'
std_con_string_output equ 9
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
 org 0f23h
alloclim dw 0
 org 0f40h
temp_bcode_seg dw 0
 org 0feah
memhi dw 0
 org 19f0h
stall: hlt
 jmp short stall
 org 1c14h
print_indexed proc near
	xchg	si,dx
	pop	si
	cld
	lods	word ptr cs:[si]
	push	si
	xchg	si,dx
	push	bx
	and	ax,7fffh
	mov	bx,ax
	shl	bx,1
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[bx+sysinit_msg_table]
	mov	ah,std_con_string_output
	int	21h
	pop	bx
	ret
print_indexed endp
 org 3941h
 assume ds:SysInitSeg
stack_allocate_start:
; Allocate the interrupt code, message and hardware stack area.

	mov	ax,entrysize
	add	ax,[stack_size]
	mul	[stack_count]
	push	ax
	call	pararound
	mov	bx,ax

	mov	cx,offset endstackcode
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_stack_msg_index]
stack_msg_size:
	lodsb
	inc	cx
	or	al,al
	jnz	stack_msg_size
	mov	ax,cx
	call	pararound
	push	ax
	add	ax,bx
	mov	bh,devmark_stk
	mov	bl,[stack_high]
	call	alloc_marked_block
	pop	ax
	add	ax,cx
	mov	word ptr [stack_addr],0
	mov	word ptr [stack_addr+2],ax
	mov	es,cx

; Relocate the interrupt code and append its stack failure message.

	mov	cx,offset endstackcode
	xor	si,si
	xor	di,di
	cld
	rep	movsb
	push	ax
	mov	si,offset sysinit_msg_base
	add	si,word ptr [sysinit_stack_msg_index]
stack_msg_copy:
	lodsb
	stosb
	or	al,al
	jnz	stack_msg_copy
	pop	ax
	pop	cx

; Fill the Windows instance entries for the stacks and interrupt code.

	push	ds
	mov	ds,temp_bcode_seg
	assume	ds:Bios_Code
	mov	win386_stack_seg,ax
	mov	win386_stack_size,cx
	add	cx,offset endstackcode
	mov	win386_stack_code_seg,es
	mov	win386_stack_code_size,cx
	mov	bx,offset nextentry
	mov	win386_nextstack,bx
	mov	word ptr [win386_nextstack+2],es
	mov	word ptr [win386_nextstack+4],2
	pop	ds
	assume	ds:sysinitseg
	call	stackinit
	push	cs
	pop	ds
 org 3b88h
pararound proc near
 add ax,15
 rcr ax,1
 shr ax,1
 shr ax,1
 shr ax,1
 ret
pararound endp
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
 org 65ach
stack_high db 0
 org 66d0h
DevSize dw 0
 org 66e1h
DevUMBAddr dw 0
DevUMBSize dw 0
DevUMBFree dw 0
 org 80aah
SpaceInUMB?	proc	near

		assume	ds:nothing, es:nothing

		mov	ax, DevUMBSize
		add	ax, DevUMBAddr		; End of UMB
		sub	ax, DevUMBFree		; - Free = Remaining space
		or	ax, ax			; Nospace ?
		jnz	@f
		stc
		ret
@@:
		dec	ax			; space for sub-arena
		cmp	ax, DevSize		; do we have space ?
		ret
SpaceInUMB?	endp
PrepareMark	proc	near

		push	ds
		mov	ds, ax
		mov	word ptr ds:[arena_owner], 8
		mov	word ptr ds:[arena_name], 'DS'
		pop	ds

		inc	ax
		mov	DevUMBAddr, ax
		mov	DevUMBFree, ax
		mov	DevUMBSize, bx		; update the UMB Variables
		ret

PrepareMark	endp
GetUMBForDev	proc	near

		assume	ds:nothing, es:nothing

		mov	bx, 0ffffh
		mov	ax, 4800h
		int	21h

		or	bx, bx
		jz	gufd_err

		dec	bx
		cmp	DevSize, bx
		ja	gufd_err
		inc	bx

		mov	ax, 4800h
		int	21h
		jc	gufd_err

		dec	ax
		call	PrepareMark

		clc				; mark no error
		ret
gufd_err:
		xor	ax, ax
		mov	DevUMBSize, ax		; erase the previous values
		mov	DevUMBAddr, ax
		mov	DevUMBFree, ax
		stc
		ret
GetUMBForDev	endp
 org 81efh
check_low_memory proc near
	push	ax
	mov	ax,cs:[memhi]
	cmp	cs:[alloclim],ax
	jbe	low_memory_error
	pop	ax
	ret
low_memory_error:
	push	cs
	pop	ds
	call	print_indexed
	dw	800eh
	jmp	stall
check_low_memory endp
 org 852fh
ShrinkUMB	proc	near
		cmp	DevUMBAddr, 0
		je	su_exit
		push	es
		push	bx
		mov	bx, DevUMBFree
		sub	bx, DevUMBAddr
		mov	es, DevUMBAddr
		mov	ax, 4a00h
		int	21h
		mov	ax, es
		dec	ax
		mov	es, ax
		mov	word ptr es:[arena_owner], 8
		pop	bx
		pop	es
su_exit:
		ret
ShrinkUMB	endp
 org 858ah
alloc_marked_block proc near
	push	ax
	or	bl,bl
	jz	alloc_marked_low
	mov	ds:[DevSize],ax
	call	SpaceInUMB?
	jnc	alloc_marked_high
	push	bx
	call	ShrinkUMB
	call	GetUMBForDev
	pop	bx
	jc	alloc_marked_low
alloc_marked_high:
	pop	dx
	mov	cx,ds:[DevUMBFree]
	call	setdevmark7
	mov	ax,dx
	add	dx,cx
	mov	ds:[DevUMBFree],dx
	jmp	short alloc_marked_done
alloc_marked_low:
	pop	dx
	mov	cx,ds:[memhi]
	call	setdevmark7
	add	ds:[memhi],dx
	inc	ds:[memhi]
	call	check_low_memory
	mov	ax,dx
alloc_marked_done:
	ret
alloc_marked_block endp
setdevmark7 proc near
	push	bx
	mov	bl,0
	cmp	bh,'R'
	je	mark_internal
	cmp	bh,'G'
	je	mark_internal
	cmp	bh,'Y'
	je	mark_internal
	cmp	bh,'H'
	jne	mark_write
mark_internal:
	mov	bl,bh
	mov	bh,'I'
mark_write:
	mov	es,cx
	mov	es:[devmark_id],bh
	mov	es:[devmark_dum+2],bl
	inc	cx
	mov	es:[devmark_seg],cx
	mov	es:[devmark_size],dx
	pop	bx
	ret
setdevmark7 endp
 org 0a568h
 include sysimsg.inc
SysInitSeg ends
 end stack_allocate_start
