###     makefile for MS-DOS

dest    =msdos.sys
inc     =..\inc
msg     =..\messages
COUNTRY =DOS
awarn   =-W1
link_opts = /MAP
extasw  =-I$(inc)

#
###################### Dependencies begin here ##########################
#

all: $(dest)

msdos.cl1 msdos.cl2 msdos.cl3 msdos.cl4: msdos.skl $(msg)\$(COUNTRY).msg
        nosrvbld msdos.skl $(msg)\$(COUNTRY).msg

origin.obj origin.lst: origin.asm $(inc)/DOSSEG.INC $(inc)/ORIGIN.INC \
	$(inc)/dossym.inc $(inc)/bdsize.inc $(inc)/version.inc

msdata.obj:   msdata.asm                \
	      mssw.asm                  \
	      $(inc)\ARENA.INC          \
	      $(inc)\CURDIR.INC         \
	      $(inc)\DEVSYM.INC         \
	      $(inc)\DPB.INC            \
	      $(inc)\FIND.INC           \
	      $(inc)\MI.INC             \
	      $(inc)\PDB.INC            \
	      $(inc)\SF.INC             \
	      $(inc)\VECTOR.INC         \
	      $(inc)\VERSIONA.INC       \
	      $(inc)\buffer.INC         \
	      $(inc)\dbcs.sw            \
	      $(inc)\dirent.INC         \
	      $(inc)\doscntry.inc       \
	      $(inc)\dosmac.INC         \
	      $(inc)\dosseg.inc         \
	      $(inc)\dossym.inc         \
	      $(inc)\error.INC          \
	      $(inc)\fastopen.inc       \
	      $(inc)\ms_data.asm        \
	      $(inc)\lmstub.asm         \
	      $(inc)\version.inc        \
	      $(inc)\xmm.inc            \
	      dostab.asm                \
	      $(inc)\const2.asm         \
	      msconst.asm               \
	      $(inc)\mshead.asm         \
	      $(inc)\BUGTYP.INC         \
	      $(inc)\ORIGIN.INC         \
	      $(inc)\bdsize.inc         \
	      $(inc)\wpatch.inc         \
	      $(inc)\msbdata.inc        \
	      msdos.cl2

mstable.obj mstable.lst: mstable.asm mssw.asm \
	$(inc)\VERSIONA.INC $(inc)\buffer.INC \
	$(inc)\copyrigh.inc $(inc)\dbcs.sw $(inc)\dirent.INC \
	$(inc)\dosmac.INC $(inc)\dosseg.inc $(inc)\dossym.inc \
	$(inc)\error.INC $(inc)\fastopen.inc $(inc)\syscall.inc \
	$(inc)\version.inc

msdisp.obj msdisp.lst: msdisp.asm $(inc)/DOSSYM.INC $(inc)/VERSIONA.INC \
	$(inc)/buffer.INC $(inc)/bugtyp.inc $(inc)/dbcs.sw $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/error.INC $(inc)/mi.inc \
	$(inc)/pdb.inc $(inc)/syscall.inc $(inc)/vector.inc \
	$(inc)/version.inc mssw.asm scnam.inc

mscode.obj mscode.lst: mscode.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dossym.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/fastopen.inc $(inc)/fastxxxx.inc \
	$(inc)/mi.inc $(inc)/msbdata.inc $(inc)/mult.inc \
	$(inc)/vector.inc $(inc)/version.inc mssw.asm $(inc)\win386.inc

msdosme.obj:  msdosme.asm               \
	      dosmes.inc                \
	      msdos.cl1                 \
	      mssw.asm                  \
	      $(inc)\VERSIONA.INC       \
	      $(inc)\buffer.INC         \
	      $(inc)\dbcs.sw            \
	      $(inc)\dirent.INC         \
	      divmes.inc                \
	      $(inc)\doscntry.inc       \
	      $(inc)\dosmac.INC         \
	      $(inc)\dosmac.inc         \
	      $(inc)\dosseg.inc         \
	      $(inc)\dossym.inc         \
	      $(inc)\error.INC          \
	      $(inc)\version.inc        \
	      $(inc)\yesno.asm

time.obj time.lst: time.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/version.inc

getset.obj getset.lst: getset.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC \
	$(inc)/doscntry.inc $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dossym.inc $(inc)/error.INC $(inc)/mult.inc $(inc)/version.inc

parse.obj parse.lst: parse.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC

