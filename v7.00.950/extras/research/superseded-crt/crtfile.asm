;** CRTFILE.ASM - Shared C runtime file and error state
;
; Initial values from the configuration runtime. Startup supplies the
; DOS version before file services execute. Final DGROUP order is linked.
_DATA segment word public 'DATA'
        public _errno,__doserrno,__osminor,__osmajor,__nfile,__osfile
        public __fmode,__umaskval
_errno dw 0
__umaskval dw 0
__osminor db 0
__osmajor db 0
__doserrno dw 0
__nfile dw 20
__osfile db 3 dup (81h),2 dup (1),15 dup (0)
__fmode dw 0
_DATA ends
DGROUP group _DATA
        end
