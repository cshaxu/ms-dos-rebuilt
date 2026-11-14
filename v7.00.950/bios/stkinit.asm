	page	,160
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	title	bios	system initialization
;
; Hardware interrupt stack handlers and device initialization request storage.
;

MULTI_CONFIG equ 1

break	macro	; dummy empty macro
	endm

	.xlist
	include version.inc
	include biosseg.inc
	include	bpb.inc
	include sysvar.inc
	include dpb.inc
	include curdir.inc
	include pdb.inc
	include exe.inc
	include sf.inc
	include arena.inc
	include syscall.inc
	include devsym.inc
	include ioctl.inc
	include biostruc.inc
	include dossym.inc
	include	dosmac.inc
	include	mult.inc
	include	oemconf.inc
	.list

Bios_Code	segment
	irp	aa,<02,08,09,0a,0b,0c,0d,0e,70,72,73,74,76,77>
	endm

Bios_Code	ends

	.xlist
	include devmark.inc
	include cputype.inc
	.list


true	equ	0ffffh
false	equ	0
cr	equ	13
lf	equ	10
tab	equ	9

;multMULT		equ	4ah
multMULTGETHMAPTR	equ	1
multMULTALLOCHMA	equ	2
multMULTALLOCHMA7 equ 3


; Boot options flags for ROMDOS

ifdef ROMDOS

BF_NoConfig	=	00000001b	; No config.sys processing
BF_DefaultMask	=	00000110b	; Bits to indicate default drive:
BF_DefFloppy	=	00000000b	; 	First floppy drive (00)
BF_DefHard	=	00000010b 	;	First hard drive   (80)
BF_DefROM	=	00000100b	;	ROM drive          (7F)

endif

stacksw equ	true			;include switchable hardware stacks
mycds_size equ	88			; size of curdir_list. if it is not
					;the same, then will generate compile error.

if DEBUG				; BUGBUG - Jeez, remove this!
  dossize equ	0b200h
else
  dossize equ	0a000h
endif

	if	ibmjapver
NOEXEC  equ     TRUE
	else
NOEXEC  equ     FALSE
	endif

;     if mycds_size <> curdirlen,then force a compilatiaon error.

	if	mycds_size ne curdirlen
	%out	!!! sysinit1 compilation failed. different cds size !!!
	.erre	ycds_size eq curdirlen
	endif


	ifdef	TAIWAN
	endif

;---------------------------------------

Bios_Data	segment 

;equates for main stack and stack initialization program

	if	stacksw


entrysize   equ     8

mincount    equ     8
defaultcount equ    9
maxcount    equ     64

minsize     equ     32
defaultsize equ     128
maxsize     equ     512

allocbyte   equ     0
intlevel    equ     1
savedsp     equ     2
savedss     equ     4
newsp	    equ     6

free	    equ     0
allocated   equ     1
overflowed  equ     2
clobbered   equ     3


;	BIOS flags used by the fatal stack error handler.

	extrn	bios_flags:word
	endif


;---------------------------------------
; Multi-track option values
multrk_on equ	10000000b		;user spcified mutitrack=on,or system turns
					; it on after handling config.sys file as a
					; default value,if multrk_flag = multrk_off1.
multrk_off1 equ 00000000b		;initial value. no "multitrack=" command entered.
multrk_off2 equ 00000001b		;user specified multitrack=off.

;


ifdef ROMDOS
endif

Bios_Data	ends


sysinitseg segment 
	assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing


ifdef   MULTI_CONFIG
endif


	ifdef	dblspace_hooks
	endif

IFDEF	CONFIGPROC
ENDIF ; CONFIGPROC
	if	noexec
	endif

IFDEF	CONFIGPROC

ENDIF ; CONFIGPROC


IFDEF	POWER
ENDIF

	public	stack_count,stack_size,stack_addr
	public	stackcount,stacksize,stackat,stacks,firstentry,lastentry,nextentry
sysinit$:
	if	stacksw
.sall

