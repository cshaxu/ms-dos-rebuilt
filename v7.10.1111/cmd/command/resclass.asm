; Resident message resource.

RESOURCE_ONLY equ 1
	include resmsg.equ

DATARES	segment public byte 'DATA'
	public Abort_Char,Retry_Char,Ignore_Char,Fail_Char,Yes_Char,No_Char
	public ResMsgClass
	include comrmsg.inc
DATARES	ends

	end
