himem = ..\dev\himem

all: himem.obj himem4.obj himem4b.obj

himem.obj: $(himem)\himem.asm
	ml /c /Zm /Fohimem.obj /Flhimem.lst $(himem)\himem.asm

himem4.obj: $(himem)\himem4.asm $(himem)\himem.inc
	ml /c /Zm /I$(himem) /Fohimem4.obj /Flhimem4.lst $(himem)\himem4.asm

himem4b.obj: $(himem)\himem4b.asm $(himem)\himem.inc
	ml /c /Zm /I$(himem) /Fohimem4b.obj /Flhimem4b.lst $(himem)\himem4b.asm
