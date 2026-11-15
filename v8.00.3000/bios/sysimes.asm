;/*
; *                      Microsoft Confidential
; *                      Copyright (C) Microsoft Corporation 1981-1991
; *                      All Rights Reserved.
; */
	page	,160

MULTI_CONFIG equ 1

	include	version.inc	; set build flags
	include biosseg.inc	; establish bios segment structure

SysInitSeg segment

; Indexed SYSINIT message resource header, offsets and text.
;
sysinit_resource label byte
	dw	(sysinit_msg_base - sysinit_msg_table)/2 - 1
	dw	offset sysinit_msg_base
	dw	100h
	dw	sysinit_msg_end - sysinit_msg_base
	include ..\lang\usa\messages\sysimsg.inc

SysInitSeg	ends
	end
