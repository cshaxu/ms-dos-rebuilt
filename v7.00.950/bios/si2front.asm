BYTE_SYSINIT equ 1
	page	,160
;
;       Microsoft Confidential
;       Copyright (C) Microsoft Corporation 1981-1991
;       All Rights Reserved.
;

        title   bios system initialization

;
; Multiple configuration block support  Created 16-Mar-1992 by JeffPar
;
; Summary:
;
;   The procedure "organize" crunches the in-memory copy of config.sys
;   into lines delimited by CR/LF (sometimes no CR, but *always* an LF)
;   with the leading "keyword=" replaced by single character codes (eg, B
;   for BUFFERS, D for DEVICE, Z for any unrecognized keyword);  see comtab
;   and/or config.inc for the full list.
;
;   [blockname] and INCLUDE are the major syntactical additions for multi-
;   configuration support.  blockname is either MENU, which contains one
;   or more MENUITEM lines, an optional MENUDEFAULT (which includes optional
;   time-out), or any user-defined keyword, such as NETWORK, CD-ROM, etc.
;   INCLUDE allows the current block to name another block for inclusion
;   during the processing phase of CONFIG.SYS.  An INCLUDE is only honored
;   once, precluding nasty infinite-loop scenarios.  If blocks are present
;   without a MENU block, then only lines inside COMMON blocks are processed.
;
; Example:
;
;   [menu]
;   menuitem=misc,Miscellaneous
;   menuitem=network,Network Configuration
;   menudefault=network,15
;
;   [network]
;   include misc
;   device=foo
;
;   [misc]
;   device=bar
;   include alternate
;
;   [alternate]
;   device=tar
;
;
;   When the menu is displayed
;
;    1. Miscellaneous
;    2. Network Configuration
;
;   #2 is highlighted as the default option, and will be automatically
;   selected after 15 seconds.  It will invoke the following lines in the
;   following order:
;
;       DEVICE=BAR
;       DEVICE=TAR
;       DEVICE=FOO
;

MULTI_CONFIG equ 1
CONFIG_LOGO equ 'q'

break   macro
        endm

	.xlist
	include version.inc		; set version build flags
	include biosseg.inc		; establish bios segment structure
	.list

lf	equ	10
cr	equ	13
tab	equ	9

; the following depends on the positions of the various letters in switchlist

switchnum	equ 11111000b		; which switches require number

	.xlist
	include	bpb.inc
        include exe.inc
	include syscall.inc
        include sysvar.inc
	include doscntry.inc
	include devsym.inc
	include ioctl.inc
        include devmark.inc
        include config.inc
ifdef   MULTI_CONFIG
        include rombios.inc
endif
	.list

stacksw equ     true                    ; include switchable hardware stacks

	if	ibmjapver
noexec	equ	true
	else
noexec	equ	false
	endif


Bios_Data segment 
        extrn   bios_flags:word
        extrn   palette_index:byte,palette_count:byte,palette_config:word
        extrn   int16_limit:word,int16_limit2:word
Bios_Data ends

Bios_Code segment
	extrn	eot:byte,ec35_flag:byte
        extrn   bc_retf:far, keyboard_service:near, int19_restore:far
        extrn   int15_esc:far,hma_init_ptr:dword
        extrn   win386_info_flags:byte
        extrn   exec_bios_word:word,bootlog_device:word
        extrn   win386_text_length:word,win386_text_buffer:byte
        extrn   win386_options_path:byte
        extrn   win386_info_buffer:byte,win386_info_table:byte
Bios_Code ends

sysinitseg segment public

	extrn	sysinit_msg_table:word,sysinit_msg_base:byte
	extrn	sysinit_prompt_index:word
	extrn	sysinit_badld_index:word,sysinit_crlf_index:word
	extrn   boot_reloc_segment:word
        extrn   IsXMSLoaded:near
	extrn	print_indexed:near,boot_record_compressed_boot:near

assume	cs:sysinitseg,ds:nothing,es:nothing,ss:nothing

ifdef   MULTI_CONFIG

        MAX_MULTI_CONFIG equ 9          ; max # of multi-config menu items supported

        extrn   BCodeSeg:word, bios_data_segment:word,boot_load_segment:word
        extrn   config_buffer_segment:word
        extrn   compression_skip:byte
        extrn   MagicMoveInfo:dword
        extrn   boot_check_redirected_drive:near,boot_check_drive_map:near
        extrn   DevUMB:byte
        extrn   stack_high:byte
        extrn   multi_pass_id:byte,multi_pass_config_line:near
        extrn   dos_umb_flag:byte
        extrn   exec_mode:byte,exec_option:byte,exec_value:word
        extrn   config_envlen:word
        extrn   config_wrkseg:word
        extrn   new_psp_segment:word
	extrn	AllocFreeMem:near,boot_mode:byte
        extrn   config_cmd:byte
        extrn   config_multi:byte
        extrn   $PauseMsg:byte
        extrn   $CleanMsg:byte
        extrn   $InterMsg:byte
        extrn   $MenuHeader:byte
        extrn   $MenuPrmpt:byte
        extrn   $StatusLine:byte
        extrn   $InterPrmpt:byte
        extrn   $YES:byte
        extrn   $NO:byte
        extrn   $TimeOut:byte
        extrn   swit_n:byte, swit_f:byte


endif

IFDEF	CONFIGPROC

	extrn	badopm:byte,badblock:byte
	extrn	badsiz_pre:byte
	extrn	error_line:near

	extrn	dosinfo:dword
	extrn	memory_size:word,fcbs:byte,keep:byte
	extrn	default_drive:byte,confbot:word
	extrn	buffers:word,zero:byte,sepchr:byte
	extrn	files:byte
	extrn	count:word,chrptr:word
	extrn	bufptr:byte,prmblk:byte
	extrn	ldoff:word,area:word,packet:byte,unitcount:byte
	extrn	break_addr:dword,bpb_addr:dword,drivenumber:byte
	extrn	com_level:byte, cmmt:byte, cmmt1:byte, cmmt2:byte
	extrn	cmd_indicator:byte
	extrn	multdeviceflag:byte
	extrn	org_count:word

	extrn	getchr:near
	extrn	DevEntry:dword
        extrn   config_record_ptr:dword

ENDIF ; CONFIGPROC

	extrn	memlo:word,memhi:word,alloclim:word
	extrn	badmem:byte,crlfm:byte
	extrn	setdevmarkflag:byte,badld_pre:byte

	extrn	donotshownum:byte
	extrn	pararound:near
	extrn	stall:near


        public  int24,open_dev,prndev,auxdev,condev

	public	badfil,print

IFDEF	CONFIGPROC

	public	organize,newline,calldev,badload
	public	config,getnum,prnerr
	public	delim
	public	setdoscountryinfo,set_country_path,move_asciiz
	public	cntry_drv,cntry_root,cntry_path
	public	pathstring



        extrn   config_swap_active:byte,OnOff:byte,insert_blank:byte
        extrn   query_yes:byte,query_yes_lower:byte,query_no:byte,query_no_lower:byte
        extrn   query_all_char:byte,query_all_lower:byte

;
;----------------------------------------------------------------------------
;
; procedure : organize
;
;----------------------------------------------------------------------------
;
		assume ds:nothing, es:nothing
extrn boot_safe:byte,boot_menu:byte,boot_delay:word,boot_config_name:byte
extrn boot_build_menu:near,boot_toupper:near,boot_logo_display:near,query_keyboard_service:near
public aoffblockdesc,bdefblock,bmaxblock,display_menu,sectimeout
organize	proc	near

	mov	cx,[count]
	jcxz	nochar1

ifndef  MULTI_CONFIG
;
;   In MULTI_CONFIG, we map to upper case on a line-by-line basis,
;   because we the case of values in SET commands preserved
;
	call	mapcase
endif
	xor	si,si
	mov	di,si
	xor	ax,ax
	mov	com_level, 0

org1:
	call	skip_comment
	jz	end_commd_line		; found a comment string and skipped.
	call	get2			; not a comment string. then get a char.
	cmp	al, lf
	je	end_commd_line		; starts with a blank line.
	cmp	al, ' '
	jbe	org1			; skip leading control characters
	jmp	short findit

end_commd_line:
	stosb				; store line feed char in buffer for the linecount.
	mov	com_level, 0		; reset the command level.
	jmp	org1

nochar1:
	stc
	ret

findit:
	push	cx
	push	si
	push	di
	mov	bp,si
	dec	bp
        mov     si,offset comtab        ; prepare to search command table
	mov	ch,0
findcom:
	mov	di,bp
	mov	cl,[si]
	inc	si
	jcxz	nocom

ifdef   MULTI_CONFIG
;
;   Simplify future parsing by collapsing ";" onto "REM", and at the same
;   time skip the upcoming delimiter test (since ";" need not be followed by
;   anything in particular)
;
        cmp     byte ptr es:[di],CONFIG_SEMICOLON
        je      semicolon
loopcom:
        mov     al,es:[di]
        inc     di
        and     al,not 20h              ; force upper case
        inc     si                      ; compare to byte @es:di
        cmp     al,ds:[si-1]
        loope   loopcom
else
	repe	cmpsb
endif
	lahf
        add     si,cx                   ; bump to next position without affecting flags
	sahf
        lodsb                           ; get indicator letter
	jnz	findcom
        cmp     byte ptr es:[di], cr    ; the next char might be cr,lf
	je	gotcom0 		; such as in "rem",cr,lf case.
	cmp	byte ptr es:[di], lf
	je	gotcom0

