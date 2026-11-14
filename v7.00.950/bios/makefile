#************************** makefile for bios ***************************
#
#       MFLAGS supplies additional assembler options.
#
inc     =..\inc
msg     =..\messages
link_opts = /MAP
extasw  =-I. -I$(inc) -DUSA -DDBLSPACE_HOOKS -DDOS7_CONFIG $(MFLAGS)
mlasw   =/c /nologo /Zm /I. /I$(inc) /DUSA /DDBLSPACE_HOOKS /DDOS7_CONFIG $(MFLAGS)

all: msload.exe msbio.bin

.asm.obj:
	masm -Mx -t -W1 $(extasw) $*.asm,$*.obj,$*.lst;

msbio.cl1 msbio.cl2 msbio.cl3 \
msbio.cl4 msbio.cl5 msbio.cl6 \
msbio.cl7 msbio.cl8 msbio.cl9 : msbio.skl \
        $(msg)\USA.MSG
	nosrvbld msbio.skl $(msg)\USA.MSG

stkinit.obj: stkinit.asm \
                biosseg.inc \
                biostruc.inc \
                devmark.inc \
                $(inc)\arena.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\cputype.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\dpb.inc \
                $(inc)\error.inc \
                $(inc)\exe.inc \
                $(inc)\ioctl.inc \
                $(inc)\mult.inc \
                $(inc)\oemconf.inc \
                $(inc)\pdb.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

msbio1.obj: msbio1.asm \
                biosseg.inc \
                msequ.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\msbds.inc \
                $(inc)\oemconf.inc \
                $(inc)\version.inc
	ml $(mlasw) /Flmsbio1.lst msbio1.asm

ststate.obj: ststate.asm \
                $(inc)\exe.inc \
                $(inc)\oemconf.inc

sysinit1.obj: sysinit1.asm \
                biosseg.inc \
                biostruc.inc \
                devmark.inc \
                $(inc)\arena.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\cputype.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\dpb.inc \
                $(inc)\error.inc \
                $(inc)\exe.inc \
                $(inc)\ioctl.inc \
                $(inc)\mult.inc \
                $(inc)\oemconf.inc \
                $(inc)\pdb.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc
	ml $(mlasw) /Flsysinit1.lst sysinit1.asm

si2front.obj: si2front.asm \
                biosseg.inc \
                config.inc \
                devmark.inc \
                $(inc)\bpb.inc \
                $(inc)\copyrigh.inc \
                $(inc)\devsym.inc \
                $(inc)\doscntry.inc \
                $(inc)\exe.inc \
                $(inc)\ioctl.inc \
                $(inc)\rombios.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc

si1tail.obj: si1tail.asm \
                biosseg.inc \
                biostruc.inc \
                devmark.inc \
                $(inc)\arena.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\cputype.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\dpb.inc \
                $(inc)\error.inc \
                $(inc)\exe.inc \
                $(inc)\ioctl.inc \
                $(inc)\mult.inc \
                $(inc)\oemconf.inc \
                $(inc)\pdb.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                msbio.cl7
	ml $(mlasw) /Flsi1tail.lst si1tail.asm

mschar.obj: mschar.asm \
                biosseg.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\error.inc \
                $(inc)\ioctl.inc \
                $(inc)\version.inc

initclk.obj: initclk.asm \
                biosseg.inc \
                biostruc.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\msbds.inc \
                $(inc)\mult.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc
	ml $(mlasw) /Flinitclk.lst initclk.asm

msdisk.obj: msdisk.asm \
                biosseg.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc
	ml $(mlasw) /Flmsdisk.lst msdisk.asm

msdioctl.obj: msdioctl.asm \
                biosseg.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\ioctl.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc
	ml $(mlasw) /Flmsdioctl.lst msdioctl.asm

msint13.obj: msint13.asm \
                biosseg.inc \
                biostruc.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bpb.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc \
                $(inc)\win386.inc
	ml $(mlasw) /Flmsint13.lst msint13.asm

