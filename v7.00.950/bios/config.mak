#************************ makefile for configuration ************************
#
# Assemble the configuration, registry and C runtime source modules.
# config.lnk supplies their final link order and extracted CRT inputs.
#

ASM     = masm
AFLAGS  = /Mx /t /W1

all: cfgseg.obj \
                cfgmain.obj \
                cfginit.obj \
                cfgpub.obj \
                cfgioctl.obj \
                pnpcheck.obj \
                pnpfind.obj \
                pnpcaps.obj \
                cfgzero.obj \
                cfgmatch.obj \
                cfgline.obj \
                cfgmenu.obj \
                regroot.obj \
                cfgmsg.obj \
                pnpcpq.obj \
                pnptosh.obj \
                pnplf.obj \
                pnpti.obj \
                pnpibm.obj \
                cpath.obj \
                rapiopen.obj \
                configio.obj \
                cfgmem.obj \
                regvm.obj \
                regvmcal.obj \
                rqvalue.obj \
                regstart.obj \
                regopen.obj \
                regstr.obj \
                regread.obj \
                regfind.obj \
                reginit.obj \
                cfgdata.obj \
                crtprint.obj \
                regpdiff.obj \
                crtcmp.obj \
                crtread.obj \
                crtflush.obj \
                crtpaths.obj \
                crtcomit.obj \
                crtclose.obj \
                crtend.obj \
                cfgtail.obj \
                crtsprnt.obj

.asm.obj:
	$(ASM) $(AFLAGS) $*.asm,$*.obj,$*.lst;

crtprint.obj: crtprint.asm
	$(ASM) $(AFLAGS) /DPRINTF_ONLY crtprint.asm,crtprint.obj,crtprint.lst;

crtsprnt.obj: crtprint.asm
	$(ASM) $(AFLAGS) /DSPRINTF_ONLY crtprint.asm,crtsprnt.obj,crtsprnt.lst;

cfginit.obj: cfginit.asm
	$(ASM) $(AFLAGS) /DCFGINIT_HEAD cfginit.asm,cfginit.obj,cfginit.lst;

cfgtail.obj: cfginit.asm
	$(ASM) $(AFLAGS) /DCFGINIT_TAIL cfginit.asm,cfgtail.obj,cfgtail.lst;
