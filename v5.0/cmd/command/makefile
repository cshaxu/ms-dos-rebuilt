#************************** makefile for cmd\command *********************

dest    =command.com
inc     =..\..\inc
msg     =..\..\messages
COUNTRY =usa-ms
awarn   =-W1
extasw  =-I$(inc) -I$(msg)

#
####################### dependencies begin here. #########################
#

all: $(dest)

command.ctl:	command.skl		 \
		$(msg)\$(COUNTRY).msg	 \
		makefile
        buildmsg $(msg)\$(COUNTRY) command.skl

command1.obj: command1.asm             \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       comsw.asm                \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ               \
	       envdata.asm              \
	       comseg.asm               \
	       $(inc)\version.inc

command2.obj: command2.asm             \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\pdb.inc           \
	       $(inc)\syscall.inc       \
	       comsw.asm                \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ               \
	       comseg.asm               \
	       $(inc)\version.inc

rucode.obj:   rucode.asm               \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\filemode.inc      \
	       $(inc)\pdb.inc           \
	       $(inc)\mult.inc          \
	       $(inc)\doscntry.inc      \
	       $(inc)\devsym.inc        \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ               \
	       $(inc)\arena.inc         \
	       $(inc)\version.inc

stub.obj:     stub.asm                 \
	       comseg.asm               \
	       $(inc)\xmm.inc

rdata.obj:    rdata.asm                \
	       comsw.asm                \
	       comseg.asm               \
	       resmsg.equ               \
	       $(msg)\comrmsg.inc       \
	       $(inc)\dossym.inc        \
	       $(inc)\pdb.inc           \
	       $(inc)\syscall.inc       \
	       comequ.asm               \
	       $(inc)\version.inc

init.obj:     init.asm                 \
	       $(inc)\dossym.inc        \
	       $(inc)\pdb.inc           \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\mult.inc          \
	       $(inc)\syscall.inc       \
	       $(inc)\doscntry.inc      \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ               \
	       envdata.asm              \
	       $(inc)\xmm.inc           \
	       $(inc)\version.inc

iparse.obj:   iparse.asm               \
	       comseg.asm               \
	       $(inc)\parse.asm         \
	       $(inc)\psdata.inc

uinit.obj:    uinit.asm                \
	       comsw.asm                \
	       comseg.asm               \
	       ifequ.asm                \
	       $(msg)\comimsg.inc       \
	       resmsg.equ               \
	       $(inc)\version.inc

tcode.obj:    tcode.asm                \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\vector.inc        \
	       $(inc)\pdb.inc           \
	       $(inc)\arena.inc         \
	       $(inc)\mshalo.asm        \
	       $(inc)\version.inc

tbatch.obj:   tbatch.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\doscntry.inc      \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

tbatch2.obj:  tbatch2.asm              \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

tfor.obj:     tfor.asm                 \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\find.inc          \
	       $(inc)\devsym.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       fordata.asm              \
	       $(inc)\version.inc

dir.obj:      dir.asm                  \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\bpb.inc           \
	       $(inc)\filemode.inc      \
	       $(inc)\find.inc          \
	       $(inc)\ioctl.inc         \
	       $(inc)\devsym.inc        \
	       $(inc)\rombios.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       ifequ.asm                \
	       $(inc)\doscntry.inc      \
	       $(inc)\version.inc

tcmd1b.obj:   tcmd1b.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\bpb.inc           \
	       $(inc)\syscall.inc       \
	       $(inc)\filemode.inc      \
	       $(inc)\sf.inc            \
	       $(inc)\ioctl.inc         \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

tcmd2a.obj:   tcmd2a.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\bpb.inc           \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\filemode.inc      \
	       $(inc)\sf.inc            \
	       $(inc)\ioctl.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\rombios.inc       \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

tcmd2b.obj:   tcmd2b.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\pdb.inc           \
	       $(inc)\mult.inc          \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

tenv.obj:     tenv.asm                 \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\arena.inc         \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\doscntry.inc      \
	       resmsg.equ               \
	       $(inc)\version.inc

tenv2.obj:    tenv2.asm                \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\find.inc          \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

tmisc1.obj:   tmisc1.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

tmisc2.obj:   tmisc2.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\pdb.inc           \
	       $(inc)\sf.inc            \
	       $(inc)\ioctl.inc         \
	       $(inc)\curdir.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\bpb.inc           \
	       $(inc)\version.inc

tpipe.obj:    tpipe.asm                \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\pdb.inc           \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

parse2.obj:   parse2.asm               \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\devsym.inc        \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

path1.obj:    path1.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

path2.obj:    path2.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\find.inc          \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

tucode.obj:   tucode.asm               \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       comsw.asm                \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\version.inc

copy.obj:     copy.asm                 \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\sf.inc            \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

copypr1.obj:  copypr1.asm              \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\sf.inc            \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

copypr2.obj:  copypr2.asm              \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       $(inc)\sf.inc            \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

cparse.obj:   cparse.asm               \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\devsym.inc        \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\version.inc

tparse.obj:   tparse.asm               \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\parse.asm         \
	       $(inc)\psdata.inc        \
	       $(inc)\version.inc

tprintf.obj:  tprintf.asm              \
	       comsw.asm                \
	       $(inc)\dosmac.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\curdir.inc        \
	       $(inc)\sysmsg.inc        \
	       $(inc)\versiona.inc      \
	       command.ctl              \
	       $(inc)\msgdcl.inc        \
	       $(inc)\msgserv.asm       \
	       $(inc)\dossym.inc        \
	       $(inc)\version.inc

loadhi.obj:   loadhi.asm               \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\dossym.inc        \
	       $(inc)\syscall.inc       \
	       $(inc)\arena.inc

tdata.obj:    tdata.asm                \
	       comsw.asm                \
	       comseg.asm               \
	       $(inc)\dirent.inc        \
	       $(inc)\curdir.inc        \
	       $(inc)\error.inc         \
	       ifequ.asm                \
	       comequ.asm               \
	       $(inc)\sysmsg.inc        \
	       $(inc)\versiona.inc      \
	       command.ctl              \
	       $(inc)\msgdcl.inc        \
	       $(inc)\msgserv.asm       \
	       tranmsg.asm              \
	       $(inc)\version.inc

tspc.obj:     tspc.asm                 \
	       comsw.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\find.inc          \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\curdir.inc        \
	       $(inc)\intnat.inc        \
	       comequ.asm               \
	       comseg.asm               \
	       $(inc)\version.inc

command.exc: command1.obj \
                command2.obj \
                rucode.obj \
                stub.obj \
                rdata.obj \
                init.obj \
                iparse.obj \
                uinit.obj \
                tcode.obj \
                tbatch.obj \
                tbatch2.obj \
                tfor.obj \
                dir.obj \
                tcmd1b.obj \
                tcmd2a.obj \
                tcmd2b.obj \
                tenv.obj \
                tenv2.obj \
                tmisc1.obj \
                tmisc2.obj \
                tpipe.obj \
                parse2.obj \
                path1.obj \
                path2.obj \
                tucode.obj \
                copy.obj \
                copypr1.obj \
                copypr2.obj \
                cparse.obj \
                tparse.obj \
                tprintf.obj \
                loadhi.obj \
                tdata.obj \
                tspc.obj command.lnk
        link @command.lnk

$(dest): command.exc
        copy command.exc command.exe
        reloc command command.com
        del command.exe