msbio2.obj: msbio2.asm \
                biosseg.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc

msinit.obj: msinit.asm \
                biosseg.inc \
                biostruc.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\msbds.inc \
                $(inc)\mult.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                msbio.cl8
	ml $(mlasw) /Flmsinit.lst msinit.asm

biostail.obj: biostail.asm \
                $(inc)\version.inc
	ml $(mlasw) /Flbiostail.lst biostail.asm

biosmsg.obj: biosmsg.asm \
                ..\lang\usa\messages\biosmsg.inc
	ml $(mlasw) /Flbiosmsg.lst biosmsg.asm

sysinit2.obj: sysinit2.asm \
                biosseg.inc \
                config.inc \
                devmark.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\doscntry.inc \
                $(inc)\exe.inc \
                $(inc)\ioctl.inc \
                $(inc)\rombios.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc
	ml $(mlasw) /Flsysinit2.lst sysinit2.asm

sysconf.obj: sysconf.asm \
                biosseg.inc \
                config.inc \
                devmark.inc \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\dpb.inc \
                $(inc)\error.inc \
                $(inc)\highexit.inc \
                $(inc)\highload.inc \
                $(inc)\highvar.inc \
                $(inc)\magicdrv.inc \
                $(inc)\parse.asm \
                $(inc)\pdb.inc \
                $(inc)\psdata.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\umb.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc
	ml $(mlasw) /Flsysconf.lst sysconf.asm

syspre.obj: syspre.asm \
                biosseg.inc \
                devmark.inc \
                $(inc)\curdir.inc \
                $(inc)\devsym.inc \
                $(inc)\dpb.inc \
                $(inc)\ds_vers.inc \
                $(inc)\magicdrv.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc

logocode.obj: logocode.asm \
                biosseg.inc \
                mrcf.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc

logpart.obj: logpart.asm
	ml $(mlasw) /Fllogpart.lst logpart.asm

pathsrc.obj: pathsrc.asm

mblate.obj: mblate.asm \
                biosseg.inc \
                msequ.inc \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc
	ml $(mlasw) /Flmblate.lst mblate.asm

drivechk.obj: drivechk.asm
	ml $(mlasw) /Fldrivechk.lst drivechk.asm

msend.obj: msend.asm

sysimes.obj: sysimes.asm \
                biosseg.inc \
                $(inc)\version.inc \
                ..\lang\usa\messages\sysimsg.inc

power.obj: power.asm \
                apmequ.inc \
                biosseg.inc \
                devmark.inc \
                msequ.inc \
                msgroup.inc \
                power.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\error.inc \
                $(inc)\ioctl.inc \
                $(inc)\mult.inc \
                $(inc)\syscall.inc \
                $(inc)\umb.inc \
                $(inc)\version.inc \
                $(inc)\win386.inc \
                msbio.cl9

ptime.obj: ptime.asm \
                apmequ.inc \
                biosseg.inc \
                msequ.inc \
                msgroup.inc \
                power.inc \
                $(inc)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\error.inc \
                $(inc)\ioctl.inc \
                $(inc)\mult.inc \
                $(inc)\version.inc

msload.obj: msload.asm \
                $(inc)\bootform.inc \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\mult.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                msbio.cl1
	ml $(mlasw) /Flmsload.lst msload.asm

msbio.bin: stkinit.obj msbio1.obj \
                ststate.obj \
                sysinit1.obj si2front.obj \
                si1tail.obj mschar.obj initclk.obj msdisk.obj \
                msdioctl.obj msint13.obj msbio2.obj msinit.obj biostail.obj \
                biosmsg.obj sysinit2.obj sysconf.obj \
                syspre.obj logocode.obj logpart.obj pathsrc.obj mblate.obj \
                drivechk.obj msend.obj sysimes.obj power.obj ptime.obj msbio.lnk
	link $(link_opts) @msbio.lnk
	reloc msbio.exe msbio.bin 70

msload.exe: msload.obj
	link $(link_opts) msload.obj,msload,msload,;