ifdef   MULTI_CONFIG
;
;   Skip the delimiter test for the BEGIN identifier (it doesn't have one).
;
        cmp     al,CONFIG_BEGIN
        je      gotcom0
        cmp     al,CONFIG_LOGO
        je      gotcom0
endif
	push	ax
        mov     al, byte ptr es:[di]    ; now the next char. should be a delim.

ifdef   MULTI_CONFIG
;
;   If keyword is *immediately* followed by a question mark (?), then
;   set the high bit of the ASCII command code (CONFIG_OPTION_QUERY) that is
;   stored in the CONFIG.SYS memory image.
;
        cmp     al,'?'                  ; explicit interactive command?
        jne     no_query                ; no
        pop     ax                      ; yes, so retrieve the original code
        or      al,CONFIG_OPTION_QUERY  ; and set the QUERY bit
        jmp     short gotcom0           ;
semicolon:
        mov     al,CONFIG_REM
        jmp     short gotcom0
no_query:
endif  ;MULTI_CONFIG

	call	delim
no_delim:
	pop	ax
	jnz	findcom
gotcom0:
	pop	di
	pop	si
	pop	cx
	jmp	short gotcom

nocom:
	pop	di
	pop	si
	pop	cx
        mov     al,CONFIG_UNKNOWN
	stosb				; save indicator char.
skipline:
	call	get2
	cmp	al, lf			; skip this bad command line
        jne     skipline
	jmp	end_commd_line		; handle next command line

gotcom:
        stosb                           ; save indicator char in buffer

ifdef   MULTI_CONFIG
;
;   Don't pollute "cmd_indicator" with the CONFIG_OPTION_QUERY bit though;
;   it screws up the direct comparisons below.
;
        and     al,NOT CONFIG_OPTION_QUERY
endif
	mov	cmd_indicator, al	; save it for the future use.

ifdef   MULTI_CONFIG
;
;   There is no whitespace/delimiter between the "begin block" character
;   ([) and the name of block (eg, [menu]), therefore skip this delimiter
;   skipping code
;
        cmp     al,CONFIG_BEGIN
        je      org31
        cmp     al,CONFIG_SUBMENU
        je      no_mapcase
        cmp     al,CONFIG_MENUITEM
        je      no_mapcase
        cmp     al,CONFIG_MENUDEFAULT
        je      no_mapcase
        cmp     al,CONFIG_INCLUDE
        je      no_mapcase
        call    mapcase                 ; map case of rest of line to UPPER
no_mapcase:
endif

org2:	call    get2                    ; skip the command name until delimiter
        cmp     al, lf
	je	org21
	cmp	al, cr
	je	org21
	cmp	al, '/'			; T-RICHJ: Added to allow DEVHIGH/L:...
	je	org21			; T-RICHJ: to be parsed properly.

	call	delim
        jnz     org2
	jmp	short org3

org21:					;if cr or lf then
	dec	si			; undo si, cx register
	inc	cx			;  and continue

org3:	cmp     cmd_indicator, CONFIG_COMMENT
	je	get_cmt_token
        cmp     cmd_indicator, CONFIG_DEVICE
	je	org_file
        cmp     cmd_indicator, CONFIG_INSTALL
	je	org_file
        cmp     cmd_indicator, CONFIG_INSTALLHIGH
        je      org_file
        cmp     cmd_indicator, CONFIG_SHELL
	je	org_file
        cmp     cmd_indicator, CONFIG_SWITCHES
	je	org_switch
org31:
	jmp	org4

org_switch:
	call	skip_comment
	jz	end_commd_line_brdg

	call	get2
	call	org_delim
	jz	org_switch

	stosb
	jmp	org5

org_file:			; get the filename and put 0 at end,
	call	skip_comment
	jz	org_put_zero

	call	get2		; not a comment
	call	delim
	jz	org_file	; skip the possible delimeters

	stosb			; copy the first non delim char found in buffer

org_copy_file:
	call	skip_comment	; comment char in the filename?
	jz	org_put_zero	; then stop copying filename at that point

	call	get2
	cmp	al, '/' 	; a switch char? (device=filename/xxx)
	je	end_file_slash	; this will be the special case.

	stosb			; save the char. in buffer
	call	delim
	jz	end_copy_file

	cmp	al, ' '
	ja	org_copy_file	; keep copying
	jmp	short end_copy_file ; otherwise, assume end of the filename.

get_cmt_token:			; get the token. just max. 2 char.
	call	get2
	cmp	al, ' ' 	; skip white spaces or "=" char.
	je	get_cmt_token	; (we are allowing the other special
	cmp	al, tab 	;  charaters can used for comment id.
	je	get_cmt_token	;  character.)
	cmp	al, '=' 	; = is special in this case.
	je	get_cmt_token
	cmp	al, cr
	je	get_cmt_end	; cannot accept the carridge return
	cmp	al, lf
	je	get_cmt_end

	mov	cmmt1, al	; store it
	mov	cmmt, 1 	; 1 char. so far.
	call	get2
	cmp	al, ' '
	je	get_cmt_end
	cmp	al, tab
	je	get_cmt_end
	cmp	al, cr
	je	get_cmt_end
	cmp	al, lf
	je	end_commd_line_brdg

	mov	cmmt2, al
	inc	cmmt

get_cmt_end:
	call	get2
	cmp	al, lf
	jne	get_cmt_end		; skip it.

end_commd_line_brdg: jmp end_commd_line ; else jmp to end_commd_line

org_put_zero:				; make the filename in front of
	mov	byte ptr es:[di], 0	;  the comment string to be an asciiz.
	inc	di
	jmp	end_commd_line		;  (maybe null if device=/*)

end_file_slash: 			; al = "/" option char.
	mov	byte ptr es:[di],0	; make a filename an asciiz
	inc	di			; and
	stosb				; store "/" after that.
	jmp	short org5		; continue with the rest of the line

end_copy_file:
	mov	byte ptr es:[di-1], 0	; make it an asciiz and handle the next char.
	cmp	al, lf
	je	end_commd_line_brdg
	jmp	short org5

org4:					; org4 skips all delimiters after the command name except for '/'
	call	skip_comment
	jz	end_commd_line_brdg

	call	get2
	call	org_delim		; skip delimiters except '/' (mrw 4/88)
	jz	org4
	jmp	short org51

org5:					; rest of the line
	call	skip_comment		; comment?
	jz	end_commd_line_brdg
	call	get2			; not a comment.

org51:
	stosb				; copy the character
	cmp	al, '"' 		; a quote ?
	je	at_quote
	cmp	al, ' '
	ja	org5
					; M051 - Start

        cmp     cmd_indicator, CONFIG_DEVICEHIGH; Q: is this devicehigh
	jne	not_dh			; N: 
	cmp	al, lf			; Q: is this line feed
	je	org_dhlf		; Y: stuff a blank before the lf
	cmp	al, cr			; Q: is this a cr
	jne	org5			; N: 
	mov	byte ptr es:[di-1], ' '	; overwrite cr with blank
	stosb				; put cr after blank
	inc	[insert_blank]		; indicate that blank has been 
					; inserted
	jmp	org5
not_dh:					; M051 - End

	cmp	al, lf			; line feed?
	je	org1_brdg		; handles the next command line.
	jmp	org5			; handles next char in this line.

org_dhlf:				; M051 - Start
	cmp	[insert_blank], 1	; Q:has a blank already been inserted
	je	org1_brdg		; Y:
	mov	byte ptr es:[di-1], ' '	; overwrite lf with blank
	stosb				; put lf after blank
					; M051 - End

org1_brdg: 
	mov	[insert_blank], 0	; M051: clear blank indicator for 
					; M051: devicehigh
	jmp	org1

at_quote:
	cmp	com_level, 0
	je	up_level
	mov	com_level, 0		; reset it.
	jmp	org5

up_level:
	inc	com_level		; set it.
	jmp	org5

organize	endp

;
;----------------------------------------------------------------------------
;
; procedure : get2
;
;----------------------------------------------------------------------------
;
get2	proc	near
	jcxz	noget
        lods    byte ptr es:[si]
	dec	cx
	ret
noget:
	pop	cx
	mov	count,di
	mov	org_count, di
	xor	si,si
	mov	chrptr,si
ifndef  MULTI_CONFIG
	ret
else
;
;   This was the rather kludgy way out of procedure "organize", but instead
;   of returning to doconf, we now want to check config.sys BEGIN/END blocks
;   and the new boot menu stuff...
;
        mov     cx,di
        jmp     menu_check
endif
get2	endp




;
;----------------------------------------------------------------------------
;
; procedure : skip_comment
;
;skip the commented string until lf, if current es:si-> a comment string.
;in) es:si-> sting
;	 cx -> length.
;out) zero flag not set if not found a comment string.
;	  zero flag set if found a comment string and skipped it. al will contain
;	  the line feed charater at this moment when return.
;	  ax register destroyed.
;	  if found, si, cx register adjusted accordingly.
;
;----------------------------------------------------------------------------
;


skip_comment	proc	near

	jcxz	noget		; get out of the organize routine.
	cmp	com_level, 0	; only check it if parameter level is 0.
	jne	no_commt	;  (not inside quotations)

	cmp	cmmt, 1
	jb	no_commt

	mov	al, es:[si]
	cmp	cmmt1, al
	jne	no_commt

	cmp	cmmt, 2
	jne	skip_cmmt

	mov	al, es:[si+1]
	cmp	cmmt2, al
	jne	no_commt

skip_cmmt:
	jcxz	noget		; get out of organize routine.
	mov	al, es:[si]
	inc	si
	dec	cx
	cmp	al, lf		; line feed?
	jne	skip_cmmt

no_commt:
	ret

skip_comment	endp


ifdef   MULTI_CONFIG

        assume  ds:sysinitseg
;
;----------------------------------------------------------------------------
;
;   kbd_read: check boot keys during the startup delay
;
;   INPUT
;       DS == CS == sysinitseg
;
;   OUTPUT
;       Boot and query mode flags updated from the selected key
;
;   OTHER REGS USED
;       All
;
;   HISTORY
;       Created 16-Nov-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  kbd_read

kbd_read proc   near
        test    byte ptr [boot_runtime_flags],8
        jnz     short no_commt
        sub     dx,dx
        cmp     byte ptr [boot_safe],0
        jne     short kbd7_safe
        cmp     byte ptr [boot_menu],0
        je      short kbd7_wait
        jmp     kbd7_menu
kbd7_wait:
        cmp     word ptr [boot_delay],0
        je      short kbd7_shift
        mov     ax,182
        mul     word ptr [boot_delay]
        mov     cx,10
        div     cx
        mov     bp,ax
        push    ds
        sub     ax,ax
        mov     ds,ax
        mov     dx,ds:[046ch]
kbd7_wait_loop:
        mov     ah,1
        int     16h
        jnz     short kbd7_wait_done
        mov     ax,ds:[046ch]
        sub     ax,dx
        cmp     ax,bp
        jb      short kbd7_wait_loop
kbd7_wait_done:
        pop     ds
kbd7_shift:
        sub     dx,dx
        mov     ah,2
        int     16h
        test    al,3
        jz      short kbd7_check_key
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+54]
kbd7_safe:
        or      byte ptr [query_mode_flags],1
kbd7_check_key:
        mov     ah,1
        int     16h
        jnz     short kbd7_have_key
        jmp     kbd7_finish
kbd7_have_key:
        test    al,al
        jz      short kbd7_function_key
        cmp     al,1bh
        je      short kbd7_escape
        jmp     kbd7_finish
kbd7_escape:
        cmp     byte ptr [boot_mode],1
        jne     short kbd7_escape_flag
        inc     byte ptr [boot_mode]
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+4]
        jmp     kbd7_consume
kbd7_escape_flag:
        or      byte ptr [boot_runtime_flags],1
        jmp     kbd7_consume
kbd7_function_key:
        cmp     ah,3fh
        je      short kbd7_f5
        cmp     ah,62h
        je      short kbd7_f5_shift
        cmp     ah,6ch
        je      short kbd7_command
        cmp     ah,58h
        jne     short kbd7_other_key
        jmp     short kbd7_f12
kbd7_f5:
        or      byte ptr [query_mode_flags],1
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+54]
        jmp     kbd7_consume
kbd7_f12:
        or      byte ptr [query_mode_flags],2
        or      byte ptr [boot_runtime_flags],40h
        push    ds
        mov     ds,[BCodeSeg]
        assume  ds:Bios_Code
        or      byte ptr ds:[win386_info_flags],40h
        pop     ds
        assume  ds:sysinitseg
        jmp     short kbd7_f5
kbd7_f5_shift:
        or      byte ptr [compression_skip],1
        jmp     short kbd7_f12
kbd7_command:
        or      byte ptr [boot_runtime_flags],61h
        push    ds
        mov     ds,[BCodeSeg]
        assume  ds:Bios_Code
        or      byte ptr ds:[win386_info_flags],40h
        pop     ds
        assume  ds:sysinitseg
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+58]
        jmp     short kbd7_consume
kbd7_old_shift:
        or      byte ptr [compression_skip],1
kbd7_old:
        or      byte ptr [boot_config_flags],10h
        test    byte ptr [boot_runtime_flags],10h
        jnz     short kbd7_consume
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+118]
        jmp     short kbd7_consume
kbd7_other_key:
        cmp     ah,40h
        jne     short kbd7_old_key
        or      byte ptr [query_mode_flags],5
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+56]
        jmp     short kbd7_consume
kbd7_old_key:
        test    byte ptr [boot_runtime_flags],80h
        jnz     short kbd7_f8_test
        cmp     ah,3eh
        je      short kbd7_old
        cmp     ah,61h
        je      short kbd7_old_shift
kbd7_f8_test:
        cmp     ah,42h
        jne     short kbd7_step_test
        mov     ah,0
        int     16h
kbd7_menu:
        sub     di,di
        call    boot_build_menu
        jmp     short kbd7_finish
kbd7_step_test:
        cmp     ah,5bh
        je      short kbd7_step
        cmp     ah,65h
        jne     short kbd7_finish
kbd7_step:
        sub     dx,dx
        and     byte ptr [query_mode_flags],0feh
        or      byte ptr [query_mode_flags],8
        and     byte ptr [boot_runtime_flags],0efh
        cmp     [boot_delay],dx
        je      short kbd7_consume
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_msg_table+60]
kbd7_consume:
        mov     ah,0
        int     16h
        mov     byte ptr [secElapsed],-1
kbd7_finish:
        cmp     byte ptr [boot_mode],0
        je      short kbd7_message
        push    dx
        mov     dl,cr
        mov     ah,2
        int     21h
        mov     cx,79
kbd7_clear_line:
        mov     dl,' '
        mov     ah,2
        int     21h
        loop    kbd7_clear_line
        mov     dl,cr
        mov     ah,2
        int     21h
        pop     dx
kbd7_message:
        or      dx,dx
        jz      short kbd7_return
        call    print
kbd7_return:
        ret
kbd_read endp



;
;----------------------------------------------------------------------------
;
;   set_numlock: set numlock LED
;
;   INPUT
;       ES:SI -> numlock setting (ie, "ON" or "OFF")
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       None
;
;   HISTORY
;       Created 16-Nov-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  set_numlock

set_numlock proc near
        push    ax
        push    ds
        sub     ax,ax
        mov     ds,ax
        mov     ax,es:[si]      ; get 1st 2 bytes of value (ON or OF)
        cmp     ax,word ptr cs:[OnOff+2]; should we turn it off?
        jne     not_off         ; no
        and     byte ptr ds:[0417h],not 20h
        jmp     short set_done
not_off:
        cmp     ax,word ptr cs:[OnOff]  ; should we turn it on?
        stc
        jne     set_done        ; no
        or      byte ptr ds:[0417h],20h
set_done:
        pop     ds
        pop     ax
        ret
set_numlock endp

        assume  ds:sysinitseg

;
;----------------------------------------------------------------------------
;
;   menu_check:  check for presence of menu (and other) configuration blocks
;
;   INPUT
;       CX == "organized" config.sys memory image length
;    ES:SI -> "organized" config.sys memory image
;       DS == CS == sysinitseg
;
;   OUTPUT
;       Same as above;  the idea is that menu_check simply transforms
;       a block-structured config.sys image into a conventional image,
;       based on the user's block selection and any other boot-time options
;       the user may have employed...
;
;   OTHER REGS USED
;       All
;
;   NOTES
;       [count] and [org_count] are set to the new config.sys image length
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
; Compare menu characters.
menu_cmp_al_ah macro
        db      38h,0e0h
endm
        public  menu_check

menu_check  proc near
        mov     byte ptr [shell_opt_flags],0
        push    cx
        push    si
        sub     bx,bx
swchk7_loop:
        call    get_char
        jc      short swchk7_end
        cmp     al,CONFIG_BEGIN
        jne     short swchk7_next1
        inc     bx
        push    ds
        mov     ds,[bios_data_segment]
        assume  ds:Bios_Data
        test    byte ptr [bios_flags+1],20h
        pop     ds
        assume  ds:sysinitseg
        jnz     short swchk7_nextline
        mov     word ptr [boot_delay],0
        jmp     short swchk7_nextline
swchk7_next1:
        cmp     al,CONFIG_NUMLOCK
        jne     short swchk7_next2
        or      bx,bx
        jnz     short swchk7_nextline
        call    set_numlock
        mov     byte ptr es:[si-1],CONFIG_REM
        jmp     short swchk7_nextline
swchk7_next2:
        cmp     al,CONFIG_SWITCHES
        jne     short swchk7_nextline
swchk7_scan:
        call    get_char
swchk7_scan1:
        cmp     al,LF
        je      short swchk7_nextline
        cmp     al,'/'
        jne     short swchk7_scan
        call    get_char
        and     al,not 20h
        cmp     al,byte ptr swit_n+1
        jne     short swchk7_scan2
        or      byte ptr [boot_runtime_flags],8
        jmp     short swchk7_scan
swchk7_scan2:
        cmp     al,byte ptr swit_f+1
        jne     short swchk7_scan1
        mov     word ptr [boot_delay],0
        jmp     short swchk7_scan
swchk7_nextline:
        call    skip_opt_line
        jmp     short swchk7_loop
swchk7_end:
        pop     si
        pop     cx
        test    byte ptr [boot_runtime_flags],8
        jz      short swchk7_query
        and     byte ptr [query_mode_flags],0f6h
swchk7_query:
        test    byte ptr [query_mode_flags],1
        jz      short menu_search
        jmp     menu_abort
menu_search:
        mov     byte ptr [menu_previous_allowed],1
        sub     bx,bx           ; if no MENU, default to zero for no_selection
        mov     di,offset szMenu;
        call    find_block      ; find the MENU block
        jnc     menu_found      ;
        mov     byte ptr [szBoot],0
        jmp     no_selection    ; not found
;
;   Process the requested menu color(s)
;
menu_color:
        push    cx              ;
        push    dx              ;
        mov     dx,0007h        ; default color setting
        call    get_number      ; get first number
        and     bl,00Fh         ; first # is foreground color (for low nibble)
        mov     ch,bl           ; save it in CH
        and     dl,0F0h         ;
        or      dl,bl           ;
        call    delim           ; did we hit a delimiter
        jne     check_color     ; no, all done
        call    get_number      ; get next number
        and     bl,00Fh         ; second # is background color (for high nibble)
        mov     dh,bl           ; save it in DH
        and     dl,00Fh         ;
        mov     cl,4            ;
        shl     bl,cl           ;
        or      dl,bl           ;
check_color:                    ;
        db      38h,0f5h      ; cmp ch,dh; compare colors
        jne     set_color       ; no
        xor     dl,08h          ; yes, so modify the fgnd intensity
set_color:
        mov     [bMenuColor],dl ;
        pop     dx              ;
        pop     cx              ;
        jmp     menu_nextitem   ;
;
;   Back to our regularly scheduled program (the COLOR and other goop
;   above is there simply to alleviate short jump problems)
;
menu_found:
        mov     byte ptr [bDefBlock],1
        mov     word ptr [offDefBlock],0
        mov     byte ptr [secTimeOut],-1
        test    byte ptr [query_mode_flags],10h
        jz      short menu_query_ready
        and     byte ptr [query_mode_flags],0e7h
menu_query_ready:

        call    skip_opt_line   ; skip to next line
        sub     dx,dx           ; initialize total block count (0 => none yet)
;
;   Process the menu block now
;
menu_process:
        call    get_char        ; get first char of current line
        jc      short to_menu_getdefault ; could happen if menu block at end
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,CONFIG_BEGIN ; BEGIN implies END
        je      to_menu_getdefault
        cmp     al,CONFIG_SUBMENU
        je      menu_item       ; go process sub-menu
        cmp     al,CONFIG_MENUITEM
        je      menu_item       ; go process menu item
        cmp     al,CONFIG_MENUDEFAULT
        je      menu_default    ; go process menu default
        cmp     al,CONFIG_MENUCOLOR
        je      menu_color      ; go process menu color
        cmp     al,CONFIG_NUMLOCK
        je      menu_numlock    ;
        cmp     al,CONFIG_REM   ; allow remarks in menu block
        je      menu_nextitem   ;
        call    any_delim       ; allow blank lines and such
        je      menu_nextitem   ;
        stc                     ;
        call    print_error     ; non-MENU command!
        jmp     short menu_nextitem
menu_numlock:
        call    set_numlock
        jmp     short menu_nextitem
to_menu_getdefault:
        jmp     short menu_getdefault
;
;   Save the offset of the default block name, we'll need it later
;
menu_default:
        mov     [offDefBlock],si; save address of default block name
        cmp     byte ptr [secElapsed],0
        jne     timeout_skip    ; secElapsed is only zero for the FIRST menu,
        call    skip_token      ; and for subsequent menus IF nothing was typed;
        jc      menu_nextitem   ; secElapsed becomes -1 forever as soon as
        call    skip_delim      ; something is typed
        jc      menu_nextitem   ;
        mov     si,bx           ;
        call    get_number      ; get number (of seconds for timeout)
        test    bx,bx           ; negative timeout disables previous selection
        jns     short timeout_limit
        mov     byte ptr [menu_previous_allowed],0
        cmp     bx,-1           ; -1 means no timeout
        je      short timeout_ok
        neg     bx
timeout_limit:
        cmp     bx,90
        jb      timeout_ok      ; (besides, 99 is the largest # my simple
        mov     bl,90           ;  display function can handle)
timeout_ok:                     ;
        mov     [secTimeOut],bl ;
timeout_skip:
        jmp     short menu_nextitem
;
;   Verify that this is a valid menu item by searching for the named block
;
menu_item:
        cmp     dl,MAX_MULTI_CONFIG ; have we reached the max # of items yet?
        jae     menu_nextitem   ;
        mov     di,si           ; DS:DI -> block name to search for
        call    srch_block      ;
        je      menu_itemfound  ;
        stc                     ;
        call    print_error     ; print error and pause
        jmp     short menu_nextitem ; if not found, ignore this menu item
;
;   srch_block, having succeeded, returns DI -> past the token that it
;   just matched, which in this case should be a descriptive string;  ES:SI
;   and CX are unmodified
;
menu_itemfound:
        inc     dx              ; otherwise, increment total block count
        mov     bx,dx           ; and use it to index the arrays of offsets
        mov     abBlockType[bx],al
        add     bx,bx           ; of recorded block names and descriptions
;
;   There should be a description immediately following the block name on
;   MENUITEM line;  failing that, we'll just use the block name as the
;   description...
;
        mov     aoffBlockName[bx],si
        mov     aoffBlockDesc[bx],si
        mov     di,bx           ; skip_delim modifies BX, so stash it in DI
        call    skip_token      ;
        jc      menu_nextitem   ; hit eol/eof
        call    skip_delim      ;
        jc      menu_nextitem   ; hit eol/eof
        xchg    bx,di           ;
        mov     aoffBlockDesc[bx],di

menu_nextitem:
        call    skip_opt_line   ;
        jmp     menu_process    ; go back for more lines
;
;   Display menu items now, after determining which one is default
;
menu_getdefault:
        or      dl,dl           ; where there any valid blocks at all?
        jnz     menu_valid      ; yes
        sub     bx,bx           ; no, so force autoselect of 0
        jmp     menu_autoselect ; (meaning: process common blocks only)
menu_valid:
        sub     bx,bx           ;
        mov     [bMaxBlock],dl  ; first, record how many blocks we found
        xchg    bl,[menu_previous_allowed]
        or      bl,bl
        jz      short menu_no_previous
        mov     ax,[config_buffer_segment]
        or      ax,ax
        jz      short menu_no_previous
menu_previous_loop:
        push    bx
        add     bx,bx
        mov     si,aoffBlockDesc[bx]
        mov     cx,128
        push    ds
        mov     ds,[config_buffer_segment]
        assume  ds:nothing
        mov     di,1ch
menu_previous_cmp:
        call    get_char
        jc      short menu_previous_done
        cmp     al,'$'
        je      short menu_previous_char
        cmp     al,1fh
        ja      short menu_previous_char
        sub     al,al
menu_previous_char:
        mov     ah,[di]
        je      short menu_previous_end
        inc     di
        and     ax,0dfdfh
        menu_cmp_al_ah
        je      short menu_previous_cmp
        mov     ah,1
menu_previous_end:
        or      ah,ah
menu_previous_done:
        pop     ds
        assume  ds:sysinitseg
        pop     bx
        je      short menu_previous_found
        inc     bx
        cmp     bl,[bMaxBlock]
        jbe     short menu_previous_loop
menu_no_previous:
        sub     bx,bx
        jmp     short menu_finddefault
menu_previous_found:
        test    byte ptr [query_mode_flags],8
        jnz     short menu_setdefault
        jmp     short menu_autoselect
menu_finddefault:
        mov     di,[offDefBlock];
        or      di,di           ; does a default block exist?
        jz      menu_nodefault  ; no
        inc     bx              ; yes, walk name table, looking for default
menu_chkdefault:
        push    bx              ;
        add     bx,bx           ;
        mov     si,aoffBlockName[bx]
        mov     cx,128          ; arbitrary maximum length of a name
        push    ds              ;
        push    es              ;
        pop     ds              ;
        call    comp_names      ; is this block the same as the default?
        pop     ds              ;
        pop     bx              ;
        je      menu_setdefault ; yes
        inc     bx              ;
        cmp     bl,[bMaxBlock]  ; all done searching?
        jbe     menu_chkdefault ; not yet
menu_nodefault:
        mov     bl,1            ; if no default, force default to #1
menu_setdefault:
        mov     [bDefBlock],bl  ; yes, this will be the initial current block
;
;   If the timeout was explicitly set to 0 (or technically, anything that
;   failed to resolve to a number, like "NONE" or "EAT POTATOES"), then we're
;   supposed to skip menu display and run with the specified default block;
;   however, if the user hit Enter prior to boot, thereby requesting fully
;   INTERACTIVE boot, then we shall display the menu block anyway (though still
;   with no timeout)
;
        cmp     [secTimeOut],0  ; is timeout zero? (ie, assume default)
        jne     menu_display    ; no
        test    byte ptr [query_mode_flags],8
        jnz     menu_display    ; yes, so *don't* assume default after all
        jmp     short not_topmenu
;
;   Reset the mode, so that we know screen is clean and cursor is home
;
menu_display:
        inc     byte ptr [shell_opt_flags]
        sub     di,di
        call    display_menu

menu_autoselect:
        cmp     bx,-1           ; clean boot requested?
        jne     normal_boot     ; no
menu_abort:
        sub     cx,cx           ; then immediately exit with 0 config.sys image
        jmp     menu_exit       ;

normal_boot:
        cmp     bx,-2           ; back to top-level menu?
        jne     not_topmenu     ; no
        mov     cx,[count]      ; yes, start all over
        sub     si,si           ;
        jmp     menu_search

not_topmenu:
        cmp     abBlockType[bx],CONFIG_SUBMENU
        jne     not_submenu     ;
        add     bx,bx           ;
        mov     di,aoffBlockName[bx]
        call    srch_block      ; THIS CANNOT FAIL!
        mov     si,di           ;
        mov     cx,bx           ; ES:SI and CX are ready for another round
        jmp     menu_found

not_submenu:
        add     bx,bx           ; get BX -> name of selected block
        mov     bx,aoffBlockName[bx]
;
;   BX should now either be ZERO (meaning no block has been selected) or
;   the offset relative to ES of the block name to be processed (along with
;   all the "common" lines of course)
;
no_selection:
        mov     [offDefBlock],bx; save selection
        mov     cx,[count]      ; reset ES:SI and CX for reprocessing
        sub     si,si           ;
        push    ds              ;
        mov     ds,[config_wrkseg]; this is where we'll store new config.sys image
        assume  ds:nothing      ;
        sub     di,di           ;
;
;   ES:SI-> config.sys, DS:DI -> new config.sys workspace
;
;   Work our way through the config.sys image again, this time copying
;   all lines that are (A) "common" lines outside any block or (B) lines
;   within the requested block.  Lines inside INCLUDEd blocks are transparently
;   copied by copy_block in a recursive fashion;  the amount of recursion is
;   limited by the fact INCLUDE statements are REMed by copy_block as they are
;   processed and by the number of unique INCLUDE stmts in config.sys...
;
;   BUGBUG 20-Mar-1992 JeffPar:  If we can figure out the lower bound of the
;   stack we're running on, then we should check it inside copy_block
;
copyblock_loop:
        push    bx              ; save selected block name
        call    copy_block      ; process (named or common) block
        pop     bx              ;
        jc      move_config     ; hit eof
;
;   copy_block can only return for two reasons:  it hit eof or a new block
;
copyblock_begin:
        push    ax              ;
        push    cx              ;
        push    si              ;
        push    di              ; always do "common" blocks
        mov     di,offset szCommon
        push    ds              ;
        push    cs              ;
        pop     ds              ;
        call    comp_names      ;
        pop     ds              ;
        pop     di              ;
        pop     si              ;
        pop     cx              ;
        pop     ax              ;
        je      copyblock_check ;
        or      bx,bx           ; is there a block name to check?
        jz      copyblock_skip  ; no
        push    di              ;
        mov     di,bx           ; check block against given block name
        push    ds              ;
        push    es              ;
        pop     ds              ;
        call    comp_names      ; is this the block we really want to do?
        pop     ds              ;
        pop     di              ;
copyblock_check:
        jc      move_config     ; hit eof
        jne     copyblock_skip  ;
        call    skip_opt_line   ;
        jmp     short copyblock_loop ;

copyblock_skip:                 ;
        call    skip_opt_line   ; this ain't the block we wanted, so skip it
        call    get_char        ;
        jc      move_config     ; hit eof
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,CONFIG_BEGIN ;
        je      copyblock_begin ;
        jmp     short copyblock_skip ; anything else is just skipped
;
;   To create as little risk to the rest of SysInit as little as possible,
;   and to free the workspace at "config_wrkseg" for creating an environment,
;   copy the new config.sys image to "confbot"
;
move_config:
        mov     cx,di           ; now copy workspace at DS:DI to "confbot"
        push    cx              ;
;
;   But first, copy the CONFIG=<configuration><0> string to the workspace,
;   since the configuration name only currently exists in the "confbot" area
;
        mov     cx,offset szMenu-offset szBoot-1
        mov     si,offset szBoot; first copy the CONFIG= part
        inc     di              ; skip a byte, in case absolutely nothing
                                ; was copied to the workspace, because we always
                                ; zero the first byte of the workspace (below)
copy_boot:                      ;
        lods    byte ptr cs:[si];
        mov     [di],al         ;
        inc     di              ;
        loop    copy_boot       ;

        push    es              ; then copy the configuration name
        mov     si,cs:[offDefBlock]; ES:SI -> default block name
        or      si,si           ; valid?
        jnz     short l1_check  ; yes
        push    cs              ;
        pop     es              ;
        mov     si,offset szCommon
        jmp     short l1
l1_check:
        mov     bx,offset boot_config_name
        cmp     byte ptr cs:[bx],0
        je      short l1
        push    si
        mov     cx,32
boot_name_loop:
        mov     al,cs:[bx]
        test    al,al
        jz      short boot_name_done
        call    boot_toupper
        mov     ah,al
        mov     al,es:[si]
        call    boot_toupper
        menu_cmp_al_ah
        jne     short boot_name_changed
        inc     bx
        inc     si
        loop    boot_name_loop
        jmp     short boot_name_done
boot_name_changed:
        or      byte ptr cs:[boot_runtime_flags],20h
boot_name_done:
        pop     si
l1:
        mov     cx,128-7
l1_copy:
        mov     al,es:[si]      ;
        call    any_delim       ;
        je      l2              ;
        mov     [di],al         ;
        inc     si              ;
        inc     di              ;
        loop    l1_copy
l2:     mov     byte ptr [di],LF; terminate the configuration string
        pop     es              ;
;
;   Now we can copy "config_wrkseg" (DS) to "confbot" (ES)
;
        sub     di,di           ;
        mov     [config_envlen],di
        sub     si,si           ;
        pop     cx              ; recover the size of "config_wrkseg"

        push    cx              ;
        rep     movsb           ; moved!
        pop     cx              ;
        mov     ax,ds           ;
        pop     ds              ;
        assume  ds:sysinitseg   ;
;
;   Now that the config_wrkseg is available once again, we shall
;   use it to create an environment.  The first thing to go in will be
;   the "CONFIG=configuration" thing.  It is also important to zero
;   the first byte of the workspace, so that copy_envvar knows the buffer
;   is empty.
;
        push    es              ;
        mov     es,ax           ;
        inc     si              ; ES:SI -> "CONFIG=configuration"
        mov     byte ptr es:[0],0;empty the environment block
        mov     dx,1            ; create the CONFIG environment variable
        call    copy_envvar     ; copy envvar at ES:SI to "config_wrkseg"
        pop     es
        cmp     byte ptr [shell_opt_flags],0
        je      short menu_done
        mov     dx,1
        call    boot_logo_display
;
;   Before returning, restore the default video page setting but do NOT
;   do it using INT 10h's Set Active Page function, because if the menu was
;   displayed on a different page, then it's because we don't want to see
;   all the device driver/TSR goop (which goes to the default page)
;
menu_done:
        cmp     byte ptr [bMenuPage],0
        je      menu_exit       ;
        push    es              ;
        mov     ax,40h          ;
        mov     es,ax           ;
        mov     ax,[wCRTStart]  ;
        mov     es:[004Eh],ax   ;
        mov     al,[bCRTPage7]
        mov     es:[0062h],al   ;
        pop     es              ;
menu_exit:
        mov     [count],cx      ; set new counts
        mov     [org_count],cx  ;
        ret
menu_check  endp

;
;----------------------------------------------------------------------------
;
;   copy_envvar:  find or update the envvar in "config_wrkseg"
;
;   INPUT
;    ES:SI -> environment variable (in the form "var=string<cr/lf>")
;       DX == 0 to find the value; nonzero to update the variable
;
;   OUTPUT
;       Lookup: DX == value offset in config_wrkseg, or zero if not found
;       Update: config_envlen updated; an empty value deletes the variable
;       Carry set if the variable name has no '='
;
;   OTHER REGS USED
;       AX, BX, DI
;
;   NOTES
;       None
;
;   HISTORY
;       Created 29-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  copy_envvar
        assume  ds:sysinitseg,es:nothing

copy_envvar proc near
        push    cx              ;
        push    si              ;
        push    ds              ;
        push    es              ;
        push    es              ;
        mov     es,[config_wrkseg]; ES:DI to point to next available byte
        pop     ds                ; DS:SI to point to envvar
        assume  ds:nothing      ;
;
;   Have to calculate the length of the variable name (and if we hit
;   the end of the line before we hit '=', then it's curtains for this
;   config.sys line)
;
;   The check for NULL is important because copy_envvar is also used to copy
;   the initial CONFIG= setting, which will have been zapped by a NULL if no
;   menu block existed (in order to prevent the creation of an environment)
;
        sub     cx,cx           ;
copy_varlen:                    ;
        lodsb                   ;
        or      al,al           ; NULL?
        stc                     ;
        jnz     short copy_notnull
        jmp     near ptr copy_envexit
copy_notnull:
        cmp     al,CR           ;
        stc                     ;
        je      copy_envexit    ;
        cmp     al,LF           ;
        stc                     ;
        je      copy_envexit    ;
        inc     cx              ;
        cmp     al,'='          ;
        jne     copy_varlen     ;
        mov     al,0            ;
        mov     ah,[si]         ; save char after '='
        sub     si,cx           ; back up to given varname
        dec     cx              ; CX == # of bytes in varname
        sub     di,di           ; start looking for DS:SI at ES:0
copy_varsrch:
        cmp     byte ptr es:[di],al
        je      copy_envprep    ; search failed, just copy var
        mov     bx,di           ; ES:BX -> start of this varname
        push    cx              ;
        push    si              ;
        repe    cmpsb           ;
        pop     si              ;
        pop     cx              ;
        jne     copy_varnext    ; no match, skip to next varname
        cmp     byte ptr es:[di],'='
        jne     copy_varnext    ; no match, there's more characters
        test    dx,dx           ; zero requests the value without changing it
        jnz     short copy_vardestroy
        lea     dx,[di+1]
        jmp     short copy_envexit
copy_vardestroy:
;
;   Previous occurrence of variable has been found;  determine the
;   entire length and then destroy it
;
        mov     cx,-1           ;
        repne   scasb           ; guaranteed to get null (since we put it there)
        push    si              ;
        mov     si,di           ;
        mov     di,bx           ;
        mov     cx,cs:[config_envlen]
        sub     cx,si           ; destroy variable now
        rep     movs byte ptr es:[di],byte ptr es:[si]
        pop     si              ;
copy_envprep:
        test    dx,dx
        jz      short copy_envexit
        test    ah,ah
        jz      short copy_envdel
        cmp     ah,CR           ; if there is nothing after the '='
        je      copy_envdel     ; then just exit with variable deleted
        cmp     ah,LF           ;
        je      copy_envdel     ;
        jmp     short copy_envloop

copy_varnext:                   ;
        push    cx              ;
        mov     cx,-1           ;
        repne   scasb           ;
        pop     cx              ;
        jmp     short copy_varsrch    ;

copy_envloop:                   ;
        lodsb                   ;
        test    al,al
        jz      short copy_envdone
        cmp     al,CR           ;
        je      copy_envdone    ;
        cmp     al,LF           ;
        je      copy_envdone    ;
        stosb                   ;
        jmp     short copy_envloop ;

copy_envdone:                   ;
        sub     al,al           ; do SUB to clear carry as well
        stosb                   ; always null-terminate these puppies
copy_envdel:                    ;
        mov     es:[di],al      ; and stick another null to terminate the env.
        mov     cs:[config_envlen],di

copy_envexit:                   ;
        pop     es              ;
        pop     ds              ;
        assume  ds:sysinitseg   ;
        pop     si              ;
        pop     cx              ;
        ret                     ;
copy_envvar endp

;
;----------------------------------------------------------------------------
;
;   copy_block:  copy the current block to the new config.sys workspace
;
;   INPUT
;       CX == remaining bytes in "organized" config.sys memory image
;    ES:SI -> remaining bytes in "organized" config.sys memory image
;    DS:DI -> new config.sys workspace (equal in size to the original
;             config.sys image) where the current block is to be copied
;
;   OUTPUT
;       Same as above
;       AL also equals the last character read from the organized image
;
;   OTHER REGS USED
;       All
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  copy_block

copy_block  proc near
        call    get_char        ; check for include
        jc      copy_done       ;
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,CONFIG_BEGIN ; another BEGIN implies END as well
        je      copy_done       ;
;
;   BOOTCON relies on these things being in-memory (sigh)
;
;       cmp     al,CONFIG_REM   ; don't bother copying this
;       je      copy_nextline   ;
;       cmp     al,CONFIG_COMMENT;don't bother copying this either
;       je      copy_nextline   ;
;
;   This is being left out for old reporting of bad command lines;
;   alternatively, we could report the error here and save the rest of
;   sysinit from ever having to deal with bogus CONFIG.SYS stuff...
;
;       cmp     al,CONFIG_UNKNOWN;don't bother copying this either too
;       je      copy_nextline   ;
                                ;
        cmp     al,CONFIG_INCLUDE
        mov     al,ah           ; AL == the original line code
        jne     copy_line       ; not an "include" line
;
;   We have hit an "INCLUDE" line;  first, REM out the line so that we
;   never try to include the block again (no infinite include loops please),
;   then search for the named block and call copy_block again.
;
        mov     byte ptr es:[si-1],CONFIG_REM
        push    di              ;

        mov     di,offset szMenu
        call    comp_names_safe ; don't allow INCLUDE MENU
        je      copy_skip       ;

        mov     di,offset szCommon
        call    comp_names_safe ; don't allow INCLUDE COMMON
        je      copy_skip       ;

        mov     di,si           ; try to find the block
        call    srch_block      ;
        mov     dx,di           ;
        pop     di              ;
        jne     copy_error      ; no such block
        push    cx              ;
        mov     cx,bx           ;
        push    si              ;
        dec     dx              ;
        mov     si,dx           ;
        call    skip_line       ; skip the rest of the "block name" line
        call    copy_block      ; and copy in the rest of that block
        pop     si              ;
        pop     cx              ;
        sub     al,al           ; force skip_opt_line to skip...
        jmp     short copy_nextline

copy_skip:
        pop     di
copy_error:
        clc                     ;
        call    print_error     ; note that carry is clear, no pause
        jmp     short copy_nextline
;
;   Copy the line at ES:SI to the current location at DS:DI
;
copy_line:
        mov     [di],al         ;
        inc     di              ;
        cmp     al,' '          ; is this is a "real" line with a "real" code?
        jb      copy_nextline   ; no
        cmp     cs:[config_multi],0
        je      copy_loop       ; not a multi-config config.sys, don't embed #s
        call    get_linenum     ; BX == line # of line @ES:SI
        mov     [di],bx         ; stash it immediately following the line code
        inc     di              ;
        inc     di              ;
        jmp     short copy_next ;
copy_loop:                      ;
        call    get_char        ;
        jc      copy_done       ; end of file
        mov     [di],al         ;
        inc     di              ;
copy_next:
        cmp     al,LF           ; done with line?
        jne     copy_loop       ; nope

copy_nextline:
        call    skip_opt_line   ;
        jmp     short copy_block ;

copy_done:
        ret
copy_block  endp

;
;----------------------------------------------------------------------------
;
;   get_linenum:  return line # (in BX) of current line (@ES:SI)
;
;   INPUT
;    ES:SI -> some line in the config.sys memory image
;
;   OUTPUT
;       BX == line # (relative to 1)
;
;   OTHER REGS USED
;       DX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  get_linenum

get_linenum proc near
        push    ax              ;
        sub     bx,bx           ; BX == line # (to be returned)
        push    cx              ;
        mov     dx,si           ; DX == the offset we're looking for
        push    si              ;
        mov     cx,cs:[count]   ;
        sub     si,si           ; prepare to scan entire file
get_linenum_loop:               ;
        call    skip_line       ;
        jc      get_linenum_done;
        inc     bx              ;
        cmp     si,dx           ; have we exceeded the desired offset yet?
        jb      get_linenum_loop; no
get_linenum_done:               ;
        pop     si              ;
        pop     cx              ;
        pop     ax              ;
        ret                     ;
get_linenum endp

;
;----------------------------------------------------------------------------
;
;   srch_block:  searches entire config.sys for block name @ES:DI
;
;   INPUT
;       ES -> config.sys image
;    ES:DI -> block name to find
;
;   OUTPUT
;       ZF flag set, if found
;    ES:DI -> just past the name in the block heading, if found
;       BX == # bytes remaining from that point, if found
;
;   OTHER REGS USED
;       None
;
;   NOTES
;       This differs from "find_block" in that it searches the ENTIRE
;       config.sys image, not merely the remaining portion, and that it
;       takes a pointer to block name that is *elsewhere* in the image
;       (ie, ES) as opposed to some string constant in our own segment (DS).
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  srch_block

srch_block  proc near           ; returns BX -> named block in CONFIG.SYS
        push    ax              ;
        push    cx              ;
        mov     cx,cs:[count]   ;
        push    si              ;
        sub     si,si           ;
        push    ds              ;
        push    es              ;
        pop     ds              ;
        call    find_block      ;
        mov     di,si           ;
        mov     bx,cx           ;
        pop     ds              ;
        pop     si              ;
        pop     cx              ;
        pop     ax              ;
        ret                     ;
srch_block  endp

;
;----------------------------------------------------------------------------
;
;   find_block:  searches rest of config.sys for block name @DS:DI
;
;   INPUT
;    DS:DI -> block name to find
;    ES:SI -> remainder of config.sys image
;       CX == remaining size of config.sys image
;
;   OUTPUT
;       ZF flag set, if found (also, CF set if EOF)
;    ES:SI -> where the search stopped (at end of block name or EOF)
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       This differs from "srch_block" in that it searches only the
;       remaining portion of the config.sys image and leaves SI and CX
;       pointing to where the search left off, and that it takes a pointer
;       to search string in our own segment (DS:DI instead of ES:DI).
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  find_block

find_block  proc near
        call    get_char        ; get line code
        jc      find_exit       ; end of file
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,CONFIG_BEGIN ; beginning of a block?
        je      check_line      ; no
        cmp     al,CONFIG_INCLUDE
        jne     next_line       ;
        or      cs:[config_multi],1
        jmp     short next_line ;
check_line:
        or      cs:[config_multi],1
        call    comp_names      ; compare block names
        jbe     find_exit       ; end of file, or names matched
next_line:
        call    skip_opt_line   ; no, so skip to next line
        jmp     short find_block ;
find_exit:
        ret
find_block  endp

;
;----------------------------------------------------------------------------
;
;   comp_names:  compares keyword @DS:DI to position in config.sys @ES:SI
;
;   INPUT
;    DS:DI -> keyword to compare
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       ZF flag set, if match (also, CF set if EOF)
;    ES:SI -> where the comparison stopped (at end of block name or EOF)
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  comp_names

comp_names  proc near
        push    di              ;
comp_loop:                      ;
        call    get_char        ;
        jc      comp_exit       ;
        call    any_delim       ; is next character a delimiter?
        mov     ah,[di]         ; (get next character we're supposed to match)
        je      comp_almost     ; yes, it *could* be a match
        inc     di              ;
        and     ax,not 2020h    ; BUGBUG -- assumes both names are alphanumeric -JTP
        menu_cmp_al_ah          ; match?
        je      comp_loop       ; yes, keep looking at the characters
        clc                     ; prevent erroneous eof indication: clear carry
comp_exit:                      ;
        pop     di              ;
        ret                     ;
comp_almost:                    ;
        xchg    al,ah           ; we don't know for sure if it's a match
        call    any_delim       ; until we verify that the second string has
        xchg    al,ah           ; been exhausted also...
        jmp     short comp_exit ; if we are, this call to any_delim will tell...
comp_names  endp

        public  comp_names_safe

comp_names_safe proc near
        push    ax
        push    cx
        push    si
        push    ds
        push    cs
        pop     ds
        call    comp_names
        pop     ds
        pop     si
        pop     cx
        pop     ax
        ret
comp_names_safe endp


;
;----------------------------------------------------------------------------
;
;   display_menu: display the menu and obtain the selected block
;
;   INPUT
;    DS:DI -> optional message (DI == 0 if none)
;       DS == CS == sysinitseg
;
;   OUTPUT
;       BX == selected block, -1 for clean boot, or -2 to return to prior menu
;
;   OTHER REGS USED
;       AX, CX, DX
;
;----------------------------------------------------------------------------
;
display_menu proc near
        mov     ah,0fh
        int     10h
        mov     ah,0
        int     10h
        push    es
        mov     ax,40h
        mov     es,ax
        mov     ax,es:[4eh]
        mov     [wCRTStart],ax
        mov     al,es:[62h]
        mov     [bCRTPage7],al
        mov     ax,word ptr [bMenuPage]
        int     10h
        mov     ax,0600h
        mov     bh,[bMenuColor]
        sub     cx,cx
        mov     dl,byte ptr es:[CRT_Cols]
        dec     dl
        mov     dh,byte ptr es:[CRT_Rows]
        or      dh,dh
        jnz     short display_menu_clear
        mov     dh,[bLastRow]
display_menu_clear:
        int     10h
        pop     es
        mov     [bLastRow],dh
        call    print_indexed
        dw      8013h
        test    byte ptr [boot_runtime_flags],8
        jnz     short display_menu_items
        mov     bh,[bMenuPage]
        mov     dh,[bLastRow]
        mov     dl,0
        mov     ah,2
        int     10h
        call    print_indexed
        dw      8015h
        mov     ah,3
        int     10h
        sub     dl,2
        mov     [bLastCol],dl
display_menu_items:
        mov     bx,1
display_menu_loop:
        call    print_item
        inc     bx
        cmp     bl,[bMaxBlock]
        jbe     display_menu_loop
        mov     dl,0
        mov     dh,bl
        add     dh,6
        mov     bh,[bMenuPage]
        mov     ah,2
        int     10h
        test    di,di
        jz      short display_menu_prompt
        mov     dx,di
        call    print
display_menu_prompt:
        mov     dl,0
        mov     dh,bl
        add     dh,4
        mov     bh,[bMenuPage]
        mov     ah,2
        int     10h
        call    print_indexed
        dw      8014h
        call    select_item
        mov     cx,1
        test    di,di
        jz      short display_menu_crlf
        mov     cx,4
display_menu_crlf:
        call    print_indexed
        dw      8005h
        loop    display_menu_crlf
        push    word ptr [boot_runtime_flags]
        or      byte ptr [boot_runtime_flags],8
        call    show_status
        pop     word ptr [boot_runtime_flags]
        ret
display_menu endp

;
;----------------------------------------------------------------------------
;
;   print_item:  display menu item #BL
;
;   INPUT
;       BL == menu item # to display
;
;   OUTPUT
;       Menu item displayed, with appropriate highlighting if BL == bDefBlock
;
;   OTHER REGS USED
;       None
;
;   NOTES
;       This function saves/restores the current cursor position, so you
;       needn't worry about it.
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  print_item

print_item  proc near           ; prints menu item #BL (1 to N)
        .286
        pusha
        .8086
        mov     ah,03h          ; get cursor position
        mov     bh,[bMenuPage]  ; selected video page
        int     10h             ; DH/DL = row/column
        push    dx              ; save it
        mov     ah,02h          ; set cursor position
        mov     dh,bl           ;
        add     dh,3            ;
        mov     dl,5            ;
        int     10h             ; set cursor position for correct row/col
        mov     al,bl           ;
        add     al,'0'          ; convert menu item # to ASCII digit
        mov     ah,[bMenuColor] ; normal attribute
        cmp     bl,[bDefBlock]  ; are we printing the current block?
        jne     print_other     ; no
        or      ah,70h          ; yes, set bgnd color to white
        mov     ch,ah           ;
        mov     cl,4            ;
        rol     ch,cl           ;
        db      38h,0e5h      ; cmp ch,ah; compare colors
        jne     print_other     ; no
        xor     ah,08h          ; yes, so modify the fgnd intensity
print_other:                    ;
        mov     bh,0            ;
        add     bx,bx           ;
        mov     di,aoffBlockDesc[bx]
        mov     bl,ah           ; put the attribute in the correct register now
        mov     bh,[bMenuPage]  ; get correct video page #
        mov     ah,09h          ; write char/attr
        mov     cx,1            ;
        int     10h             ;
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        mov     ax,0900h+'.'    ;
        int     10h             ; display '.'
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        mov     ax,0900h+' '    ;
        int     10h             ; display ' '
        inc     dl              ; increment column
        mov     ah,02h          ;
        int     10h             ;
        push    es              ;
print_loop:                     ;
        mov     al,es:[di]      ; get a character of the description
        inc     di              ;
        cmp     al,TAB          ; substitute spaces for tabs
        jne     print_nontab    ;
        mov     al,' '          ;
print_nontab:                   ;
        cmp     al,' '          ;
        jb      print_done      ; stop at the 1st character < space
        cmp     al,'$'          ;
        je      print_done      ; also stop on $
        mov     ah,09h          ; display function #
        int     10h             ;
        inc     dl              ; increment column
        cmp     dl,78           ; far enough?
        jae     print_done      ; yes
        mov     ah,02h          ;
        int     10h             ;
        jmp     print_loop      ;
print_done:                     ;
        pop     es              ;
        pop     dx              ;
        mov     ah,02h          ;
        int     10h             ; restore previous row/col
        .286
        popa
        .8086
        ret                     ;
print_item  endp

;
;----------------------------------------------------------------------------
;
;   select_item:  wait for user to select menu item, with time-out
;
;   INPUT
;       None
;
;   OUTPUT
;       BX == menu item # (1-N), -1 for clean boot, or -2 for prior menu
;       Selected menu item highlighted
;       Cursor positioned beneath menu, ready for tty-style output now
;
;   OTHER REGS USED
;       AX, CX, DX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  select_item

select_item proc near           ; returns digit value in BX (trashes AX/CX/DX)
        mov     bl,[bDefBlock]  ; BL will be the default block #
        mov     al,bl           ;
        call    disp_num        ;
        call    show_status     ; display current interactive status
        cmp     byte ptr [secTimeOut],-1
        je      input_key       ; no time-out, just go to input
        mov     ah,Get_Time     ;
        int     21h             ;
        mov     bh,dh           ; BH = initial # of seconds
check_time:
        mov     al,[secTimeOut] ;
        sub     al,[secElapsed] ;
        jae     show_time       ;
        or      byte ptr [query_mode_flags],10h ; accept remaining commands
        mov     byte ptr [secElapsed],0
        jmp     select_done     ; time's up!
show_time:
        push    bx              ;
        mov     bl,al           ; save # in BL
        mov     bh,[bMenuPage]  ;
        mov     ah,03h          ; get cursor position
        int     10h             ;
        push    dx              ;
	add	dl,8		; move cursor to the right
        mov     ah,02h          ; set cursor position
        int     10h             ;
        call    print_indexed
        dw      8018h
        mov     al,bl           ; recover # from BL
        cbw                     ; this works because AL is always <= 90
        mov     cl,10           ;
        div     cl              ; AL = tens digit, AH = ones digit
        mov     cl,ah           ;
        add     al,'0'          ;
        mov     ah,0Eh          ;
        int     10h             ; write TTY tens digit
        mov     al,cl           ;
        add     al,'0'          ;
        mov     ah,0Eh          ;
        int     10h             ; write TTY ones digit
        pop     dx
        mov     ah,02h          ; set cursor position back to where it was
        int     10h             ;
        pop     bx              ;
input_key:
        mov     ah,Raw_Con_IO   ;
        mov     dl,0FFh         ; input request
        int     21h             ;
        jnz     got_key         ;
        cmp     byte ptr [secTimeOut],-1; is there a time-out?
        je      input_key       ; no, just go back to input
        mov     ah,Get_Time     ;
        int     21h             ; DH = seconds
        mov     ah,dh           ;
        sub     dh,bh           ; should generally be zero or one
        mov     bh,ah           ;
        jnc     got_time        ;
        mov     dh,1            ; it wrapped back to zero, so assume one
got_time:
        or      dh,dh           ; any change?
        jz      input_key       ; no
        add     [secElapsed],dh ;
        jmp     check_time      ;
got_key:
        push    ax              ;
        mov     ax,-1           ; zap both secTimeOut and secElapsed
        xchg    word ptr [secTimeOut],ax
        cmp     al,-1           ; was time-out already disabled?
        je      timeout_disabled; yes
        push    bx              ; let's disable # seconds display
        mov     ax,0A20h        ; write multiple spaces
        mov     bx,word ptr [bMenuColor]
        mov     cx,80           ; 80 of them, to be safe
        int     10h             ; to completely obliterate # seconds display
        pop     bx              ;
timeout_disabled:
        pop     ax              ;
        or      al,al           ; extended key pressed?
        jz      short extended_key
        jmp     normal_key
extended_key:
        int     21h             ; get the next part of the key then
        jz      input_key       ; hmmm, what happened to the second part?

        cmp     al,48h          ; up arrow?
        jne     not_up          ; no
        cmp     bl,1            ; are we as up as up can get?
        jbe     input_key       ; yes, ignore it
        dec     [bDefBlock]     ;
        call    print_item      ; re-print the current item
        dec     bl              ; and then print the new current item
        jmp     short print1
not_up:
        cmp     al,50h          ; down arrow?
        jne     not_down        ; no
        cmp     bl,[bMaxBlock]  ; are we as down as down can get?
        jae     to_input_key    ; yes, ignore it
        inc     [bDefBlock]     ;
        call    print_item      ; re-print the current item
        inc     bx              ; and then print the new current item
print1: mov     al,bl           ;
print2: call    print_item      ;
        call    disp_num        ;
to_input_key:
        jmp     input_key       ;
not_down:
        test    byte ptr [boot_runtime_flags],8
        jnz     to_input_key
        mov     ah,1
        test    byte ptr [boot_runtime_flags],80h
        jnz     short menu_key_62
        cmp     al,3eh
        jne     short menu_key_62
        or      byte ptr [boot_config_flags],10h
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_62:
        cmp     al,62h
        jne     short menu_key_5b
        or      byte ptr [compression_skip],1
        jmp     short menu_key_skip
menu_key_5b:
        cmp     al,5bh
        jne     short menu_key_3f
        xor     byte ptr [query_mode_flags],8
        call    show_status
        jmp     input_key
menu_key_3f:
        cmp     al,3fh
        jne     short menu_key_58
menu_key_set:
        or      [query_mode_flags],ah
menu_key_clean:
        mov     bx,-1
        mov     al,' '
        jmp     short disp_input
menu_key_58:
        cmp     al,58h
        jne     short menu_key_6c
menu_key_skip:
        or      ah,2
        jmp     short menu_key_set
menu_key_6c:
        cmp     al,6ch
        jne     short menu_key_40
        or      byte ptr [boot_runtime_flags],21h
        jmp     short menu_key_clean
menu_key_40:
        cmp     al,40h
        jne     to_input_key
        or      ah,4
        jmp     short menu_key_set

normal_key:
        cmp     al,0Dh          ; Enter?
        je      select_done     ; yes
        cmp     al,08h          ; backspace?
        jne     not_backspace   ; no
        mov     bx,-2           ; yes, special return code
        ret                     ;
not_backspace:
        sub     al,'0'          ; is greater than '0'?
        jbe     to_input_key    ; no
        cmp     al,[bMaxBlock]  ; is less than or equal to the maximum digit?
        ja      to_input_key    ; no
        mov     [bDefBlock],al  ;
        call    print_item      ; redisplay the current selection
        mov     bl,al           ; set new selection
        jmp     print2

select_done:
        mov     bh,0            ; return a full 16-bit value (for indexing)
        mov     al,bl           ;
        add     al,'0'          ; convert it into a digit, then display it
        if2
        .errnz  disp_input-$    ; fall into disp_input
        endif
select_item endp

;
;----------------------------------------------------------------------------
;
;   disp_input:  display a single character + cr/lf
;
;   INPUT
;       AL == character to display
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       DX
;
;   NOTES
;       This function is used not only for the menu input selection but
;       also for the interactive line prompting (the y/n/a thing).
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  disp_input

disp_input  proc near
        push    ax
        cmp     al,' '
        jae     disp_ok
        mov     al,' '
disp_ok:
        mov     dl,al
        mov     ah,Std_Con_Output
        int     21h
        call    print_indexed
        dw      8005h
        pop     ax
        ret
disp_input  endp

disp_num    proc near
        push    bx
        add     al,'0'
        mov     ah,0Ah
        mov     bx,word ptr [bMenuColor]
        mov     cx,1
        int     10h
        pop     bx
        ret
disp_num    endp

;
;----------------------------------------------------------------------------
;
;   show_status:  display current interactive mode setting (on/off/none)
;
;   INPUT
;       None
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       AX, CX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  show_status

show_status proc near
        push    bx              ; BL = video page #
        mov     bx,word ptr [bMenuColor]
        mov     ah,03h          ; get cursor position
        int     10h             ;
        push    dx              ; save it
        mov     ah,02h          ; set cursor position
        mov     dx,word ptr [bLastCol]   ; set correct row/col
        test    byte ptr [boot_runtime_flags],8
        jz      show_onoff      ; just show on/off
        mov     dl,0            ;
        int     10h             ;
        mov     ax,0A20h        ; write multiple spaces
        mov     cx,80           ; 80 of them, to be exact
        int     10h             ; to obliterate the status line
        jmp     short show_done ;
show_onoff:                     ;
        int     10h             ;
        mov     al,[query_no]
        test    byte ptr [query_mode_flags],8
        jz      show_noton
        mov     al,[query_yes]
show_noton:                     ;
        mov     ah,0Eh          ; write TTY
        int     10h             ;
show_done:                      ;
        pop     dx              ;
        mov     ah,02h          ;
        int     10h             ; restore original cursor position
        pop     bx              ;
        ret                     ;
show_status endp

;
;----------------------------------------------------------------------------
;
;   skip_token:  advances ES:SI/CX past the current token
;
;   INPUT
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       CF set if EOL/EOF hit
;       AL == 1st char of delimiter
;    ES:SI -> just past the delimiter
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  skip_token

skip_token  proc near
        call    get_char
        jc      skip_token_done
        call    any_delim
        jne     skip_token
skip_check_eol:
        cmp     al,CR
        je      skip_token_eol
        cmp     al,LF
        je      skip_token_eol
        clc
        jmp     short skip_token_done
skip_token_eol:
        stc
skip_token_done:
        ret
skip_token  endp

;
;----------------------------------------------------------------------------
;
;   skip_delim:  advances ES:SI/CX past the current delimiter
;
;   INPUT
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       CF set if EOF hit
;       AL == 1st char of token
;    ES:SI -> just past the token
;       CX == # bytes remaining from that point
;    ES:BX -> new token (since ES:SI is already pointing 1 byte past token)
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  skip_delim

skip_delim  proc near           ; returns carry set if eol/eof
        call    get_char        ;
        lea     bx,[si-1]       ; also returns BX -> next token
        jc      skip_token_done ;
        call    delim           ;
        je      skip_delim      ;
        jmp     skip_check_eol  ;
skip_delim  endp

;
;----------------------------------------------------------------------------
;
;   skip_opt_line:  same as skip_line provided AL != LF
;
;   INPUT
;       AL == last character read
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       CF set if EOF hit
;       AL == 1st char of new line
;    ES:SI -> just past 1st char of new line
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       In other words, the purpose here is to skip to the next line,
;       unless ES:SI is already sitting at the front of the next line (which
;       it would be if the last character fetched -- AL -- was a linefeed)
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  skip_opt_line

skip_opt_line   proc near
        cmp     al,LF
        je      skip_line_done
        if2
        .errnz  skip_line-$     ; fall into skip_line
        endif
skip_opt_line   endp

;
;----------------------------------------------------------------------------
;
;   skip_line:  skip to the next line
;
;   INPUT
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       CF set if EOF hit
;    ES:SI -> just past 1st char of new line
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  skip_line

skip_line   proc near
        call    get_char
        jc      skip_line_done
        cmp     al,LF
        jne     skip_line
skip_line_done:
        ret
skip_line   endp

;
;----------------------------------------------------------------------------
;
;   get_number:  return binary equivalent of numeric string
;
;   INPUT
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       AL == non-digit encountered
;       BX == binary #
;    ES:SI -> just past 1st non-digit
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  get_number

get_number  proc near
        push    dx              ; save caller's DX
        sub     bx,bx           ; BX = result
        sub     dx,dx           ; DX = sign flag
num_loop:
        call    get_char        ;
        jc      num_done        ;
        cmp     al,'-'          ; negative number?
        jne     num_digit       ; no
        not     dx              ; toggle sign
        jmp     short num_loop  ;
num_digit:
        cmp     al,'0'          ; convert to value
        jb      num_done        ; no more number
        cmp     al,'9'          ;
        ja      num_done        ;
        push    ax              ;
        mov     ax,10           ;
        push    dx              ;
        mul     bx              ;
        pop     dx              ;
        mov     bx,ax           ;
        pop     ax              ;
        sub     al,'0'          ;
        cbw                     ;
        add     bx,ax           ;
        jmp     num_loop        ;
num_done:
        or      dx,dx           ; negative result?
        jz      num_positive    ; no
        neg     bx              ;
num_positive:
        pop     dx              ; restore caller's DX
        ret
get_number  endp

;
;----------------------------------------------------------------------------
;
;   get_char:  return next character, advance ES:SI, and decrement CX
;
;   INPUT
;    ES:SI -> position in config.sys
;       CX == remaining bytes in config.sys
;
;   OUTPUT
;       AL == next character
;    ES:SI -> just past next character
;       CX == # bytes remaining from that point
;
;   OTHER REGS USED
;       AX
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  get_char

get_char    proc near
        sub     cx,1            ; use SUB to set carry,zero
        jb      get_fail        ; out of data
        lods    byte ptr es:[si];
        mov     ah,al           ;
        ret                     ;
get_fail:                       ; restore CX to zero
        mov     cx,0            ; leave carry set, zero not set
nearby_ret:
        ret
get_char    endp

;
;----------------------------------------------------------------------------
;
;   query_user:  ask user whether to execute current config.sys command
;
;   INPUT
;       AL == current command code
;    ES:SI -> current command line in config.sys
;    config_cmd == current command code, but with QUERY bit intact
;    DS:DX -> caller-supplied prompt for command codes 00h and 01h
;
;   OUTPUT
;       CF set and AH == CONFIG_REM if command should be ignored
;       query_result set to 1 for an affirmative response
;
;   OTHER REGS USED
;       BX, CX, DX, DI
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  query_user, query_check_skip, query_check_done

query_user  proc near
        mov     byte ptr [query_result],0
        test    byte ptr [query_mode_flags],1
        jz      query_check_skip
        test    byte ptr [bQueryOpt],1
        jnz     query_check_skip
        jmp     skip_all
query_check_skip:
        test    byte ptr [query_mode_flags],2
        jz      query_check_done
        jmp     skip_all
query_check_done:
        test    byte ptr [query_mode_flags],50h
        jnz     nearby_ret
        push    ax
        mov     al,[config_cmd]
        test    byte ptr [query_mode_flags],8
        jnz     query_prepare
        test    al,CONFIG_OPTION_QUERY
        jnz     query_prepare
        jmp     do_cmd
query_prepare:
        call    query_keyboard_service
query_all:
;
;   Search for the command code (AL) in "comtab", and then print
;   out the corresponding keyword, followed by the rest of the actual
;   line pointed to by ES:SI
;
        push    si                      ; save pointer to rest of CONFIG.SYS line
; The caller supplies the generic prompt in DS:DX.
        and     al,NOT CONFIG_OPTION_QUERY
        cmp     al,1
        jbe     generic_prompt

        mov     dh,al                   ; save config_cmd in DH
        sub     bx,bx                   ;
        mov     di,offset comtab        ;
find_match:                             ;
        mov     bl,[di]                 ; get size of current keyword
        or      bl,bl                   ;
        jz      line_print              ; end of table
        inc     di                      ;
        cmp     al,[di+bx]              ; match?
        je      cmd_match               ; yes
        lea     di,[di+bx+1]            ; otherwise, skip this command code
        jmp     find_match              ; loop
cmd_match:                              ;
        mov     cl,[di-1]               ;
        mov     ch,0                    ;
        mov     ah,Std_Con_Output
cmd_print:                              ;
        mov     al,[di]                 ;
        inc     di                      ;
        mov     dl,al                   ;
        int     21h                     ;
        loop    cmd_print               ;
        mov     dl,'='                  ;
        cmp     dh,CONFIG_SET           ; for SET commands, don't display a '='
        jne     cmd_notset              ;
        mov     dl,' '                  ;
cmd_notset:
        int     21h                     ; '=' looks funny on SET commands
line_print:                             ;
        lods    byte ptr es:[si]        ;
        or      al,al                   ;
        jnz     non_null                ;
        mov     al,' '                  ;
non_null:                               ;
        cmp     al,' '                  ; control code?
        jb      prompt_user             ; yes, assume end of line
        jne     non_space               ;
        cmp     byte ptr es:[si],' '    ;
        jb      prompt_user             ;
non_space:                              ;
        mov     dl,al                   ;
        mov     ah,Std_Con_Output       ;
        int     21h                     ;
        jmp     line_print              ;
prompt_user:                            ;
        mov     dx,offset sysinit_msg_base
        add     dx,word ptr [sysinit_prompt_index]

generic_prompt:
        call    print                   ;
input_loop:
        mov     ax,0c08h                ; flush input and read a character
        int     21h
        test    al,al                   ; extended key?
        jnz     not_func
        test    byte ptr [boot_runtime_flags],8
        jnz     input_loop
        mov     ah,8
        int     21h
        mov     ah,1
        cmp     al,'?'
        je      set_query_mode
        cmp     al,'X'
        je      set_skip_mode
        cmp     al,'@'
        jne     input_loop
        or      ah,4
        jmp     short set_query_mode
set_skip_mode:
        or      ah,2
set_query_mode:
        or      [query_mode_flags],ah
answer_no:
        mov     al,[query_no]
        jmp     short legal_char
not_func:
        cmp     al,0dh
        je      answer_yes
        cmp     al,1bh
        je      answer_no
        cmp     al,[query_no]
        je      answer_no
        cmp     al,[query_yes]
        je      answer_yes
        cmp     al,[query_no_lower]
        je      answer_no
        cmp     al,[query_yes_lower]
        je      answer_yes
        cmp     al,9
        jne     check_all_char
        or      byte ptr [query_mode_flags],40h
        jmp     short answer_yes
check_all_char:
        test    byte ptr [config_cmd],7fh
        jz      input_loop
        cmp     al,[query_all_char]
        je      answer_all
        cmp     al,[query_all_lower]
        jne     input_loop
answer_all:
        or      byte ptr [query_mode_flags],10h
answer_yes:
        mov     byte ptr [query_result],1
        mov     al,[query_yes]
legal_char:
        test    byte ptr [query_display_flags],1
        jnz     query_no_echo
        call    disp_input
query_no_echo:
        and     byte ptr [query_display_flags],0feh
        pop     si
        cmp     al,[query_no]
        je      skip_cmd
        cmp     al,[query_no_lower]
        je      skip_cmd
do_cmd:
        pop     ax
        clc
        ret
skip_cmd:
        pop     ax
skip_all:
        mov     ah,CONFIG_REM
        stc
        ret
query_user  endp

;
;----------------------------------------------------------------------------
;
;   print_error:  displays multi-config error conditions
;
;   INPUT
;    Carry set to pause, clear to not
;    ES:SI -> current command line in config.sys
;
;   OUTPUT
;       None
;
;   OTHER REGS USED
;       None
;
;   NOTES
;       None
;
;   HISTORY
;       Created 16-Mar-1992 by JeffPar
;
;----------------------------------------------------------------------------
;
        public  print_error
        extrn   linecount:word

print_error proc near
        push    ax
        push    bx
        push    cx
        push    dx
        push    ds
        push    cs
        pop     ds
        pushf
        call    get_linenum
        mov     [linecount],bx
        call    error_line
        popf
        jnc     pe_ret
        call    print_indexed
        dw      801ah           ; pause message
        mov     ax,0C07h                ; flush input buffer, then wait for key
        int     21h                     ; wait for a key
        or      al,al                   ; extended key?
        jnz     @F                      ; no
        mov     ah,07h                  ; yes
        int     21h                     ; eat it too
@@:
        call    print_indexed
        dw      8005h           ; carriage return and line feed
pe_ret: pop     ds
        pop     dx
        pop     cx
        pop     bx
        pop     ax
	ret
print_error endp


        assume  ds:nothing

endif  ;MULTI_CONFIG

;
;----------------------------------------------------------------------------
;
; procedure : delim
;
;----------------------------------------------------------------------------
;
ifdef   MULTI_CONFIG
any_delim proc  near
        cmp     al,CR
        je      delim_ret
        cmp     al,LF
        je      delim_ret
        cmp     al,'['
        je      delim_ret
        cmp     al,']'
        je      delim_ret
        if2
        .errnz  delim-$
        endif
any_delim endp
endif  ;MULTI_CONFIG

delim	proc	near
	cmp	al,'/'		; ibm will assume "/" as an delimeter.
	jz	delim_ret

	cmp	al, 0		; special case for sysinit!!!
	jz	delim_ret

org_delim:			; used by organize routine except for getting
	cmp	al,' '          ;the filename.
	jz	delim_ret
        cmp     al,TAB
	jz	delim_ret
	cmp	al,'='
	jz	delim_ret
	cmp	al,','
	jz	delim_ret
	cmp	al,';'
ifdef   MULTI_CONFIG
;
;   Make sure there's no chance of a false EOF indication
;
        clc
endif
delim_ret:
	ret
delim	endp

;
;----------------------------------------------------------------------------
;
; procedure : newline
;
;  newline returns with first character of next line
;
;----------------------------------------------------------------------------
;

newline	proc	near

	call	getchr			;skip non-control characters
	jc	nl_ret
	cmp	al,lf			;look for line feed
	jnz	newline
	call	getchr
nl_ret:
	ret

newline	endp

;
;----------------------------------------------------------------------------
; 
; procedure : mapcase
;
;----------------------------------------------------------------------------
;
mapcase	proc	near
	push	cx
	push	si
	push	ds

	push	es
	pop	ds

ifdef   MULTI_CONFIG
        mov     bl,al                   ; same cmd code this line
else
	xor	si,si
endif

convloop:
	lodsb

	ifdef	DBCS
	call	testkanj
	jz	normconv		; if this is not lead byte

	mov	ah,al
	lodsb				; get tail byte
	cmp	ax,DB_SPACE
	jnz	@f			; if this is not dbcs space
	mov	word ptr [si-2],'  '	; set 2 single space
@@:

	dec	cx
        jcxz    convdone                ; just ignore 1/2 kanji error
	jmp	short noconv

;fall through, know al is not in 'a'-'z' range

normconv:
	endif

	cmp	al,'a'
	jb	noconv
	cmp	al,'z'
	ja	noconv
	sub	al,20h
	mov	[si-1],al
noconv:
ifdef   MULTI_CONFIG
;
;   When MULTI_CONFIG enabled, "mapcase" is used to map everything to
;   upper-case a line at a time, after we've been able to figure out whether
;   the line is a SET command or not (since we don't want to upper-case
;   anything after the "=" in a SET)
;
        cmp     bl,CONFIG_SET           ; preserve case for part of the line?
        jne     check_eol               ; no, just check for end-of-line
        cmp     al,'='                  ; separator between SET var and value?
        je      convdone                ; yes
check_eol:
        cmp     al,cr
        je      convdone
        cmp     al,lf
        je      convdone
endif
	loop	convloop

convdone:
	pop	ds
	pop	si
	pop	cx
	ret

	ifdef	DBCS

	public	testkanj
testkanj:
	push	si
	push	ds

	push	ax
	mov	ax,6300h		; get dos dbcs vector
	int	21h
	pop	ax

bdbcs_do:

	cmp	ds:word ptr [si],0	; end of lead byte info?
	jz	bdbcs_notfound		; jump if so
	cmp	al,ds:[si]		; less than first byte character?
	jb	bdbcs_next		; jump if not
	cmp	al,ds:[si+1]		; grater than first byte character?
	ja	bdbcs_next

bdbcs_found:

	push	ax
	xor	ax,ax
	inc	ax			; reset zero flag
	pop	ax

bdbcs_exit:

	pop	ds
	pop	si
	ret

bdbcs_notfound:

	push	ax
	xor	ax,ax			; set zero flag
	pop	ax
	jmp	short bdbcs_exit

bdbcs_next:

	add	si,2			; points next lead byte table
	jmp	short bdbcs_do

	endif  ; DBCS

mapcase	endp

;
;----------------------------------------------------------------------------
;
; procedure : calldev
;
;----------------------------------------------------------------------------
;
;
; Call the device entry, accommodating the directory and swap drivers.
;
        .286
calldev proc near
        lds     si,cs:[DevEntry]
        push    si
        add     bx,si
        mov     ax,[bx]
        mov     word ptr cs:[DevEntry],ax
        mov     bx,offset packet
        push    es
        push    si
        mov     si,offset config_record_ptr+6
        cmp     word ptr cs:[si],'ID'
        jne     short calldev_swap
        cmp     word ptr cs:[si+2],'RC'
        jne     short calldev_swap
        cmp     word ptr cs:[si+4],'UM'
        jne     short calldev_swap
        cmp     word ptr cs:[si+6],'10'
        jne     short calldev_swap
        push    bx
        shr     bx,4
        mov     ax,es
        add     ax,bx
        mov     es,ax
        pop     bx
        and     bx,0fh
        mov     si,40h
        mov     ds,si
        pop     si
        mov     ds,word ptr ds:[0eh]
        push    word ptr [bx+3]
        push    ds
        mov     ds,word ptr cs:[DevEntry+2]
        call    dword ptr cs:[DevEntry]
        pop     ds
        pop     word ptr [bx+3]
        jmp     short calldev_done
calldev_swap:
        cmp     word ptr cs:[si],'SS'
        jne     short calldev_call
        cmp     word ptr cs:[si+2],'AW'
        jne     short calldev_call
        cmp     word ptr cs:[si+4],' P'
        jne     short calldev_call
        cmp     word ptr cs:[si+6],'  '
        jne     short calldev_call
        pusha
        mov     byte ptr cs:[config_swap_active],1
        mov     ax,4a18h
        int     2fh
        popa
calldev_call:
        pop     si
        call    dword ptr cs:[DevEntry]
        cmp     byte ptr cs:[config_swap_active],0
        je      short calldev_done
        pusha
        mov     byte ptr cs:[config_swap_active],0
        mov     ax,4a16h
        int     2fh
        popa
calldev_done:
        pop     es
        pop     word ptr cs:[DevEntry]
        ret
calldev endp
        .8086

        assume  ds:nothing
;
;----------------------------------------------------------------------------
;
; procedure : todigit
;
;----------------------------------------------------------------------------
;
todigit	proc	near
	sub	al,'0'
	jb	notdig
	cmp	al,9
	ja	notdig
	clc
	ret
notdig:
	stc
	ret
todigit	endp

;
;----------------------------------------------------------------------------
;
; procedure : getnum
;
; getnum parses a decimal number.
; returns it in ax, sets zero flag if ax = 0 (may be considered an
; error), if number is bad carry is set, zero is set, ax=0.
;
;----------------------------------------------------------------------------
;

getnum	proc	near

	push	bx
	xor	bx,bx			; running count is zero

b2:
	call	todigit 		; do we have a digit
	jc	badnum			; no, bomb

	xchg	ax,bx			; put total in ax
	push	bx			; save digit
	mov	bx,10			; base of arithmetic
	mul	bx			; shift by one decimal di...
	pop	bx			; get back digit
	add	al,bl			; get total
	adc	ah,0			; make that 16 bits
	jc	badnum			; too big a number

	xchg	ax,bx			; stash total

	call	getchr			;get next digit
	jc	b1			; no more characters
	cmp	al, ' ' 		; space?
	jz	b15			; then end of digits
	cmp	al, ',' 		; ',' is a seperator!!!
	jz	b15			; then end of digits.
	cmp	al, tab 		; tab
	jz	b15
	cmp	al,sepchr		; allow 0 or special separators
	jz	b15
	cmp	al,'/'			; see if another switch follows
	nop				; cas - remnant of old bad code
	nop
	jz	b15
	cmp	al,lf			; line-feed?
	jz	b15
	cmp	al,cr			; carriage return?
	jz	b15
	or	al,al			; end of line separator?
	jnz	b2			; no, try as a valid char...

b15:
	inc	count			; one more character to s...
	dec	chrptr			; back up over separator
b1:
	mov	ax,bx			; get proper count
	or	ax,ax			; clears carry, sets zero accordingly
	pop	bx
	ret
badnum:
	mov	sepchr,0
	xor	ax,ax		; set zero flag, and ax = 0
	pop	bx
	stc			; and carry set
	ret

getnum	endp





ENDIF ; CONFIGPROC

;
;----------------------------------------------------------------------------
;


IFDEF	CONFIGPROC


;*****************************************************************

setdoscountryinfo	proc	near

;input: es:di -> pointer to dos_country_cdpg_info
;	ds:0  -> buffer.
;	si = 0
;	ax = country id
;	dx = code page id. (if 0, then use ccsyscodepage as a default.)
;	bx = file handle
;	this routine can handle maxium 438 country_data entries.
;
;output: dos_country_cdpg_info set.
;	 carry set if any file read failure or wrong information in the file.
;	 carry set and cx = -1 if cannot find the matching country_id, codepage
;	 _id in the file.

	push	di
	push	ax
	push	dx

	xor	cx,cx
	xor	dx,dx
	mov	ax,512			;read 512 bytes
	call	readincontrolbuffer	;read the file header
	jc	setdosdata_fail

	push	es
	push	si

	push	cs
	pop	es

	mov	di,offset country_file_signature
	mov	cx,8			;length of the signature
	repz	cmpsb

	pop	si
	pop	es
	jnz	setdosdata_fail 	;signature mismatch

	add	si,18			;si -> county info type
	cmp	byte ptr ds:[si],1	;only accept type 1 (currently only 1 header type)
	jne	setdosdata_fail 	;cannot proceed. error return

	inc	si			;si -> file offset
	mov	dx,word ptr ds:[si]	;get the info file offset.
	mov	cx,word ptr ds:[si+2]
	mov	ax,6144			;read 6144 bytes.
	call	readincontrolbuffer	;read info
	jc	setdosdata_fail

	mov	cx, word ptr ds:[si]	;get the # of country, codepage combination entries
	cmp	cx, 438			;cannot handle more than 438 entries.
					;	
	ja	setdosdata_fail

	inc	si
	inc	si			;si -> entry information packet
	pop	dx			;restore code page id
	pop	ax			;restore country id
	pop	di

setdoscntry_find:			;search for desired country_id,codepage_id.
	cmp	ax, word ptr ds:[si+2]	;compare country_id
	jne	setdoscntry_next

	cmp	dx, 0			;no user specified code page ?
	je	setdoscntry_any_codepage;then no need to match code page id.
	cmp	dx, word ptr ds:[si+4]	;compare code page id
	je	setdoscntry_got_it

setdoscntry_next:
	add	si, word ptr ds:[si]	;next entry
	inc	si
	inc	si			;take a word for size of entry itself
	loop	setdoscntry_find

	mov	cx, -1			;signals that bad country id entered.
setdoscntry_fail:
	stc
	ret

setdosdata_fail:
	pop	si
	pop	cx
	pop	di
	jmp	short setdoscntry_fail

setdoscntry_any_codepage:		;use the code_page_id of the country_id found.
	mov	dx, word ptr ds:[si+4]

setdoscntry_got_it:			;found the matching entry
	mov	cs:cntrycodepage_id, dx ;save code page id for this country.
	mov	dx, word ptr ds:[si+10] ;get the file offset of country data
	mov	cx, word ptr ds:[si+12]
	mov	ax, 512 		;read 512 bytes
	call	readincontrolbuffer
	jc	setdoscntry_fail

	mov	cx, word ptr ds:[si]	;get the number of entries to handle.
	inc	si
	inc	si			;si -> first entry

setdoscntry_data:
	push	di			;es:di -> dos_country_cdpg_info
	push	cx			;save # of entry left
	push	si			;si -> current entry in control buffer

	mov	al, byte ptr ds:[si+2]	;get data entry id
	call	getcountrydestination	;get the address of destination in es:di
        jnc     short @F
        jmp     near ptr setdoscntry_data_next
@@:

	mov	dx, word ptr ds:[si+4]	;get offset of data
	mov	cx, word ptr ds:[si+6]
	mov	ax,4200h
	stc
	int	21h			;move pointer
	jc	setdosdata_fail

	mov	dx,512			;start of data buffer
	mov	cx,20			;read 20 bytes only. we only need to
	mov	ah,3fh			;look at the length of the data in the file.
	stc
	int	21h			;read the country.sys data
	jc	setdosdata_fail 	;read failure

	cmp	ax,cx
	jne	setdosdata_fail

	mov	dx,word ptr ds:[si+4]	;get offset of data again.
	mov	cx,word ptr ds:[si+6]
	mov	ax,4200h
	stc
	int	21h			;move pointer back again
	jc	setdosdata_fail

	push	si
	mov	si,(512+8)		;get length of the data from the file
	mov	cx,word ptr ds:[si]
	pop	si
	mov	dx,512			;start of data buffer
	add	cx,10			;signature + a word for the length itself
	mov	ah,3fh			;read the data from the file.
	stc
	int	21h
	jc	setdosdata_fail

	cmp	ax, cx
	jne	setdosdata_fail

	mov	al,byte ptr ds:[si+2]	;save data id for future use.
	mov	si,(512+8)		;si-> data buffer + id tag field
	mov	cx,word ptr ds:[si]	;get the length of the file
	inc	cx			;take care of a word for lenght of tab
	inc	cx			;itself.
	cmp	cx,(2048 - 512 - 8)	;fit into the buffer?
        jbe     short @F
        jmp     near ptr setdosdata_fail
@@:

	if	bugfix
	call	setdbcs_before_copy
	endif

	cmp	al, setcountryinfo	;is the data for setcountryinfo table?
	jne	setdoscntry_mov 	;no, don't worry

	push	word ptr es:[di+ccmono_ptr-cccountryinfolen]	;cannot destroy ccmono_ptr address. save them.
	push	word ptr es:[di+ccmono_ptr-cccountryinfolen+2]	;at this time di -> cccountryinfolen
	push	di			;save di

	push	ax
	mov	ax,cs:cntrycodepage_id	;do not use the code page info in country_info
	mov	ds:[si+4], ax		;use the saved one for this !!!!
	pop	ax

setdoscntry_mov:
	rep	movsb			;copy the table into dos
	cmp	al, setcountryinfo	;was the ccmono_ptr saved?
	jne	setdoscntry_data_next

	pop	di			;restore di
	pop	word ptr es:[di+ccmono_ptr-cccountryinfolen+2]	 ;restore
	pop	word ptr es:[di+ccmono_ptr-cccountryinfolen]

setdoscntry_data_next:
	pop	si			;restore control buffer pointer
	pop	cx			;restore # of entries left
	pop	di			;restore pointer to dso_country_cdpg
	add	si, word ptr ds:[si]	;try to get the next entry
	inc	si
	inc	si			;take a word of entry length itself
	dec	cx
	cmp	cx,0
	je	setdoscntry_ok
	jmp	setdoscntry_data

setdoscntry_ok:
	ret
setdoscountryinfo	endp

	if	bugfix
setdbcs_before_copy	proc	near

	cmp	al,setdbcs		; dbcs vector set?
	jnz	@f			; jump if not
	cmp	word ptr es:[di], 0	; zero byte data block?
	jz	@f			; jump if so

	push	di
	push	ax
	push	cx
	mov	cx,es:[di]		; load block length
	add	di,2			; points actual data
	xor	al,al			; fill bytes
	rep	stosb			; clear data block
	pop	cx
	pop	ax
	pop	di
@@:
	ret
setdbcs_before_copy	endp
	endif

getcountrydestination	proc	near

;get the destination address in the dos country info table.
;input: al - data id
;	es:di -> dos_country_cdpg_info
;on return:
;	es:di -> destination address of the matching data id
;	carry set if no matching data id found in dos.

	push	cx
	add	di,ccnumber_of_entries	;skip the reserved area, syscodepage etc.
	mov	cx,word ptr es:[di]	;get the number of entries
	inc	di
	inc	di			;si -> the first start entry id

getcntrydest:
	cmp	byte ptr es:[di],al
	je	getcntrydest_ok
	cmp	byte ptr es:[di],setcountryinfo ;was it setcountryinfo entry?
	je	getcntrydest_1

	add	di,5			;next data id
	jmp	short getcntrydest_loop

getcntrydest_1:
	add	di,new_country_size + 3 ;next data id
getcntrydest_loop:
	loop	getcntrydest
	stc
	jmp	short getcntrydest_exit

getcntrydest_ok:
	cmp	al,setcountryinfo	;select country info?
	jne	getcntrydest_ok1

	inc	di			;now di -> cccountryinfolen
	jmp	short getcntrydest_exit

getcntrydest_ok1:
	les	di,dword ptr es:[di+1]	;get the destination in es:di

getcntrydest_exit:
	pop	cx
	ret
getcountrydestination	endp


readincontrolbuffer	proc	near

;move file pointer to cx:dx
;read ax bytes into the control buffer. (should be less than 2 kb)
;si will be set to 0 hence ds:si points to the control buffer.
;entry:  cx,dx offset from the start of the file where the read/write pointer
;	 be moved.
;	 ax - # of bytes to read
;	 bx - file handle
;	 ds - buffer seg.
;return: the control data information is read into ds:0 - ds:0200.
;	 cx,dx value destroyed.
;	 carry set if error in reading file.

	push	ax			;# of bytes to read
	mov	ax, 4200h
	stc
	int	21h			;move pointer
	pop	cx			;# of bytes to read
	jc	ricb_exit

	xor	dx,dx			;ds:dx -> control buffer
	xor	si,si
	mov	ah,3fh			;read into the buffer
	stc
	int	21h			;should be less than 1024 bytes.

ricb_exit:
	ret
readincontrolbuffer	endp


set_country_path	proc	near

;in:  ds - sysinitseg, es - confbot, si -> start of the asciiz path string
;     dosinfo_ext, cntry_drv, cntry_root, cntry_path
;     assumes current directory is the root directory.
;out: ds:di -> full path (cntry_drv).
;     set the cntry_drv string from the country=,,path command.
;     ds, es, si value saved.

	push	si

	push	ds			;switch ds, es
	push	es
	pop	ds
	pop	es			;now ds -> confbot, es -> sysinitseg

	call	chk_drive_letter	;current ds:[si] is a drive letter?
	jc	scp_default_drv 	;no, use current default drive.

	mov	al, byte ptr ds:[si]
	inc	si
	inc	si			;si -> next char after ":"
	jmp	short scp_setdrv

scp_default_drv:
	mov	ah, 19h
	int	21h
	add	al, "A"			;convert it to a character.

scp_setdrv:
	mov	cs:cntry_drv, al	;set the drive letter.
	mov	di, offset cntry_path
	mov	al, byte ptr ds:[si]
	cmp	al, "\"
	je	scp_root_dir

	cmp	al,"/"			;let's accept "/" as an directory delim
	je	scp_root_dir

	jmp	short scp_path

scp_root_dir:
	dec	di			;di -> cntry_root
scp_path:
	call	move_asciiz		;copy it

	mov	di, offset cntry_drv
scpath_exit:

	push	ds			;switch ds, es
	push	es
	pop	ds
	pop	es			;ds, es value restored

	pop	si
	ret
set_country_path	endp


chk_drive_letter	proc	near
;check if ds:[si] is a drive letter followed by ":".
;assume that every alpha charater is already converted to upper case.
;carry set if not.

	push	ax
	cmp	byte ptr ds:[si], "A"
	jb	cdletter_no
	cmp	byte ptr ds:[si], "Z"
	ja	cdletter_no
	cmp	byte ptr ds:[si+1], ":"
	jne	cdletter_no

	jmp	short cdletter_exit

cdletter_no:
	stc

cdletter_exit:
	pop	ax
	ret
chk_drive_letter	endp


move_asciiz	proc	near
;in: ds:si -> source es:di -> target
;out: copy the string until 0.
;assumes there exists a 0.

masciiz_loop:
	movsb
	cmp	byte ptr ds:[si-1],0	;was it 0?
	jne	masciiz_loop
	ret
move_asciiz	endp



ENDIF ; CONFIGPROC



;
;	ds:dx points to string to output (asciz)
;
;	prints <badld_pre> <string> <badld_post>

badfil:
	push	cs
	pop	es

	mov	si,dx
badload:
	mov	dx,offset sysinit_msg_base
	add	dx,cs:[sysinit_badld_index]
	mov	bx,offset sysinit_msg_base
	add	bx,cs:[sysinit_crlf_index]

prnerr:
	push	cs
	pop	ds
	assume	ds:sysinitseg
	cmp	bQueryOpt,0
	jne	short badfil_print
	cmp	linecount,0
	je	prnexit
badfil_print:
	call	print

prn1:
	mov	dl,es:[si]
	or	dl,dl
	jz	prn2
	mov	ah,std_con_output
	int	21h
	inc	si
	jmp	prn1

prn2:
	mov	dx,bx
	call	print

IFDEF	CONFIGPROC
	cmp	cs:donotshownum,1
	je	prnexit
	call	error_line
ENDIF ; CONFIGPROC

prnexit:
	ret
	assume	ds:nothing

print:
	mov	ah,std_con_string_output
	int	21h
	ret




	if	noexec

; load non exe file called [ds:dx] at memory location es:bx

ldfil:
	push	ax
	push	bx
	push	cx
	push	dx
	push	si
	push	ds
	push	bx

	xor	ax,ax			;open the file
	mov	ah,open
	stc				;in case of int 24
	int	21h
	pop	dx			;clean stack in case jump
	jc	ldret

	push	dx
	mov	bx,ax			;handle in bx
	xor	cx,cx
	xor	dx,dx
	mov	ax,(lseek shl 8) or 2
	stc				;in case of int 24
	int	21h			; get file size in dx:ax
	jc	ldclsp

	or	dx,dx
	jnz	lderrp			; file >64k
	pop	dx

	push	dx
	mov	cx,es			; cx:dx is xaddr
	add	dx,ax			; add file size to xaddr
	jnc	dosize
	add	cx,1000h		; ripple carry
dosize:
	mov	ax,dx
	call	pararound
	mov	dx,ax

	add	cx,dx
	cmp	cx,[alloclim]
	jb	okld
	jmp	mem_err

okld:
	xor	cx,cx
	xor	dx,dx
	mov	ax,lseek shl 8		;reset pointer to beginning of file
	stc				;in case of int 24
	int	21h
	jc	ldclsp

	pop	dx

	push	es			;read the file in
	pop	ds			;trans addr is ds:dx

	mov	cx,0ff00h		; .com files arn't any bigger than
					; 64k-100h
	mov	ah,read
	stc				;in case of int 24
	int	21h
	jc	ldcls

	mov	si,dx			;check for exe file
	cmp	word ptr [si],"ZM"
	clc				; assume ok
	jnz	ldcls			; only know how to do .com files

	stc
	jmp	short ldcls

lderrp:
	stc
ldclsp:
	pop	dx			;clean stack
ldcls:
	pushf
	mov	ah,close		;close the file
	stc
	int	21h
	popf

ldret:	pop	ds
	pop	si
	pop	dx
	pop	cx
	pop	bx
	pop	ax
	ret
	endif

;
;  open device pointed to by dx, al has access code
;   if unable to open do a device open null device instead
;
open_dev:
	call	open_file
	jnc	open_dev3

open_dev1:
	mov	dx,offset nuldev
	call	open_file
of_ret:
	ret

open_dev3:
	mov	bx,ax			; handle from open to bx
	xor	ax,ax			; get device info
	mov	ah,ioctl
	int	21h
	test	dl,10000000b
	jnz	of_ret

	mov	ah,close
	int	21h
	jmp	open_dev1

open_file:
	mov	ah,open
	stc
	int	21h
	ret

; test int24. return back to dos with the fake user response of "fail"

int24:
	mov	al, 3			; fail the system call
	iret				; return back to dos.

include copyrigh.inc			; copyright statement


nuldev	db	"NUL",0
condev	db	"CON",0
auxdev	db	"AUX",0
prndev	db	"PRN",0

IFDEF	CONFIGPROC
config	db	"\CONFIG.SYS",0

cntry_drv   db	  "A:"
cntry_root  db	  "\"
cntry_path  db	  "COUNTRY.SYS",0
	    db	  52 dup (0)

country_file_signature db 0ffh,'COUNTRY'

cntrycodepage_id dw ?

ifdef   MULTI_CONFIG
menu_previous_allowed db 0             ; allow previous menu selection
endif
pathstring db   64 dup (0)

ENDIF ; CONFIGPROC


IFDEF	CONFIGPROC


ifdef   MULTI_CONFIG
;
;   Beware of byte pairs accessed as words (see all "KEEP AFTER" notes below)
;
        public  shell_opt_flags, bQueryOpt
shell_opt_flags db      0
bMenuColor      db      07h ;1Fh        ; default fgnd/bgnd color
bMenuPage       db      0               ; menu video page (KEEP AFTER bMenuColor)
                db      5               ; video page function # (KEEP AFTER bMenuPage)
bLastCol        db      ?               ; ending column on status line
bLastRow        db      24              ; row # of status line (KEEP AFTER bLastCol)
bCRTPage7       label   byte            ; saved video page
bDisableUI      db      0               ; 1=disable clean/interactive
                                        ; 2=disable default 2-second delay
        public  boot_config_flags
boot_config_flags db     1
        public  boot_runtime_flags
boot_runtime_flags db   80h
        public  bCRTPage
bCRTPage        db      ?               ; value saved from BIOS data area
wCRTStart       dw      ?               ; value saved from BIOS data area
bQueryOpt       db      0               ; 0=off, 1=prompt all, 2=prompt none, 4=skip all
        public  query_mode_flags
query_mode_flags db     0
query_display_flags db  0
bDefBlock       db      1               ; default block #
bMaxBlock       db      ?               ; maxmimum block #
offDefBlock     dw      0               ; offset of name of default block (if any)
secTimeOut      db      -1              ; # of seconds for timeout (-1 == indefinite)
secElapsed      db      0               ; # of seconds elapsed so far (KEEP AFTER secTimeOut)
abBlockType     db  MAX_MULTI_CONFIG+1 dup(?)   ; array of block types
aoffBlockName   dw  MAX_MULTI_CONFIG+1 dup(?)   ; array of offsets of block names
aoffBlockDesc   dw  MAX_MULTI_CONFIG+1 dup(?)   ; array of offsets of block descriptions

        public  query_result
query_result    db      0
szBoot          db      "CONFIG=",0
szMenu          db      "MENU",0
szCommon        db      "COMMON",0


endif  ;MULTI_CONFIG

comtab	label	byte

;            cmd len    command         cmd code
;            -------    -------         --------
;
ifdef MULTI_CONFIG
        db      1,      "[",            CONFIG_BEGIN
endif
        db      7,      "ACCDATE",      CONFIG_ACCDATE
        db      5,      "BREAK",        CONFIG_BREAK
        db      7,      "BUFFERS",      CONFIG_BUFFERS
        db      11,     "BUFFERSHIGH",  CONFIG_BUFFERSHIGH
        db      7,      "COMMENT",      CONFIG_COMMENT
        db      7,      "COUNTRY",      CONFIG_COUNTRY
        db      6,      "DEVICE",       CONFIG_DEVICE
        db      10,     "DEVICEHIGH",   CONFIG_DEVICEHIGH
        db      3,      "DOS",          CONFIG_DOS
        db      8,      "DRIVPARM",     CONFIG_DRIVPARM
        db      4,      "FCBS",         CONFIG_FCBS
        db      8,      "FCBSHIGH",     CONFIG_FCBSHIGH
        db      5,      "FILES",        CONFIG_FILES
        db      9,      "FILESHIGH",    CONFIG_FILESHIGH
ifdef MULTI_CONFIG
        db      7,      "INCLUDE",      CONFIG_INCLUDE
endif
        db      7,      "INSTALL",      CONFIG_INSTALL
        db      11,     "INSTALLHIGH",  CONFIG_INSTALLHIGH
        db      9,      "LASTDRIVE",    CONFIG_LASTDRIVE
        db      13,     "LASTDRIVEHIGH", CONFIG_LASTDRIVEHIGH
        db      4,      "LOGO",         CONFIG_LOGO
ifdef MULTI_CONFIG
        db      7,      "SUBMENU",      CONFIG_SUBMENU
        db      9,      "MENUCOLOR",    CONFIG_MENUCOLOR
        db      11,     "MENUDEFAULT",  CONFIG_MENUDEFAULT
        db      8,      "MENUITEM",     CONFIG_MENUITEM
endif
        db      10,     "MULTITRACK",   CONFIG_MULTITRACK
ifdef MULTI_CONFIG
        db      7,      "NUMLOCK",      CONFIG_NUMLOCK
endif
        db      3,      "REM",          CONFIG_REM
ifdef MULTI_CONFIG
        db      3,      "SET",          CONFIG_SET
endif
        db      5,      "SHELL",        CONFIG_SHELL
if    STACKSW
        db      6,      "STACKS",       CONFIG_STACKS
        db      10,     "STACKSHIGH",   CONFIG_STACKSHIGH
endif
        db      8,      "SWITCHES",     CONFIG_SWITCHES
	db	0

ENDIF  ;CONFIGPROC

extrn deviceparameters:byte

IFDEF	CONFIGPROC

        public  hlim,slim,switchlist,bpbtable
hlim	    dw	    2
slim	    dw	    9

public drive
drive	db	?

public switches
switches    dw	0


; the following are the recommended bpbs for the media that we know of so
; far.

; 48 tpi diskettes

bpb48t	dw	512
	db	2
	dw	1
	db	2
	dw	112
	dw	2*9*40
	db	0fdh
	dw	2
	dw	9
	dw	2
	dd	0
        dd      0

; 96tpi diskettes

bpb96t	dw	512
	db	1
	dw	1
	db	2
	dw	224
	dw	2*15*80
	db	0f9h
	dw	7
	dw	15
	dw	2
	dd	0
        dd      0

; 3 1/2 inch diskette bpb

bpb35	dw	512
	db	2
	dw	1
	db	2
	dw	70h
	dw	2*9*80
	db	0f9h
	dw	3
	dw	9
	dw	2
	dd	0
        dd      0
      
bpb35h	dw	0200h
	db	01h
	dw	0001h
	db	02h
	dw	0e0h
	dw	0b40h
	db	0f0h
	dw	0009h
	dw	0012h
	dw	0002h
	dd	0
        dd      0

;
; m037 - BEGIN
;
bpb288	dw	0200h
	db	02h
	dw	0001h
	db	02h
	dw	240
	dw	2*36*80
	db	0f0h
	dw	0009h
	dw	36
	dw	0002h
	dd	0
        dd      0
;
; m037 - END
;
bpbtable    dw	    bpb48t		; 48tpi drives
	    dw	    bpb96t		; 96tpi drives
	    dw	    bpb35		; 3.5" drives
; the following are not supported, so default to 3.5" media layout
	    dw	    bpb35		; not used - 8" drives
	    dw	    bpb35		; not used - 8" drives
	    dw	    bpb35		; not used - hard files
	    dw	    bpb35		; not used - tape drives
	    dw	    bpb35h		; 3-1/2" 1.44mb drive
	    dw	    bpb35		; ERIMO				m037
	    dw	    bpb288		; 2.88 MB diskette drives	m037

switchlist  db	8,"FHSTDICN"	     ; preserve the positions of n and c.
ENDIF
sysinitseg ends
end
