; Bounded comparative DOS 6 FIGREC, awaiting full rom.asm restoration.
include version.inc
include dosseg.inc
include dossym.inc
include devsym.inc
include dpb.inc
I_need HIGH_SECTOR,WORD
DOSCODE SEGMENT
ASSUME SS:DOSDATA,CS:DOSCODE,DS:NOTHING,ES:NOTHING
procedure	FIGREC,NEAR

        Assert      ISDPB,<ES,BP>,"FigRec"
        PUSH    CX
        MOV     CL,ES:[BP.dpb_cluster_shift]
        DEC     DX
        DEC     DX

;hkn; SS override HIGH_SECTOR
        MOV     [HIGH_SECTOR],0              ;F.C. >32mb
        OR      CL,CL                        ;F.C. >32mb
        JZ      noshift                      ;F.C. >32mb
        XOR     CH,CH                        ;F.C. >32mb
rotleft:                                     ;F.C. >32mb
        CLC                                  ;F.C. >32mb
        RCL     DX,1                         ;F.C. >32mb
        RCL     [HIGH_SECTOR],1              ;F.C. >32mb
        LOOP    rotleft                      ;F.C. >32mb
noshift:

;       SHL     DX,CL
        OR      DL,BL
        ADD     DX,ES:[BP.dpb_first_sector]
        ADC     [HIGH_SECTOR],0              ;F.C. >32mb
        POP     CX
        return
EndProc FIGREC
DOSCODE ENDS
END
