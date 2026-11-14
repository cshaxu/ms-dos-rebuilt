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
       tfor.obj dir.obj cratio.obj tcmd1b.obj tcmd2a.obj tcmd2b.obj \
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

command1.obj:  command1.asm             \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       comsw.asm                \
               $(inc)\version.inc       \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       comseg.asm               \
               resmsg.equ

command2.obj:  command2.asm             \
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
               $(inc)\version.inc       \
	       $(inc)\curdir.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       resmsg.equ

copy.obj:      copy.asm                 \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

copypr1.obj:   copypr1.asm              \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

copypr2.obj:   copypr2.asm              \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

cparse.obj:    cparse.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

init.obj:      init.asm                 \
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
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ               \
               $(inc)\msbdata.inc       \
	       envdata.asm \
	       $(inc)\oemconf.inc         \
	       $(inc)\xmm.inc             

iparse.obj:    iparse.asm               \
	       comseg.asm

parse2.obj:    parse2.asm               \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\devsym.inc        \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm \
	       $(inc)\intnat.inc          

path1.obj:     path1.asm                \
	       $(inc)\dossym.inc        \
	       $(inc)\dbcs.sw           \
	       $(inc)\dosmac.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\buffer.inc        \
	       $(inc)\dirent.inc        \
	       $(inc)\error.inc         \
	       $(inc)\syscall.inc       \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm

path2.obj:     path2.asm                \
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
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm \
	       fordata.asm                

rdata.obj:     rdata.asm                \
               comequ.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       resmsg.equ               \
	       $(MSG_DIR)\comrmsg.inc	\
	       $(inc)\highvar.inc \
	       $(inc)\buffer.inc          \
	       $(inc)\curdir.inc          \
	       $(inc)\dbcs.sw             \
	       $(inc)\dirent.inc          \
	       $(inc)\dosmac.inc          \
	       $(inc)\dossym.inc          \
	       $(inc)\error.inc           \
	       $(inc)\pdb.inc             \
	       $(inc)\syscall.inc         \
	       $(inc)\versiona.inc        

stub.obj:      stub.asm                 \
	       comseg.asm       	\
	       $(inc)\highexit.inc	\
	       $(inc)\highvar.inc \
	       $(inc)\arena.inc           \
	       $(inc)\versiona.inc        \
	       $(inc)\xmm.inc             

rucode.obj:    rucode.asm               \
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
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       resmsg.equ \
	       $(inc)\arena.inc           

tbatch.obj:    tbatch.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

tbatch2.obj:   tbatch2.asm              \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

dir.obj:       dir.asm                  \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       $(inc)\rombios.inc       \
	       comseg.asm               \
	       $(inc)\curdir.inc        \
	       comequ.asm               \
	       $(inc)\doscntry.inc        

cratio.obj:    cratio.asm		\
	       comseg.asm		\
	       comequ.asm		\
	       $(inc)\dossym.inc	 \
	       $(inc)\syscall.inc	\
	       $(inc)\magicdrv.inc \
	       $(inc)\buffer.inc          \
	       $(inc)\curdir.inc          \
	       $(inc)\dbcs.sw             \
	       $(inc)\dirent.inc          \
	       $(inc)\dosmac.inc          \
	       $(inc)\error.inc           \
	       $(inc)\version.inc         \
	       $(inc)\versiona.inc        

tcmd1b.obj:    tcmd1b.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

tcmd2a.obj:    tcmd2a.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
	       $(inc)\dossym.inc        \
	       $(inc)\bpb.inc \
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
	       comseg.asm                 \
	       comequ.asm                 

tcmd2b.obj:   tcmd2b.asm                 \
	       comsw.asm                  \
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
	       comequ.asm \
	       $(inc)\version.inc         

tcode.obj:     tcode.asm                \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       $(inc)\mshalo.asm

tdata.obj:     tdata.asm                \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\dirent.inc        \
	       $(inc)\curdir.inc        \
	       $(inc)\error.inc         \
	       ifequ.asm                \
	       comequ.asm               \
	       $(inc)\sysmsg.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\msgserv.asm       \
	       tranmsg.asm              \
	       $(inc)\copyrigh.inc        

tenv.obj:      tenv.asm                 \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       $(inc)\doscntry.inc \
	       resmsg.equ                 

tenv2.obj:     tenv2.asm                \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

tfor.obj:      tfor.asm                 \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       fordata.asm

tmisc1.obj:    tmisc1.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

tmisc2.obj:    tmisc2.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm \
	       $(inc)\bpb.inc             

tparse.obj:    tparse.asm               \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       $(inc)\parse.asm         \
	       $(inc)\psdata.inc

tpipe.obj:     tpipe.asm                \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       comequ.asm

tprintf.obj:   tprintf.asm              \
	       comsw.asm                \
               $(inc)\version.inc       \
	       $(inc)\dosmac.inc        \
	       comseg.asm               \
	       comequ.asm               \
	       $(inc)\curdir.inc        \
	       $(inc)\sysmsg.inc        \
	       $(inc)\versiona.inc      \
	       $(inc)\msgdcl.inc        \
	       $(inc)\msgserv.asm \
	       $(inc)\buffer.inc          \
	       $(inc)\copyrigh.inc        \
	       $(inc)\dbcs.sw             \
	       $(inc)\dirent.inc          \
	       $(inc)\dossym.inc          \
	       $(inc)\error.inc           

tspc.obj:      tspc.asm                 \
	       comsw.asm                \
               $(inc)\version.inc       \
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
	       $(inc)\magicdrv.inc

tucode.obj:    tucode.asm               \
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
               $(inc)\version.inc       \
	       comseg.asm               \
	       comequ.asm

uinit.obj:     uinit.asm                \
	       comsw.asm                \
               $(inc)\version.inc       \
	       comseg.asm               \
	       ifequ.asm                \
	       $(MSG_DIR)\comimsg.inc \
	       resmsg.equ                 \
	       $(inc)\buffer.inc          \
	       $(inc)\copyrigh.inc        \
	       $(inc)\dbcs.sw             \
	       $(inc)\dirent.inc          \
	       $(inc)\dosmac.inc          \
	       $(inc)\dossym.inc          \
	       $(inc)\error.inc           \
	       $(inc)\pdb.inc             \
	       $(inc)\syscall.inc         \
	       $(inc)\versiona.inc        

loadhi.obj:     loadhi.asm              \
		comseg.asm              \
		comequ.asm              \
		$(inc)\dossym.inc       \
		$(inc)\syscall.inc      \
		$(inc)\arena.inc	\
		$(inc)\highload.inc	\
		$(inc)\highvar.inc \
	       $(inc)\buffer.inc          \
	       $(inc)\curdir.inc          \
	       $(inc)\dbcs.sw             \
	       $(inc)\dirent.inc          \
	       $(inc)\dosmac.inc          \
	       $(inc)\error.inc           \
	       $(inc)\version.inc         \
	       $(inc)\versiona.inc        

iniclass.obj: iniclass.asm               \
	       $(MSG_DIR)\comimsg.inc     \
	       resmsg.equ                 

resclass.obj: resclass.asm               \
	       $(MSG_DIR)\comrmsg.inc     \
	       resmsg.equ                 

iniclass.exe: iniclass.obj
	link /map iniclass.obj,iniclass.exe,iniclass.map,,;

resclass.exe: resclass.obj
	link /map resclass.obj,resclass.exe,resclass.map,,;

res0.exe: res0.obj
	link res0.obj,res0.exe,,,;
