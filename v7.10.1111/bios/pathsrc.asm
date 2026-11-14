	.8086
sysinitseg	segment	byte public 'system_init'
	assume	cs:sysinitseg,ds:sysinitseg,es:sysinitseg
	extrn	config_envlen:word,config_wrkseg:word
	public	Path_str,Path_Crunch,Search,Search_Ftype,Find_Path_In_Environment
; PATH searching routines.

Path_str	db	'PATH='
Path_str_size	equ	$ - offset Path_str
Path_buffer	db	110 dup (0)
FindBufferName	equ	Path_buffer+61h

;----------------------------------------------------------------------------
; Path_Crunch - concatenate a file name with a directory from PATH.
;
; ENTRY: BH = additional terminator, DS:SI -> path string.
;        DX = filename offset in SysInitSeg.
; EXIT:  SI advances along the path string. Path_buffer receives the name;
;        ES:DI points past its terminating null. Carry set at end of PATH.
;----------------------------------------------------------------------------
Path_Crunch	proc	near
	push	cs
	pop	es
	mov	di,offset Path_buffer
path_cr_copy:
	lodsb
	or	al,al
	jz	path_seg
	db	38h,0f8h       ; cmp al,bh
	jz	path_seg
	stosb
	jmp	short path_cr_copy
path_seg:
	push	si
	mov	bl,al
	mov	al,'\'
	cmp	al,es:[di-1]
	jz	path_cr_l1
	stosb
path_cr_l1:
	mov	si,dx
path_cr_l2:
	lods	byte ptr es:[si]
	stosb
	or	al,al
	jnz	path_cr_l2
	or	bl,bl
	clc
	jnz	path_cr_exit
	cmc
path_cr_exit:
	pop	si
	ret
Path_Crunch	endp

search_best	db	0
;----------------------------------------------------------------------------
; Search - find a file, preferring .COM to .EXE when no extension is given.
;
; ENTRY: DX = pathname offset in SysInitSeg, AL = explicit-extension flag.
;        The caller must set the find buffer before calling.
; EXIT:  DS = SysInitSeg, DX points to the resolved pathname.
;        AL receives search_best on success; AX is zero if no file is found.
;----------------------------------------------------------------------------
Search	proc	near
	push	cs
	pop	ds
	push	si
	push	ax
	mov	di,dx
	mov	cx,3
	mov	ah,4eh
	int	21h
	pop	ax
	jc	search_no_file
	or	al,al
	jnz	search_file_found
	mov	search_best,0
search_loop:
	call	Search_Ftype
	cmp	al,search_best
	jle	search_next
	mov	search_best,al
	cmp	al,8
	je	search_done
search_next:
	mov	cx,3
	mov	ah,4fh
	int	21h
	jnc	search_loop
search_done:
	cmp	search_best,0
	je	search_no_file
	cmp	search_best,8
	mov	si,offset comext
	je	search_move_ext
	mov	si,offset exeext
search_move_ext:
	mov	di,dx
	mov	al,'.'
	mov	cx,43h
	rep	scasb
	dec	di
	movsw
	movsw
search_file_found:
	mov	al,search_best
	jmp	short search_exit
search_no_file:
	mov	ax,0
search_exit:
	pop	si
	ret
Search	endp

comext	db	'.COM',0
exeext	db	'.EXE',0

;----------------------------------------------------------------------------
; Search_Ftype - examine the extension in the current find buffer.
;
; ENTRY: ES addresses FindBufferName, DS addresses the extension strings.
; EXIT:  AL = 8 for .COM, 4 for .EXE, 0 for a failed extension comparison.
;        SI and DI are preserved.
;----------------------------------------------------------------------------
Search_Ftype	proc	near
	push	di
	push	si
	mov	al,0
	mov	di,offset FindBufferName
	mov	cx,23
	cld
	repne	scasb
	jnz	ftype_exit
	dec	di
	mov	cx,5
	std
	mov	al,'.'
	repne	scasb
	jnz	ftype_exit
	inc	di
	cld
	mov	si,offset comext
	mov	ax,di
	cmpsw
	jnz	ftype_exe
	cmpsw
	jnz	ftype_exe
	mov	al,8
	jmp	short ftype_exit
ftype_exe:
	mov	di,ax
	mov	si,offset exeext
	cmpsw
	jnz	ftype_fail
	cmpsw
	jnz	ftype_fail
	mov	al,4
	jmp	short ftype_exit
ftype_fail:
	mov	al,0
ftype_exit:
	pop	si
	pop	di
	ret
Search_Ftype	endp

;----------------------------------------------------------------------------
; Find_Path_In_Environment - find PATH in the CONFIG environment workspace.
;
; ENTRY: DS = SysInitSeg; config_envlen and config_wrkseg describe the workspace.
; EXIT:  ES:DI points to the directory list; carry set if PATH is not found.
;----------------------------------------------------------------------------
Find_Path_In_Environment	proc	near
	lea	si,Path_str
	mov	cx,Path_str_size
	cmp	word ptr [config_envlen],0
	je	short path_not_found
	cld
	mov	es,[config_wrkseg]
	xor	di,di
find1:
	push	si
	push	cx
	repe	cmpsb
	pop	dx
	pop	si
	je	short path_find_exit
	dec	di
	xor	al,al
	mov	cx,100h
	repne	scasb
	cmp	byte ptr es:[di],0
	mov	cx,dx
	jnz	find1
path_not_found:
	stc
path_find_exit:
	ret
Find_Path_In_Environment	endp
sysinitseg	ends
	end
