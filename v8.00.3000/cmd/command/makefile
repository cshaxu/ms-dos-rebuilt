#************************** makefile for cmd\command *********************
#
# COMMAND and its message resources.
#

inc     =..\..\inc
MSG_DIR=..\..\lang\usa\messages

ASM     = masm
AFLAGS  = /Mx /t /W1 /DUSA /DDBLSPACE_HOOKS /I. /I$(inc) /I$(MSG_DIR)

OBJS    = command1.obj command2.obj rucode.obj stub.obj rdata.obj \
       init.obj iparse.obj uinit.obj tcode.obj tbatch.obj tbatch2.obj \
       tfor.obj dir.obj tcmd1b.obj tcmd2a.obj tcmd2b.obj \
       tenv.obj tenv2.obj tmisc1.obj tmisc2.obj tpipe.obj parse2.obj \
       path1.obj path2.obj tucode.obj copy.obj copypr1.obj copypr2.obj \
       cparse.obj tparse.obj loadhi.obj tprintf.obj tdata.obj tspc.obj

all: command.exe iniclass.exe resclass.exe

.asm.obj:
	$(ASM) $(AFLAGS) $*.asm,$*.obj,$*.lst;

buildmsg.exe: buildmsg.c
	cl /AS /O /W2 buildmsg.c /link /stack:16384

command.exe: $(OBJS) command.lnk
	link @command.lnk
	copy command.exc command.exe

$(OBJS): command.cl1 command.cl2 command.clf command.ctl

####################### dependencies begin here. #########################

command1.obj: command1.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                resmsg.equ \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

command2.obj: command2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                resmsg.equ \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

rucode.obj: rucode.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                resmsg.equ \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\filemode.inc \
                $(inc)\mult.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

stub.obj: stub.asm \
                comseg.asm \
                $(inc)\arena.inc \
                $(inc)\highexit.inc \
                $(inc)\highvar.inc \
                $(inc)\versiona.inc \
                $(inc)\xmm.inc

rdata.obj: rdata.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                resmsg.equ \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\highvar.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                $(MSG_DIR)\comrmsg.inc

init.obj: init.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                envdata.asm \
                resmsg.equ \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\msbdata.inc \
                $(inc)\mult.inc \
                $(inc)\oemconf.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                $(inc)\xmm.inc

iparse.obj: iparse.asm \
                comseg.asm

uinit.obj: uinit.asm \
                comseg.asm \
                comsw.asm \
                ifequ.asm \
                resmsg.equ \
                $(inc)\buffer.inc \
                $(inc)\copyrigh.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\pdb.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc \
                $(MSG_DIR)\comimsg.inc

tcode.obj: tcode.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\mshalo.asm \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\vector.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tbatch.obj: tbatch.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tbatch2.obj: tbatch2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tfor.obj: tfor.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                fordata.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\find.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

dir.obj: dir.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\filemode.inc \
                $(inc)\find.inc \
                $(inc)\ioctl.inc \
                $(inc)\rombios.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

cratio.obj: cratio.asm \
                comequ.asm \
                comseg.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\magicdrv.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tcmd1b.obj: tcmd1b.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\filemode.inc \
                $(inc)\ioctl.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tcmd2a.obj: tcmd2a.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\filemode.inc \
                $(inc)\ioctl.inc \
                $(inc)\rombios.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tcmd2b.obj: tcmd2b.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\mult.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tenv.obj: tenv.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                resmsg.equ \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\doscntry.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tenv2.obj: tenv2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\find.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tmisc1.obj: tmisc1.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tmisc2.obj: tmisc2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\bpb.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\ioctl.inc \
                $(inc)\pdb.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tpipe.obj: tpipe.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\pdb.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

parse2.obj: parse2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\intnat.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

path1.obj: path1.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

path2.obj: path2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                fordata.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\find.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tucode.obj: tucode.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

copy.obj: copy.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

copypr1.obj: copypr1.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

copypr2.obj: copypr2.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\sf.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

cparse.obj: cparse.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\devsym.inc \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tparse.obj: tparse.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\parse.asm \
                $(inc)\psdata.inc \
                $(inc)\version.inc

loadhi.obj: loadhi.asm \
                comequ.asm \
                comseg.asm \
                $(inc)\arena.inc \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\highload.inc \
                $(inc)\highvar.inc \
                $(inc)\syscall.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tprintf.obj: tprintf.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\copyrigh.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\msgdcl.inc \
                $(inc)\msgserv.asm \
                $(inc)\sysmsg.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tdata.obj: tdata.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                ifequ.asm \
                tranmsg.asm \
                $(inc)\copyrigh.inc \
                $(inc)\curdir.inc \
                $(inc)\dirent.inc \
                $(inc)\error.inc \
                $(inc)\msgserv.asm \
                $(inc)\sysmsg.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

tspc.obj: tspc.asm \
                comequ.asm \
                comseg.asm \
                comsw.asm \
                $(inc)\buffer.inc \
                $(inc)\curdir.inc \
                $(inc)\dbcs.sw \
                $(inc)\dirent.inc \
                $(inc)\dosmac.inc \
                $(inc)\dossym.inc \
                $(inc)\error.inc \
                $(inc)\find.inc \
                $(inc)\intnat.inc \
                $(inc)\magicdrv.inc \
                $(inc)\version.inc \
                $(inc)\versiona.inc

iniclass.obj: iniclass.asm $(MSG_DIR)\comimsg.inc resmsg.equ
resclass.obj: resclass.asm $(MSG_DIR)\comrmsg.inc resmsg.equ

iniclass.exe: iniclass.obj
	link /map iniclass.obj,iniclass.exe,iniclass.map,,;

resclass.exe: resclass.obj
	link /map resclass.obj,resclass.exe,resclass.map,,;

res0.exe: res0.obj
	link res0.obj,res0.exe,,,;
