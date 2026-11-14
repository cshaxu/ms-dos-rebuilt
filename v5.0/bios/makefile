#************************** makefile for bios ***************************

dest    =io.sys
inc     =inc
msg     =..\messages
COUNTRY =DOS
awarn   =-W1
link_opts = /MAP
common  =..\inc
extasw  =-I$(inc) -I$(common) -DOEMBASE

#
####################### dependencies begin here. #########################
#

all: $(dest)

msbio.cl1 msbio.cl2 msbio.cl3 \
msbio.cl4 msbio.cl5 msbio.cl6 \
msbio.cl7 msbio.cl8 msbio.cl9 : msbio.skl \
	$(msg)\$(COUNTRY).msg
        nosrvbld msbio.skl $(msg)\$(COUNTRY).msg

msbio1.obj msbio1.lst: msbio1.asm \
                $(inc)\msbdata.inc \
                $(inc)\bootform.inc \
                $(common)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\msbds.inc \
                msequ.inc \
                $(inc)\version.inc

mschar.obj mschar.lst: mschar.asm \
                $(common)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\ioctl.inc \
                $(inc)\version.inc \
                msequ.inc \
                msgroup.inc

msdisk.obj msdisk.lst: msdisk.asm \
                $(common)\VERSIONA.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\bootform.inc \
                $(inc)\version.inc \
                $(common)\bpb.inc \
                $(inc)\msbds.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc

msdioctl.obj msdioctl.lst: msdioctl.asm \
                $(inc)\bootform.inc \
                $(common)\bpb.inc \
                $(inc)\devsym.inc \
                $(inc)\ioctl.inc \
                $(inc)\version.inc \
                $(inc)\msbds.inc \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc

msint13.obj msint13.lst: msint13.asm \
                biostruc.inc \
                $(common)\bpb.inc \
                $(inc)\version.inc \
                $(inc)\msbds.inc \
                msequ.inc \
                msgroup.inc

msbio2.obj msbio2.lst: msbio2.asm \
                $(inc)\bootform.inc \
                $(common)\bpb.inc \
                $(inc)\msbds.inc \
                $(inc)\version.inc \
                msbio.cl2 \
                msequ.inc \
                msgroup.inc

msinit.obj msinit.lst: msinit.asm \
                $(common)\VERSIONA.inc \
                $(inc)\buffer.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\version.inc \
                biostruc.inc \
                $(inc)\bootform.inc \
                $(common)\bpb.inc \
                $(inc)\msbds.inc \
                msbio.cl8 \
                msdskpr.inc \
                msequ.inc \
                msgroup.inc

sysinit1.obj sysinit1.lst: sysinit1.asm \
                $(common)\VERSIONA.inc \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(common)\cputype.inc \
                $(common)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(common)\dpb.inc \
                $(inc)\error.inc \
                $(inc)\exe.inc \
                $(inc)\pdb.inc \
                $(common)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc \
                biostruc.inc \
                $(common)\bpb.inc \
                devmark.inc \
                $(inc)\devsym.inc \
                $(inc)\ioctl.inc \
                msbio.cl4 \
                msbio.cl5 \
                msbio.cl6 \
                msbio.cl7

sysconf.obj sysconf.lst: sysconf.asm \
                $(inc)\doscntry.inc \
                $(common)\dpb.inc \
                $(inc)\parse.asm \
                $(inc)\psdata.inc \
                $(inc)\syscall.inc \
                $(inc)\sysvar.inc \
                $(inc)\version.inc \
                devmark.inc \
                $(inc)\devsym.inc

sysinit2.obj sysinit2.lst: sysinit2.asm \
                $(common)\copyrigh.inc \
                $(inc)\doscntry.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(common)\bpb.inc \
                devmark.inc \
                $(inc)\devsym.inc \
                $(inc)\ioctl.inc

sysimes.obj sysimes.lst: sysimes.asm \
                $(inc)\version.inc \
                msbio.cl3

power.obj power.lst: power.asm \
                power.inc \
                msequ.inc \
                msgroup.inc \
                biosseg.inc \
                $(inc)\version.inc \
                $(inc)\devsym.inc \
                $(common)\bpb.inc \
                $(inc)\ioctl.inc \
                $(inc)\error.inc \
                apmequ.inc \
                msbio.cl9

ptime.obj ptime.lst: ptime.asm \
                power.inc \
                msequ.inc \
                msgroup.inc \
                biosseg.inc \
                $(inc)\version.inc \
                $(inc)\devsym.inc \
                $(common)\bpb.inc \
                $(inc)\ioctl.inc \
                $(inc)\error.inc \
                apmequ.inc

msend.obj msend.lst: msend.asm \
                $(inc)\version.inc

msload.obj: msload.asm \
                makefile \
                msbio.cl1 \
                $(common)\bpb.inc \
                $(inc)\bootform.inc \
                $(common)\versiona.inc \
                $(inc)\version.inc \
                $(inc)\dossym.inc \
                $(inc)\dosmac.inc \
                $(inc)\mult.inc

msload.com: msload.obj
        link $(link_opts) msload.obj,msload,msload,;
        reloc msload.exe msload.com

msbio.bin: msbio1.obj \
                mschar.obj \
                msdisk.obj \
                msdioctl.obj \
                msint13.obj \
                msbio2.obj \
                msinit.obj \
                sysinit1.obj \
                sysconf.obj \
                sysinit2.obj \
                sysimes.obj \
                power.obj \
                ptime.obj \
                msend.obj msbio.lnk
        link $(link_opts) @msbio.lnk
        reloc msbio.exe msbio.bin 70

$(dest): msload.com msbio.bin
        copy /b msload.com+msbio.bin $(dest)