;	interrupt level 2, 3, 4, 5, 6, 7,(10, 11, 12, 14, 15 - at level)
;	should follow the standard interrupt sharing scheme which has
;	a standard header structure.
;	fyi, the following shows the relations between
;	the interrupt vector and interrupt level.
; vec(hex)    2  8  9  a  b  c	d  e  70  72  73  74  76  77
; lvl(deci)   9  0  1  2  3  4	5  6   8  10  11  12  14  15
;	msstack module modifies the following interrupt vectors
;	to meet the standard interrupt sharing standard;
;	  a, b, c, d, e, 72, 73, 74, 76, 77.
;	also, for interrupt level 7 and 15, the firstflag in a standard header
;	should be initialized to indicat whether this interrupt handler is
;	the first (= 80h) or not.  the firstflag entry of int77h's
;	program header is initialized in this module.
;	firstflag is only meaningful for interrupt level 7 and 15.
;

;  user specifies the number of stack elements - default = 9
;						 minimum = 8
;						 maximum = 64
;
;  intercepts asynchronous hardware interrupts only
;
;  picks a stack from pool of stacks and switches to it
;
;  calls the previously saved interrupt vector after pushing flags
;
;  on return, returns the stack to the stack pool
;


; this is a modification of stacks:
; 1. to fix a bug which was causing the program to take up too much space.
; 2. to dispense stack space from hi-mem first rather than low-mem first.
;    . clobbers the stack that got too big instead of innocent stack
;    . allows system to work if the only stack that got too big was the most
;      deeply nested one
; 3. disables nmi interrupts while setting the nmi vector.
; 4. double checks that a nested interrupt didn't get the same stack.
; 5. intercepts ints 70, 72-77 for pc-ats and other future products

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
;
; Switch stacks and call the original interrupt handler.
; The word following the near call identifies the saved interrupt vector.
; On return, restore the interrupted stack and release its allocated entry.
;

do_int_stacks proc near
	push	eax
	push	bp
	push	es
	mov	es,word ptr cs:[stacks+2]
	mov	bp,cs:[nextentry]
	mov	al,allocated
	xchg	es:byte ptr allocbyte[bp],al
	cmp	al,free
	jne	short notfree02
	sub	word ptr cs:[nextentry],entrysize
found02:
	mov	es:word ptr savedsp[bp],sp
	mov	es:word ptr savedss[bp],ss
	mov	ax,bp
	mov	bp,es:word ptr newsp[bp]
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
	mov	ss,es:word ptr savedss[bp]
	mov	sp,es:word ptr savedsp[bp]
	mov	es:byte ptr allocbyte[bp],free
	mov	cs:[nextentry],bp
	pop	es
	pop	bp
	pop	eax
	add	sp,2
	iret
notfree02:
	cmp	al,allocated
	je	short findnext02
	xchg	es:byte ptr allocbyte[bp],al
	jmp	short findnext02
foundbad02:
	cmp	bp,cs:[firstentry]
	jc	short findnext02
	mov	bp,ax
	mov	es:byte ptr allocbyte[bp],clobbered
findnext02:
	mov	bp,cs:[lastentry]
lploopp:
	cmp	es:byte ptr allocbyte[bp],free
	jne	short inuse
	mov	al,allocated
	xchg	es:byte ptr allocbyte[bp],al
	cmp	al,free
	je	short found02
	cmp	al,allocated
	je	short inuse
	mov	es:byte ptr allocbyte[bp],al
inuse:
	cmp	bp,cs:[firstentry]
	je	short fatal
	sub	bp,entrysize
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
	test	byte ptr ds:[bios_flags],40h
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
.xall
	public	endstackcode
endstackcode label  byte
	endif

	public	packet,unitcount,break_addr,bpb_addr,devdrivenum,configmsgflag
; Following is the request packet used to call INIT routines for 
; all device drivers.  Some fields may be accessed individually in
; the code, and hence have individual labels, but they should not
; be separated.

packet	db	25
	db	0
	db	0			;initialize code
	dw	0
	db	8 dup (?)

unitcount	db	0
break_addr	dd	0
bpb_addr	dd	0
devdrivenum	db	0
configmsgflag	dw	0		; used to control "error in config.sys line #" message

; end of request packet

	public	deviceparameters
deviceparameters a_deviceparameters <0,0,0,0>

sysinitseg ends
end
