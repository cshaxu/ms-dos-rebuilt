;** CFGSEG.ASM - Configuration program segment order.
;
;	Static C runtime storage precedes exit tables and communal storage.
;
_BSS	segment	word public 'BSS'
_BSS	ends
XOB	segment	word public 'BSS'
XOB	ends
XO	segment	word public 'BSS'
XO	ends
XOE	segment	word public 'BSS'
XOE	ends
XOFB	segment	word public 'BSS'
XOFB	ends
XOF	segment	word public 'BSS'
XOF	ends
XOFE	segment	word public 'BSS'
XOFE	ends
c_common	segment	para public 'BSS'
c_common	ends

;	Configuration, hardware detection and registry code segments.
CFGMAIN	segment	word public 'CODE'
CFGMAIN	ends
CFGPUB	segment	word public 'CODE'
CFGPUB	ends
CFGIOCTL	segment	word public 'CODE'
CFGIOCTL	ends
CFGPNP	segment	word public 'CODE'
CFGPNP	ends
CFGMSGS	segment	word public 'CODE'
CFGMSGS	ends
CFGMSGT	segment	word public 'CODE'
CFGMSGT	ends
CFGMSG	segment	word public 'CODE'
CFGMSG	ends
PNPCPQ	segment	word public 'CODE'
PNPCPQ	ends
PNPTOSH	segment	word public 'CODE'
PNPTOSH	ends
PNPLF	segment	word public 'CODE'
PNPLF	ends
PNPTI	segment	word public 'CODE'
PNPTI	ends
PNPIBM	segment	word public 'CODE'
PNPIBM	ends
CONFIGPATH	segment	para public 'CODE'
CONFIGPATH	ends
REGAPI	segment	word public 'CODE'
REGAPI	ends
REGIO	segment	para public 'CODE'
REGIO	ends
REGWRAP	segment	word public 'CODE'
REGWRAP	ends
REGSTART	segment	word public 'CODE'
REGSTART	ends
REGKEYS	segment	word public 'CODE'
REGKEYS	ends
REGSTR	segment	word public 'CODE'
REGSTR	ends
REGFILE	segment	word public 'CODE'
REGFILE	ends
REGHANDLE	segment	word public 'CODE'
REGHANDLE	ends
REGFINAL	segment	word public 'CODE'
REGFINAL	ends

	end