misc.obj misc.lst: misc.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/bpb.inc $(inc)/buffer.INC \
	$(inc)/bugtyp.inc $(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc $(inc)/error.INC \
	$(inc)/filemode.inc $(inc)/mi.inc $(inc)/mult.inc $(inc)/pdb.inc \
	$(inc)/sf.inc $(inc)/vector.inc $(inc)/version.inc

misc2.obj misc2.lst: misc2.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/bugtyp.inc $(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dossym.inc \
	$(inc)/error.INC $(inc)/fastxxxx.inc $(inc)/sf.inc $(inc)/sysvar.inc \
	$(inc)/version.inc

crit.obj crit.lst: crit.asm $(inc)/DOSSYM.INC $(inc)/VERSIONA.INC \
	$(inc)/buffer.INC $(inc)/bugtyp.inc $(inc)/dbcs.sw $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/error.INC $(inc)/int2a.inc \
	$(inc)/vector.inc

cpmio.obj cpmio.lst: cpmio.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/doscntry.inc $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/error.INC $(inc)/sf.inc $(inc)/vector.inc \
	kstrin.asm

cpmio2.obj cpmio2.lst: cpmio2.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/sf.inc

fcbio.obj fcbio.lst: fcbio.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/cpmfcb.inc $(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/dpb.inc $(inc)/error.INC $(inc)/filemode.inc \
	$(inc)/mult.inc $(inc)/sf.inc $(inc)/syscall.inc $(inc)/version.inc

fcbio2.obj fcbio2.lst: fcbio2.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/cpmfcb.inc $(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/error.INC $(inc)/filemode.inc $(inc)/sf.inc \
	$(inc)/version.inc

search.obj search.lst: search.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/fastopen.inc $(inc)/fastxxxx.inc

path.obj path.lst: path.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/filemode.inc $(inc)/mult.inc \
	$(inc)/version.inc

ioctl.obj ioctl.lst: ioctl.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/bpb.inc $(inc)/buffer.INC \
	$(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/dpb.inc $(inc)/error.INC \
	$(inc)/ioctl.inc $(inc)/mult.inc $(inc)/sf.inc $(inc)/vector.inc

delete.obj delete.lst: delete.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/FASTOPEN.INC $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/fastxxxx.inc \
	$(inc)/filemode.inc $(inc)/mult.inc $(inc)/sf.inc

rename.obj rename.lst: rename.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/filemode.inc $(inc)/find.inc $(inc)/mult.inc \
	$(inc)/sf.inc

finfo.obj finfo.lst: finfo.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/fastopen.inc $(inc)/fastxxxx.inc \
	$(inc)/mult.inc

dup.obj dup.lst: dup.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/sf.inc $(inc)/version.inc

create.obj create.lst: create.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/filemode.inc $(inc)/mult.inc $(inc)/sf.inc \
	$(inc)/version.inc

open.obj open.lst: open.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dossym.inc \
	$(inc)/error.INC $(inc)/fastopen.inc $(inc)/fastxxxx.inc \
	$(inc)/filemode.inc $(inc)/mult.inc $(inc)/sf.inc

dinfo.obj dinfo.lst: dinfo.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/mult.inc

isearch.obj isearch.lst: isearch.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/fastopen.inc \
	$(inc)/fastxxxx.inc $(inc)/mult.inc

abort.obj abort.lst: abort.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/mult.inc $(inc)/pdb.inc $(inc)/sf.inc

close.obj close.lst: close.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/mult.inc $(inc)/sf.inc

dircall.obj dircall.lst: dircall.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/FASTOPEN.INC $(inc)/FASTXXXX.INC $(inc)/VERSIONA.INC \
	$(inc)/buffer.INC $(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc $(inc)/error.INC \
	$(inc)/mult.inc $(inc)/sf.inc

disk.obj disk.lst: disk.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/fastxxxx.inc $(inc)/filemode.inc \
	$(inc)/mult.inc $(inc)/sf.inc $(inc)/version.inc

disk2.obj disk2.lst: disk2.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/filemode.inc $(inc)/sf.inc $(inc)/version.inc

disk3.obj disk3.lst: disk3.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/sf.inc $(inc)/version.inc

dir.obj dir.lst: dir.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dossym.inc $(inc)/dpb.inc $(inc)/error.INC $(inc)/fastopen.inc

dir2.obj dir2.lst: dir2.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC \
	$(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dossym.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/fastopen.inc

dev.obj dev.lst: dev.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/sf.inc $(inc)/version.inc

mknode.obj mknode.lst: mknode.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/dossym.inc $(inc)/dpb.inc $(inc)/error.INC \
	$(inc)/fastopen.inc $(inc)/filemode.inc $(inc)/sf.inc

rom.obj rom.lst: rom.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/fastxxxx.inc $(inc)/sf.inc $(inc)/version.inc

fcb.obj fcb.lst: fcb.asm $(inc)/VERSIONA.INC $(inc)/buffer.INC \
	$(inc)/dbcs.sw $(inc)/devsym.inc $(inc)/dirent.INC \
	$(inc)/doscntry.inc $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dossym.inc $(inc)/error.INC $(inc)\version.inc mssw.asm

msctrlc.obj msctrlc.lst: msctrlc.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/exe.inc $(inc)/filemode.inc \
	$(inc)/mi.inc $(inc)/mult.inc $(inc)/pdb.inc $(inc)/sf.inc \
	$(inc)/syscall.inc $(inc)/vector.inc $(inc)/version.inc mssw.asm

fat.obj fat.lst: fat.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/sf.inc

buf.obj buf.lst: buf.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/version.inc

msproc.obj proc.lst: msproc.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/arena.inc $(inc)/buffer.INC \
	$(inc)/curdir.inc $(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC \
	$(inc)/dosseg.inc $(inc)/error.INC $(inc)/exe.inc $(inc)/pdb.inc \
	$(inc)/sf.inc $(inc)/syscall.inc $(inc)/vector.inc \
	$(inc)/version.inc

alloc.obj alloc.lst: alloc.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/arena.inc $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC

srvcall.obj srvcall.lst: srvcall.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpl.asm \
	$(inc)/error.INC $(inc)/mult.inc $(inc)/sf.inc

segcheck.obj segcheck.lst: segcheck.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/dpb.inc $(inc)/version.inc $(inc)/sf.inc \
	$(inc)/int2a.inc

util.obj util.lst: util.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/pdb.inc $(inc)/sf.inc $(inc)/version.inc

handle.obj handle.lst: handle.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/bugtyp.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/filemode.inc $(inc)/mult.inc $(inc)/pdb.inc \
	$(inc)/sf.inc $(inc)/syscall.inc $(inc)/version.inc

macro.obj macro.lst: macro.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/error.INC $(inc)/mult.inc

macro2.obj macro2.lst: macro2.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/curdir.inc \
	$(inc)/dbcs.sw $(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/error.INC $(inc)/mult.inc

file.obj file.lst: file.asm $(inc)/VERSIONA.INC \
	$(inc)/buffer.INC $(inc)/bugtyp.inc $(inc)/dbcs.sw $(inc)/devsym.inc \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc \
	$(inc)/dossym.inc $(inc)/error.INC $(inc)/filemode.inc $(inc)/sf.inc \
	$(inc)/version.inc

lock.obj lock.lst: lock.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/lock.inc $(inc)/mult.inc $(inc)/sf.inc \
	$(inc)/version.inc

share.obj share.lst: share.asm $(inc)/DEVSYM.INC $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/buffer.INC $(inc)/dbcs.sw \
	$(inc)/dirent.INC $(inc)/dosmac.INC $(inc)/dosseg.inc $(inc)/dpb.inc \
	$(inc)/error.INC $(inc)/sf.inc

exepatch.obj exepatch.lst: exepatch.asm $(inc)/DOSSYM.INC \
	$(inc)/VERSIONA.INC $(inc)/dosseg.inc  $(inc)/exe.inc \
	$(inc)/version.inc

msinit.obj msinit.lst: msinit.asm $(inc)/arena.inc $(inc)/buffer.inc \
	$(inc)/curdir.inc $(inc)/devsym.inc $(inc)/dirent.inc \
	$(inc)/doscntry.inc $(inc)/dosmac.inc $(inc)/dosseg.inc \
	$(inc)/dpb.inc $(inc)/fastopen.inc $(inc)/find.inc $(inc)/mi.inc \
	$(inc)/pdb.inc $(inc)/sf.inc $(inc)/sysvar.inc $(inc)/vector.inc \
	$(inc)/version.inc $(inc)/xmm.inc mssw.asm $(inc)/dossym.inc \
	$(inc)/bugtyp.inc $(inc)\win386.inc

msdos.bin: origin.obj \
                msdata.obj \
                mstable.obj \
                msdisp.obj \
                mscode.obj \
                msdosme.obj \
                time.obj \
                getset.obj \
                parse.obj \
                misc.obj \
                misc2.obj \
                crit.obj \
                cpmio.obj \
                cpmio2.obj \
                fcbio.obj \
                fcbio2.obj \
                search.obj \
                path.obj \
                ioctl.obj \
                delete.obj \
                rename.obj \
                finfo.obj \
                dup.obj \
                create.obj \
                open.obj \
                dinfo.obj \
                isearch.obj \
                abort.obj \
                close.obj \
                dircall.obj \
                disk.obj \
                disk2.obj \
                disk3.obj \
                dir.obj \
                dir2.obj \
                dev.obj \
                mknode.obj \
                rom.obj \
                fcb.obj \
                msctrlc.obj \
                fat.obj \
                buf.obj \
                msproc.obj \
                alloc.obj \
                srvcall.obj \
                segcheck.obj \
                util.obj \
                handle.obj \
                macro.obj \
                macro2.obj \
                file.obj \
                lock.obj \
                share.obj \
                exepatch.obj \
                msinit.obj makefile msdos.lnk
	link $(link_opts) @msdos.lnk
	reloc msdos.exe msdos.bin

$(dest): msdos.bin
	stripz msdos.bin $(dest)
