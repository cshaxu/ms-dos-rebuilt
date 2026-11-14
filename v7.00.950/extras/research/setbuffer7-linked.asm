DOS7_CONFIG equ 1
Buff_Queue equ 0
Dirty_Buff_Count equ 4
Buff_In_HMA equ 0ch
Lo_Mem_Buff equ 0dh
buf_next equ 0
buf_prev equ 2
bufinsiz equ 14h
devmark_buf equ 42h
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing,es:nothing
 org 0f0ch
dos_umb_flag db 1
 org 0f17h
buffers dw 0
 org 0f1bh
singlebuffersize dw 0
 org 3b88h
pararound proc near
 ret
pararound endp
 org 3c4fh
set_buffer proc near

	assume	ds:nothing
IFDEF DOS7_CONFIG
        call    GetBufferAddr7
ELSE
	xor	dl, dl				; assume buffers not in HMA
	call	GetBufferAddr
	je	@f
	mov	dl, 1				; buffers in HMA
@@:
ENDIF
	mov	word ptr ds:[bx].Buff_Queue,di	; head of Buff Q
	mov	word ptr ds:[bx].Buff_Queue[2],es
	mov	word ptr ds:[bx.Dirty_Buff_Count],0 ;set dirty_count to 0.

	mov	ax, di
	mov	cx, [buffers]
	push	di				; remember first buffer

;	for each buffer

nxt_buff:
	call	set_buffer_info 		;set buf_link,buf_id...
	mov	di, ax
	loop	nxt_buff

	sub	di, [singlebuffersize]		; point to last buffer

	pop	cx				; get first buffer
	mov	word ptr es:[di].buf_next, cx	; last->next = first
	xchg	cx, di
	mov	word ptr es:[di].buf_prev, cx	; first->prev = last

IFDEF DOS7_CONFIG
        mov     ax,es
        cmp     ax,word ptr ds:[bx+1fh] ; DOS 7 buffer HMA segment threshold
        jb      buffer7_exit
        mov     byte ptr ds:[bx].Buff_In_HMA,1
        mov     ax,cs:[singlebuffersize]
        sub     ax,bufinsiz
        push    ds
        push    bx
        call    pararound
        push    cs
        pop     ds
        assume  ds:sysinitseg
        mov     bh,devmark_buf
        mov     bl,[dos_umb_flag]
        cmp     bl,1
        jne     short buffer7_scratch
        mov     bl,0
buffer7_scratch:
        call    alloc_marked_block
        pop     bx
        pop     ds
        assume  ds:nothing
        mov     word ptr ds:[bx].Lo_Mem_Buff,0
        mov     word ptr ds:[bx].Lo_Mem_Buff[2],cx
buffer7_exit:
        ret
ELSE
	or	dl, dl				; In HMa ?
	jz	@f				; no
	mov	byte ptr ds:[bx].Buff_In_HMA, 1
	mov	ax, memhi			; seg of scratch buff
	mov	word ptr ds:[bx].Lo_Mem_Buff, 0	; offset of sctarch buff is 0
	mov	word ptr ds:[bx].Lo_Mem_Buff[2], ax
	mov	ax, singlebuffersize		; size of scratch buff
	sub	ax, bufinsiz			; buff head not reqd
@@:
	add	memlo, ax
	or	[setdevmarkflag], for_devmark
	call	round
	ret
ENDIF
set_buffer endp
 org 3caeh
GetBufferAddr7 proc near
 ret
GetBufferAddr7 endp
 org 3ce6h
set_buffer_info proc near
 ret
set_buffer_info endp
 org 858ah
alloc_marked_block proc near
 ret
alloc_marked_block endp
sysinitseg ends
end
