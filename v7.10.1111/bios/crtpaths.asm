;** CRTPATHS.ASM - Runtime temporary-file path components
_DATA segment word public 'DATA'
        public CRTTempPrefix,CRTPathSep
CRTTempPrefix db '\',0
CRTPathSep db '\',0
_DATA ends
DGROUP group _DATA
        end
