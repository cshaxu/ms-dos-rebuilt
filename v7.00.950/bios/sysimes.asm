;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160

MULTI_CONFIG equ 1

	include	version.inc	; set build flags
	include biosseg.inc	; establish bios segment structure

sysinitseg segment

; Indexed SYSINIT message resource header, offsets and text.
;
sysinit_resource label byte
	dw	(sysinit_msg_base - sysinit_msg_table)/2 - 1
	dw	sysinit_msg_base - sysinit_resource
	dw	100h
	dw	sysinit_msg_end - sysinit_resource
	include ..\lang\usa\messages\sysimsg.inc

sysinitseg	ends
	end
