	page ,132
;	SCCSID = @(#)tfor.asm	4.1 85/09/17
;	SCCSID = @(#)tfor.asm	4.1 85/09/17
TITLE	Part3 COMMAND Transient Routines
;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1991
; *                      All Rights Reserved.
; */

;     For loop processing routines


.xlist
.xcref
	include comsw.asm
	include dossym.inc
	include syscall.inc
	include find.inc
	include devsym.inc
	include comseg.asm
	include comequ.asm
.list
.cref


DATARES 	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	BATCH:WORD
	EXTRN	ECHOFLAG:BYTE
	EXTRN	FORFLAG:BYTE,LFNForFlag:BYTE
	EXTRN	FORPTR:WORD
	EXTRN	NEST:WORD
	EXTRN	NULLFLAG:BYTE
	EXTRN	PIPEFILES:BYTE
	EXTRN	SINGLECOM:WORD
DATARES ENDS

TRANDATA	SEGMENT PUBLIC BYTE	;AC000;
	EXTRN	Extend_buf_ptr:word	;AN000;
	extrn	fornestmes_ptr:word
	EXTRN	msg_disp_class:byte	;AN000;
	extrn	string_buf_ptr:word
TRANDATA	ENDS

TRANSPACE	SEGMENT PUBLIC BYTE	;AC000;
	extrn	arg:byte		; the arg structure!
	EXTRN	ComBufPtr:WORD,CmdBufferLength:WORD
	EXTRN	PathFindMode:BYTE,PathFindHandle:WORD
	EXTRN	RESSEG:WORD
	EXTRN	string_ptr_2:word
TRANSPACE	ENDS

TRANCODE	SEGMENT PUBLIC BYTE

ASSUME	CS:TRANGROUP,DS:NOTHING,ES:NOTHING,SS:NOTHING

	EXTRN	SelectPathInterface:NEAR,PathFindFirst:NEAR,PathFindNext:NEAR
	EXTRN	cerror:near
	EXTRN	docom:near
	EXTRN	docom1:near
	EXTRN	forerror:near
	EXTRN	tcommand:near

	PUBLIC	$for
	PUBLIC	forproc
	PUBLIC	for_make_com,nextarg,FORTERM,FORNESTERR,$for_exit,for_begin,fornesterrj


; All batch proccessing has DS set to segment of resident portion
ASSUME	DS:RESGROUP,ES:TRANGROUP


FORTERM:
	push	cs				;AN037; Get local segment into
	pop	ds				;AN037;    DS, ES
	push	cs				;AN037;
	pop	es				;AN037;
	call	ForOff
	mov	ds,ResSeg
ASSUME	DS:RESGROUP
	CMP	[SINGLECOM],0FF00H
	JNZ	BATCRLF
	CMP	NEST,0				;G See if we have nested batch files
	JNZ	BATCRLF 			;G Yes - don't exit just yet
	MOV	[SINGLECOM],-1			; Cause a terminate
	JMP	SHORT NOFORP2

BATCRLF:
	test	[ECHOFLAG],1			;G  Is echo on?
	JZ	NOFORP2 			;G  no - exit
	TEST	[BATCH], -1			;G  print CRLF if in batch
	JZ	NOFORP2 			;G
	invoke	CRLF2

NOFORP2:
	JMP	TCOMMAND


;------
;   For-loop processing.  For loops are of the form:
;	    for %<loop-variable> in (<list>) do <command>
; where <command> may contain references of the form %<variable>, which are
; later substituted with the items in <list>.  The for-loop structure is
; set-up by the procedure '$for'; successive calls to 'forproc' execute
; <command> once for each item in <list>.  All of the information needed for
; loop processing is stored on a piece of memory gotten from 'alloc'.  This
; structure is actually fairly large, on the order of 700 bytes, and includes
; a complete copy of the original command-line structure as parsed by
; 'parseline', loop control variables, and a dma buffer for the
; 'FindFirst/FindNext' expansion of wildcard filenames in <list>.  When loop
; processing has completed, this chunk of memory is returned to the system.
;
;   All of the previously defined variables, in 'datares', used for loop
; processing may be erased.  Only one, (DW) ForPtr, need be allocated.
;
;   The error message, 'for_alloc_mes', should be moved into the file
; containing all of the other error messages.
;
;   Referencing the allocated for-loop structure is a little tricky.
; At the moment, a byte is defined as part of a new segment, 'for_segment'.
; When 'forproc' actually runs, ES and DS are set to point to the base of the
; new chunk of memory.	References to this byte, 'f', thus assemble correctly
; as offsets of ES or DS.  'f' would not be necessary, except that the
; assembler translates an instruction such as 'mov AX, [for_minarg]' as an
; immediate move of the offset of 'for_minarg' into AX.  In other words, in
; terms of PDP-11 mnemonics, the assembler ACTUALLY assembles
;	mov	AX, #for_minarg 	; AX := 02CA (for example)
; instead of
;	mov	AX, for_minarg		; AX := [02CA] (contents of 02CA)
; By using 'f', we pretend that we are actually referencing an allocated
; structure, and the assembler coughs up the code we want.  Notice that it
; doesn't matter whether we put brackets around the location or not -- the
; assembler is "smart" enough to know that we want an address instead of the
; contents of that location.
;
;   Finally, there now exists the potential to easily implement nested loops.
; One method would be to have a link field in each for-structure pointing to
; its parent.  Variable references that couldn't be resolved in the local
; frame would cause a search of prior frames.  For-structures would still be
; allocated and released in exactly the same fashion.  The only limit on the
; number of nested loops would be memory size (although at 700 bytes a pop,
; memory wouldn't last THAT long).  Alternately, a small structure could be
; maintained in the resident data area.  This structure would be an array of
; control-variable names and pointers to for-structure blocks.	This would
; greatly speed up the resolution of non-local variable references.  However,
; since space in the resident is precious, we would have to compromise on a
; "reasonable" level of nesting -- 10, 16, 32 levels, whatever.  For-structure
; allocation and de-allocation would have to be modified slightly to take this
; new structure into account.
;
;   Oops, just one more thing.	Forbuf need not be a part of the for-structure.
; It could just as well be one structure allocated in 'transpace'.  Actually,
; it may be easier to allocate it as part of 'for_segment'.
;------

	include fordata.asm

$for_exit:
	jmp	forterm 			; exceeding maxarg means all done

forproc:
assume	DS:resgroup
	mov	AX, [ForPtr]
	mov	DS, AX
	mov	ES, AX				; operate in for-info area
assume	DS:for_segment, ES:for_segment

for_begin:
	cmp	f.for_expand, 0 		; non-zero for_expand equals FALSE
	je	for_begin1
	inc	f.for_minarg
for_begin1:
	mov	BX, f.for_minarg		; current item in <list> to examine
	cmp	BX, f.for_maxarg
	jg	$for_exit			; exceeding maxarg means all done
	mov	AX, for_args.argv
	invoke	argv_calc			; compute argv[x] address

	mov	CX, [BX].argstartel
	mov	DX, [BX].argpointer
	push	DS
	mov	DS,CS:ResSeg
	assume	DS:RESGROUP
	mov	AL,LFNForFlag
	pop	DS
	assume	DS:for_segment
	or	AL,AL
	jz	short for_path_mode
	mov	SI,DX
	invoke	SelectPathInterface
for_path_mode:
	mov	CS:PathFindMode,AL
	test	[bx].argflags,00000100b 	; Is there a path separator in this arg?
	jnz	forsub				; Yes, argstartel should be correct
	mov	si, [BX].argpointer
	mov	al,lparen
	cmp	byte ptr [si-1],al		; If the current token is the first
	jnz	forsub				;  one in the list and originally had
	inc	cx				;  the opening paren as its first char,
						;  the argstartel ptr needs to be
						;  advanced passed it before the prefix
						;  length is computed.
	mov	al,':'
	cmp	byte ptr [si+1],al		; If the token begins with "(d:",
	jnz	forsub				;  argstartel has to be moved over the
	add	cx,2				;  rest of the prefix as well.

forsub:
	sub	CX, DX				; compute length of pathname prefix
	cmp	f.for_expand, 0 		; are we still expanding a name?
	je	for_find_next			; if so, get next matching filename

	test	[BX].argflags, MASK wildcard
	jnz	for_find_first			; should we expand THIS (new) arg?
	mov	CX, [BX].arglen 		; else, just copy all of it directly
	jmp	short for_smoosh

for_find_first:
	PUSH	CX
	XOR	CX,CX
	mov	DI,fordma
	invoke	PathFindFirst
	mov	f.FOR_FIND_HANDLE,AX
	mov	CS:PathFindHandle,0
	POP	CX
	jmp	short for_result
for_find_next:
	mov	DI,fordma
	mov	AX,f.FOR_FIND_HANDLE
	mov	CS:PathFindHandle,AX
	invoke	PathFindNext
	mov	CS:PathFindHandle,0

for_result:
	mov	AX, -1				; assume worst case
	jc	forCheck
	mov	ax,0
forCheck:					; Find* returns 0 for SUCCESS
	mov	f.FOR_EXPAND, AX		; record success of findfirst/next
	or	AX, AX				; anything out there?
	jz	short for_smoosh
	jmp	for_begin			; if not, try next arg

for_smoosh:
	push	SI
	mov	SI, [BX].argpointer		; copy argv[arg][0,CX] into destbuf
	mov	DI, forbuf			; some days this will be the entire
	rep	movsb				; arg, some days just the path prefix
	pop	SI

	cmp	f.FOR_EXPAND, 0 		; if we're not expanding, we can
	jnz	for_make_com			; skip the following

for_more:					; tack on matching filename
	cmp	BYTE PTR [SI], 0
	je	for_make_com
	movsb
	jnz	for_more

for_make_com:
	xor	AL, AL				; tack a null byte onto the end
	stosb					; of the substitute string

	xor	CX, CX				; character count for command line
	not	CX				; negate it -- take advantage of loopnz
	xor	BX, BX				; argpointer
	mov	DI, CS:ComBufPtr
	mov	bl, f.FOR_COM_START		; argindex
	mov	DH, f.FOR_VAR			; %<for-var> is replaced by [forbuf]
						; time to form the <command> string
	push	CS
	pop	ES
assume	ES:trangroup

	mov	AX, for_args			; translate offset to pointer
	invoke	argv_calc
	mov	si,[bx].arg_ocomptr
	inc	si				; mov ptr passed beginning space

for_make_loop:
	mov	al,[si] 			; the <command> arg, byte by byte
	inc	si
	cmp	AL,'%'                          ; looking for %<control-variable>
	jne	for_stosb			; no % ... add byte to string
	cmp	BYTE PTR [SI], DH		; got the right <variable>?
	jne	for_stosb			; got a %, but wrong <variable>
	inc	SI				; skip over <for-variable>

	push	SI
	mov	SI, forbuf			; substitute the <item> for <variable>
						; to make a final <command> to execute
sloop:
	lodsb					; grab all those <item> bytes, and
	stosb					; add 'em to the <command> string,
	or	AL, AL				; until we run into a null
	loopnz	sloop
	dec	DI				; adjust length and <command> pointer
	inc	CX				; so we can overwrite the null

	pop	SI
	jmp	for_make_loop			; got back for more <command> bytes
for_stosb:
	stosb					; take a byte from the <command> arg
	dec	CX				; and put it into the <command> to be
						; executed (and note length, too)
	cmp	al,0dh				; If not done, loop.
	jne	for_make_loop

for_made_com:					; finished all the <command> args
	not	CX				; compute and record command length
	push	SI
	mov	SI, ES:ComBufPtr
	mov	[SI-2], CX
	pop	SI

	mov	DS, [RESSEG]
assume	DS:resgroup

	test	[ECHOFLAG],1			; shall we echo this <command>, dearie?
	jz	noecho3
	cmp	nullflag,nullcommand		;G was there a command last time?
	jz	No_crlf_pr			;G no - don't print crlf
	invoke	CRLF2				;G  Print out prompt

no_crlf_pr:
	mov	nullflag,0			;G reset no command flag
	push	CS
	pop	DS
	assume	DS:trangroup
	push	di
	invoke	PRINT_PROMPT			;G Prompt the user
	pop	di
	mov	BYTE PTR ES:[DI-1],0		; yeah, PRINT it out...
	mov	DX, ComBufPtr
	mov	string_ptr_2, DX
	mov	dx,offset trangroup:string_buf_ptr
	invoke	std_printf
	mov	BYTE PTR ES:[DI-1], 0DH
	jmp	DoCom
noecho3:					; run silent, run deep...
	assume	DS:resgroup
	mov	nullflag,0			;G reset no command flag
	push	CS
	pop	DS
	assume	DS:trangroup
	jmp	docom1


fornesterrj:					; no multi-loop processing... yet!
assume	ES:resgroup
	call	ForOff
	jmp	fornesterr

forerrorj:
	jmp	forerror

	break	$For
assume	ds:trangroup,es:trangroup

$for:
	mov	ES, [RESSEG]
assume	ES:resgroup

	cmp	ForFlag,0			; is another one already running?
	jnz	fornesterrj			; if flag is set.... boom!

;
; Turn off any pipes in progress.
;
	cmp	[PIPEFILES],0			; Only turn off if present.
	jz	NoPipe
	invoke	PipeDel
NoPipe:
	xor	DX, DX				; counter (0 <= DX < argvcnt)
	call	nextarg 			; move to next argv[n]
	jc	forerrorj			; no more args -- bad forloop
	cmp	AL,'%'                          ; next arg MUST start with '%'...
	jne	forerrorj
	mov	BP, AX				; save forloop variable
	lodsb
	or	AL, AL				; and MUST end immediately...
	jne	forerrorj

	call	nextarg 			; let's make sure the next arg is 'in'
	jc	forerrorj
	and	AX, NOT 2020H			; uppercase the letters
	cmp	AX, in_word
	jne	forerrorj
	lodsb
	or	AL, AL				; it, too, must end right away

; Compaq bug fix -- exit from this loop on error

	jne	forerrorj			; jump on error

;;	je	CheckLParen
;
; Not null.  Perhaps there are no spaces between this and the (:
;   FOR %i in(foo bar...
; Check for the Lparen here
;
;;	CMP	AL,lparen
;;	JNZ	forerrorj
;
; The token was in(...	We strip off the "in" part to simulate a separator
; being there in the first place.
;
;;	ADD	[BX].argpointer,2		; advance source pointer
;;	ADD	[BX].arg_ocomptr,2		; advance original string
;;	SUB	[BX].arglen,2			; decrement the appropriate length
;
; SI now points past the in(.  Simulate a nextarg call that results in the
; current value.
;
;;	MOV	ax,[si-1]			; get lparen and next char
;;	jmp	short lpcheck
;
;; end of Compaq bug fix

CheckLParen:
	call	nextarg 			; lparen delimits beginning of <list>
	jc	forerrorj
lpcheck:
	cmp	al, lparen
	jne	forerrorj
	cmp	ah,0
	je	for_paren_token

	cmp	ah, rparen			; special case:  null list
	jne	for_list_not_empty
	jmp	forterm

for_list_not_empty:
	inc	[bx].argpointer 		; Advance ptr past "("
						; Adjust the rest of this argv entry
	dec	[bx].arglen			;  to agree.
	inc	si				; Inc si so check for ")" works
	jmp	short for_list

for_paren_token:
	call	nextarg 			; what have we in our <list>?
	jc	forerrorj
	cmp	ax, nullrparen			; special case:  null list
	jne	for_list
	jmp	forterm

forerrorjj:
	jmp	forerror

for_list:					; skip over rest of <list>
	mov	CX, DX				; first arg of <list>
skip_list:
	add	si,[bx].arglen
	sub	si,3				; si = ptr to last char of token
	mov	al,rparen
	cmp	byte ptr [si],al		; Is this the last element in <list>
	je	for_end_list			; Yes, exit loop.
	call	nextarg 			; No, get next arg <list>
	jc	forerrorjj			; If no more and no rparen, error.
	jmp	skip_list
for_end_list:
	mov	DI, DX				; record position of last arg in <list>
	mov	byte ptr [si],0 		; Zap the rparen
	cmp	ax,nullrparen			; Was this token only a rparen
	jz	for_do				; Yes, continue
	inc	di				; No, inc position of last arg

for_do:
	call	nextarg 			; now we had BETTER find a 'do'...
	jc	forerrorjj
	and	AX, NOT 2020H			; uppercase the letters
	cmp	AX, do_word
	jne	forerrorjj
	lodsb
	or	AL, AL				; and it had BETTER be ONLY a 'do'...
	jne	forerrorjj

	call	nextarg 			; on to the beginning of <command>
	jc	forerrorjj			; null <command> not legal

	push	AX
	push	BX
	push	CX
	push	DX				; preserve registers against disaster
	push	DI
	push	SI
	push	BP
	invoke	FREE_TPA			; need to make free memory, first
ASSUME	ES:RESGROUP
	call	ForOff
	invoke	Save_Args			; save arguments and allocate for-info
	pushf
	mov	[ForPtr], AX
	invoke	ALLOC_TPA			; ALLOC_TPA clobbers registers...
	popf
	pop	BP
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	pop	AX
	jc	for_alloc_err

	push	ES				; save resgroup seg...
	push	[ForPtr]
	pop	ES
assume	ES:for_segment				; make references to for-info segment

	dec	CX				; forproc wants min pointing before
	dec	DI				; first arg, max right at last one
	mov	f.for_minarg, CX
	mov	f.for_maxarg, DI
	mov	f.for_com_start, DL
	mov	f.for_expand, -1		; non-zero means FALSE
	mov	AX, BP
	mov	f.for_var, AH
	pop	ES
assume	ES:resgroup

	inc	[FORFLAG]
	cmp	[SINGLECOM], -1
	jnz	for_ret
	mov	[SINGLECOM], 0FF00H
for_ret:
	ret

for_alloc_err:
	mov	msg_disp_class,ext_msg_class	;AN000; set up extended error msg class
	mov	dx,offset TranGroup:Extend_Buf_ptr     ;AC000; get extended message pointer
	mov	Extend_Buf_ptr,error_not_enough_memory ;AN000; get message number in control block
	jmp	cerror

nextarg:
	inc	DX				; next argv[n]
	cmp	DX, arg.argvcnt 		; make sure we don't run off end
	jge	nextarg_err			; of argv[]...
	mov	BX, DX
	mov	AX, OFFSET TRANGROUP:arg.argv
	invoke	argv_calc			; convert array index to pointer
	mov	SI, [BX].argpointer		; load pointer to argstring
	lodsw					; and load first two chars
	clc
	ret
nextarg_err:
	stc
	ret


ASSUME	DS:TRANGROUP,ES:TRANGROUP

FORNESTERR:
	PUSH	DS
	MOV	DS,[RESSEG]
ASSUME	DS:RESGROUP
	MOV	DX,OFFSET TRANGROUP:FORNESTMES_ptr
	CMP	[SINGLECOM],0FF00H
	JNZ	NOFORP3
	MOV	[SINGLECOM],-1			; Cause termination
NOFORP3:
	POP	DS
ASSUME	DS:TRANGROUP
	JMP	CERROR
;
; General routine called to free the for segment.  We also clear the forflag
; too.	Change no registers.
;
PUBLIC ForOff
ForOff:
	assume DS:NOTHING,ES:NOTHING
	SaveReg <AX,ES>
	mov	es,ResSeg
	assume	es:ResGroup
	mov	AX,ForPtr
	or	ax,ax
	jz	FreeDone
	push	es
	mov	es,ax
	mov	ah,dealloc
	int	21h
	pop	es
FreeDone:
	mov	ForPtr,0
	mov	ForFlag,0
	RestoreReg  <ES,AX>
	return

break <Save_Args>
;----------------------------------------------------------------------------
;   SAVE_ARGS preserves the argument header and dynamic strings in a new
; FOR segment.  Control information and search buffers precede the strings.
; Argument pointers are adjusted to the new segment.
; ENTRY:
;   DS      --      TRANGROUP, containing the current parsed arguments.
; EXIT:
;   AX	    --	    segment of new area.
;   CF	    --	    set if unable to save a copy.
; NOTE(S):
;   1)	The allocated area will be AT LEAST the size requested -- since
;	the underlying MSDOS call, <alloc> returns an integral number of
;	paragraphs.
;   2)	It is an error if MSDOS can't allocate AT LEAST as much memory
;	as the caller of Save_Args requests.
;   3)	AX is undefined if CF indicates an error.
;---------------
Procedure   Save_Args,NEAR
;---------------
	assume	ds:trangroup, es:trangroup
	push	BX
	push	CX
	push	DX
	push	DI
	push	SI
	push	BP
	pushf
	mov	BX, SIZE for_info + 0FH	; fixed area, rounded to paragraphs
	add	BX, CmdBufferLength
	add	BX, CmdBufferLength
	add	BX, CmdBufferLength
	mov	CL, 4				; to paragraph size and convert
	shr	BX, CL				; size in bytes to size in paragraphs
	trap	Alloc
	jc	save_error
	mov	BP, AX				; save segment id
	push	ES				; save TRANGROUP address
	mov	ES, AX				; switch to new memory segment
assume	ES:nothing
	mov	CX, FOR_COM_START		; get back structure size
	xor	DI, DI				; destination is new memory area
	mov	SI, OFFSET TRANGROUP:arg	; source is arg structure
	rep	movsb				; move that sucker!
	mov	DI, SIZE for_info		; strings follow control information
	mov	SI, ComBufPtr
	mov	CX, CmdBufferLength
	add	SI, CX
	inc	SI
	add	CX, CX
	add	CX, CmdBufferLength
	rep	movsb
	mov	CX, arg.argvcnt		; adjust argv pointers
	xor	AX, AX			; base address for argv_calc
	mov	SI, ComBufPtr
	add	SI, CmdBufferLength
	inc	SI
	sub	SI, SIZE for_info		; old string base minus new base

save_ptr_loop:
	dec	CX				; exhausted all args?
	jl	save_done
	mov	BX, CX				; get arg index and
	invoke	argv_calc			; convert to a pointer
	mov	DX, DS:arg.argv[BX].argpointer
	sub	DX, SI				; adjust argpointer
	mov	ES:argv[BX].argpointer, DX
	mov	DX, DS:arg.argv[BX].argstartel
	sub	DX, SI				; and adjust argstartel
	mov	ES:argv[BX].argstartel, DX
	mov	DX, DS:arg.argv[BX].arg_ocomptr
	sub	DX, SI				; and adjust arg_ocomptr
	mov	ES:argv[BX].arg_ocomptr, DX
	jmp	save_ptr_loop

save_done:
	pop	ES				; back we go to TRANGROUP
assume	ES:trangroup
	mov	AX, BP				; restore segment id
	jmp	short save_ok

save_error:
	popf
	stc
	jmp	short save_exit

save_ok:
	popf
	clc
save_exit:
	pop	BP
	pop	SI
	pop	DI
	pop	DX
	pop	CX
	pop	BX
	ret
;---------------
EndProc Save_Args

trancode    ends
	    end
