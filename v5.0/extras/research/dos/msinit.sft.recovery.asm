	TITLE	MSINIT - Console SFT initialization
	include version.inc
	include dosseg.inc
	include dossym.inc
	include devsym.inc
	include sf.inc
	i_need sftabl,BYTE
DOSCODE SEGMENT
	ASSUME CS:DOSCODE,SS:DOSDATA,ES:DOSDATA,DS:NOTHING
	mov	di,offset dosdata:sftabl + sftable   
	mov	ax,3
	stosw				; refcount
	dec	al
	.errnz	sf_mode-(sf_ref_count+2)
	stosw				; access rd/wr, compatibility
	xor	al,al
	.errnz	sf_attr-(sf_mode+2)
	stosb				; attribute
	mov	al,devid_device_eof or devid_device or iscin or iscout
	.errnz	sf_flags-(sf_attr+1)
	stosw				; flags
	mov	ax,si
	.errnz	sf_devptr-(sf_flags+2)
	stosw				; device pointer in devptr
	mov	ax,ds
	stosw
	xor	ax,ax
	.errnz	sf_firclus-(sf_devptr+4)
	stosw				; firclus
	.errnz	sf_time-(sf_firclus+2)
	stosw				; time
	.errnz	sf_date-(sf_time+2)
	stosw				; date
	dec	ax
	.errnz	sf_size-(sf_date+2)
	stosw				; size
	stosw
	inc	ax
	.errnz	sf_position-(sf_size+4)
	stosw				; position
	stosw
	add	di,sf_name - sf_cluspos ; point at name
	add	si,sdevname		; point to name
	mov	cx,4
	rep	movsw			; name
	mov	cl,3
	mov	al," "
	rep	stosb			; extension
	pop	si			; get back pointer to header
DOSCODE ENDS
END
