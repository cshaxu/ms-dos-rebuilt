himem = ..\dev\himem

all: himem.obj himem4.obj himem4b.obj himem1.obj himem2.obj

himem.obj: $(himem)\himem.asm bioscode.inc
	ml /c /Zm /I. /Fohimem.obj /Flhimem.lst $(himem)\himem.asm

himem4.obj: $(himem)\himem4.asm $(himem)\himem.inc bioscode.inc
	ml /c /Zm /I. /I$(himem) /Fohimem4.obj /Flhimem4.lst $(himem)\himem4.asm

himem4b.obj: $(himem)\himem4b.asm $(himem)\himem.inc bioscode.inc
	ml /c /Zm /I. /I$(himem) /Fohimem4b.obj /Flhimem4b.lst $(himem)\himem4b.asm

himem1.obj: $(himem)\himem1.asm
	ml /c /Zm /I. /Fohimem1.obj /Flhimem1.lst $(himem)\himem1.asm

himem2.obj: $(himem)\himem2.asm $(himem)\himem.inc bioscode.inc
	ml /c /Zm /I. /I$(himem) /Fohimem2.obj /Flhimem2.lst $(himem)\himem2.asm
