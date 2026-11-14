BIOS_DATA SEGMENT
BIOS_DATA ENDS
BIOS_CODE SEGMENT BYTE PUBLIC 'Bios_Code'
ASSUME CS:BIOS_CODE,DS:BIOS_DATA,ES:NOTHING
EXTRN errin:BYTE,lsterr:BYTE
numerr EQU 9
        ORG 083Eh
maperror proc	near
	public	maperror
	assume	ds:Bios_Data,es:nothing

	push	cx			; save cx
	push	es			; preserve es
IFDEF DOS7_CONFIG
	push	cs			; set es=Bios_Code
ELSE
	push	ds			; set es=Bios_Data
ENDIF
	pop	es

	mov	al,ah			;put error code in al
IFDEF DOS7_CONFIG
	mov	es:[lsterr],al		;terminate list with error code
ELSE
	mov	[lsterr],al		;terminate list with error code
ENDIF
	mov	cx,numerr		;number of possible error conditions
	mov	di,offset errin 	;point to error conditions
	repne	scasb
IFDEF DOS7_CONFIG
	mov	al,es:[di + numerr - 1] ;get translation
ELSE
	mov	al,[di + numerr - 1] ;get translation
ENDIF

	pop	es			; restore caller's es
	pop	cx			; restore cx
	stc				;flag error condition
	ret
maperror endp
BIOS_CODE ENDS
END
