Handle	struc
Flags	db	?
cLock	db	?
Base	dd	?
Len	dd	?
Handle	ends

DEFHANDLES	equ	48
FREEFLAG	equ	1
USEDFLAG	equ	2
UNUSEDFLAG	equ	4
ERR_INVALIDHANDLE equ	0a2h
ERR_EMBUNLOCKED	equ	0aah
ERR_EMBLOCKED	equ	0abh
ERR_LOCKOVERFLOW equ	0ach
