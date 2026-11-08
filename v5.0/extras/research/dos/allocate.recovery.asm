	TITLE	ROM - Low level disk routines
	NAME	Rom

;**	Physical sector calculation
;
;	FIGREC
;	RELEASE
;	GETEOF
;
	include	version.inc
	include	dosseg.inc
	include	dossym.inc
	include	devsym.inc
	include	dpb.inc
	include	sf.inc
	I_need	HIGH_SECTOR,WORD
	i_need	FATBYT,WORD
	i_need	THISSFT,DWORD
	i_need	DISK_FULL,BYTE
DOSCODE	SEGMENT
	ASSUME	SS:DOSDATA,CS:DOSCODE,DS:NOTHING,ES:NOTHING
Break   <ALLOCATE -- Assign disk space>
;---------------------------------------------------------------------------
;
; Procedure Name : ALLOCATE - Allocate Disk Space
;
;   ALLOCATE is called to allocate disk clusters.  The new clusters are
;   FAT-chained onto the end of the existing file.
;
;   The DPB contains the cluster # of the last free cluster allocated
;   (dpb_next_free).  We start at this cluster and scan towards higher
;   numbered clusters, looking for the necessary free blocks.
;
;   Once again, fancy terminology gets in the way of corrct coding.  When
;   using next_free, start scanning AT THAT POINT and not the one following it.
;   This fixes the boundary condition bug when only free = next_free = 2.
;
;       If we get to the end of the disk without satisfaction:
;
;           if (dpb_next_free == 2) then we've scanned the whole disk.
;               return (insufficient_disk_space)
;           ELSE
;               dpb_next_free = 2; start scan over from the beginning.
;
;   Note that there is no multitasking interlock.  There is no race when
;   examining the entrys in an in-core FAT block since there will be no
;   context switch.  When UNPACK context switches while waiting for a FAT read
;   we are done with any in-core FAT blocks, so again there is no race.  The
;   only special concern is that V2 and V3 MSDOS left the last allocated
;   cluster as "00"; marking it EOF only when the entire alloc request was
;   satisfied.  We can't allow another activation to think this cluster is
;   free, so we give it a special temporary mark to show that it is, indeed,
;   allocated.
;
;   Note that when we run out of space this algorithem will scan from
;   dpb_next_free to the end, then scan from cluster 2 through the end,
;   redundantly scanning the later part of the disk.  This only happens when
;   we run out of space, so sue me.
;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;            C  A  V  E  A  T     P  A  T  T  E  R  S  O  N                ;
;                                                                          ;
;   The use of FATBYT and RESTFATBYT is somewhat mysterious.  Here is the
;   explanation:
;
;   In the NUL file case (sf_firclus currently 0) ALLOCATE is called with
;   entry BX = 0.  What needs to be done in this case is to stuff the cluster
;   number of the first cluster allocated in sf_firclus when the ALLOCATE is
;   complete.  THIS VALUE IS SAVED TEMPORARILY IN CLUSTER 0, HENCE THE CURRENT
;   VALUE IN CLUSTER 0 MUST BE SAVED AND RESTORED.  This is a side effect of
;   the fact that PACK and UNPACK don't treat requests for clusters 0 and 1 as
;   errors.  This "stuff" is done by the call to PACK which is right before
;   the
;           LOOP    findfre         ; alloc more if needed
;   instruction when the first cluster is allocated to the nul file.  The
;   value is recalled from cluster 0 and stored at sf_firclus at ads4:
;
;   This method is obviously useless (because it is non-reentrant) for
;   multitasking, and will have to be changed.  Storing the required value on
;   the stack is recommended.  Setting sf_firclus at the PACK of cluster 0
;   (instead of actually doing the PACK) is BAD because it doesn't handle
;   problems with INT 24 well.
;
;            C  A  V  E  A  T     P  A  T  T  E  R  S  O  N                ;
;----+----+----+----+----+----+----+----+----+----+----+----+----+----+----;
;                                                                          ;
;       ENTRY   BX = Last cluster of file (0 if null file)
;               CX = No. of clusters to allocate
;               ES:BP = Base of drive parameters
;               [THISSFT] = Points to SFT
;
;       EXIT    'C' set if insufficient space
;                 [FAILERR] can be tested to see the reason for failure
;                 CX = max. no. of clusters that could be added to file
;               'C' clear if space allocated
;                 BX = First cluster allocated
;                 FAT is fully updated
;                 sf_FIRCLUS field of SFT set if file was null
;
;       USES    ALL but SI, BP

	return

PROCEDURE ALLOCATE,NEAR

	DOSAssume   <DS>,"Allocate"

	Assert	ISDPB,<ES,BP>,"Allocate"


        PUSH    BX                      ; save (bx)
        XOR     BX,BX
        invoke  UNPACK
        MOV     [FATBYT],DI             ; save correct cluster 0 value
        POP     BX
        retc                            ; abort if error   [INTERR?]

        PUSH    CX
        PUSH    BX

        MOV     DX,BX
        Assert      ISDPB,<ES,BP>,"Allocate/Unpack"
        mov     bx,es:[bp.dpb_next_free]
        cmp     bx,2
        ja      findfre

;   couldn't find enough free space beyond dpb_next_free, or dpb_next_free is
;   <2 or >dpb_max_clus.  Reset it and restart the scan

ads1:
        Assert      ISDPB,<ES,BP>,"Alloc/ads1"
        mov     es:[bp.dpb_next_free],2
        mov     bx,1                    ; Counter next instruction so first
                                        ;       cluster examined is 2

;   Scanning both forwards and backwards for a free cluster
;
;       (BX) = forwards scan pointer
;       (CX) = clusters remaining to be allocated
;       (DX) = current last cluster in file
;       (TOS) = last cluster of file

FINDFRE:
        INC     BX
        Assert      ISDPB,<ES,BP>,"Alloc/findfre"
        CMP     BX,ES:[BP.dpb_max_cluster]

;hkn; bad code! replace with ja.
	ja      ads7            ; at end of disk

;        JBE     aupk
;        jmp     ads7            ; at end of disk
;aupk:

        invoke  UNPACK          ; check out this cluster
        jc      ads4            ; FAT error             [INTERR?]
        jnz     findfre         ; not free, keep on truckin

;   Have found a free cluster.  Chain it to the file
;
;       (BX) = found free cluster #
;       (DX) = current last cluster in file

        mov     es:[bp.dpb_next_free],bx        ; next time start search here
        xchg    ax,dx           ; save (dx) in ax
        mov     dx,1            ; mark this free guy as "1"
        invoke  PACK            ; set special "temporary" mark
        jc      ads4            ; FAT error             [INTERR?]
        CMP     ES:[BP.dpb_free_cnt],-1 ; Free count valid?
        JZ      NO_ALLOC                ; No
        DEC     ES:[BP.dpb_free_cnt]    ; Reduce free count by 1
NO_ALLOC:
        xchg    ax,dx           ; (dx) = current last cluster in file
        XCHG    BX,DX
        MOV     AX,DX
        invoke  PACK            ; link free cluster onto file
                                ;  CAVEAT.. On Nul file, first pass stuffs
                                ;    cluster 0 with FIRCLUS value.
        jc      ads4            ; FAT error             [INTERR?]
        xchg    BX,AX           ; (BX) = last one we looked at
        mov     dx,bx           ; (dx) = current end of file
        LOOP    findfre         ; alloc more if needed

;   We've successfully extended the file.  Clean up and exit
;
;       (BX) = last cluster in file

        MOV     DX,0FFFFH
        invoke  PACK            ; mark last cluster EOF

;   Note that FAT errors jump here to clean the stack and exit.  this saves us
;   2 whole bytes.  Hope its worth it...
;
;       'C' set iff error
;       calling (BX) and (CX) pushed on stack

ads4:   POP     BX
        POP     CX              ; Don't need this stuff since we're successful
        retc
        invoke  UNPACK          ; Get first cluster allocated for return
                                ; CAVEAT... In nul file case, UNPACKs cluster 0.
        retc
        invoke  RESTFATBYT      ; Restore correct cluster 0 value
        retc
        XCHG    BX,DI           ; (DI) = last cluster in file upon our entry
        OR      DI,DI           ; clear 'C'
        retnz                   ; we were extending an existing file

;   We were doing the first allocation for a new file.  Update the SFT cluster
;   info
dofastk:
        PUSH    DX
        MOV     DL,ES:[BP.dpb_drive]              ; get drive #

        PUSH    ES
        LES     DI,[THISSFT]
        Assert  ISSFT,<ES,DI>,"Allocate/ads4"
        MOV     ES:[DI.sf_firclus],BX
        MOV     ES:[DI.sf_lstclus],BX
do_norm5:
        POP     ES
        POP     DX
        return


;** we're at the end of the disk, and not satisfied.  See if we've scanned ALL
;   of the disk...

ads7:   cmp     es:[bp.dpb_next_free],2
	DLJNZ	ads1		; start scan from front of disk

;   Sorry, we've gone over the whole disk, with insufficient luck.  Lets give
;   the space back to the free list and tell the caller how much he could have
;   had.  We have to make sure we remove the "special mark" we put on the last
;   cluster we were able to allocate, so it doesn't become orphaned.
;
;       (CX) = clusters remaining to be allocated
;       (TOS) = last cluster of file (before call to ALLOCATE)
;       (TOS+1) = # of clusters wanted to allocate


        POP     BX              ; (BX) = last cluster of file
        MOV     DX,0FFFFH
        invoke  RELBLKS         ; give back any clusters just alloced
        POP     AX              ; No. of clusters requested
                                ; Don't "retc". We are setting Carry anyway,
                                ;   Alloc failed, so proceed with return CX
                                ;   setup.
        SUB     AX,CX           ; AX=No. of clusters allocated
        invoke  RESTFATBYT      ; Don't "retc". We are setting Carry anyway,
                                ;   Alloc failed.
;       fmt     <>,<>,<"$p: disk full in allocate\n">
        MOV     [DISK_FULL],1   ;MS. indicating disk full
        STC
        return

EndProc ALLOCATE

;-----------------------------------------------------------------------
;
; Procedure Name : RESTFATBYT
;
; SEE ALLOCATE CAVEAT
;       Carry set if error (currently user FAILed to I 24)
;-----------------------------------------------------------------------

procedure RESTFATBYT,NEAR
	DOSAssume   <DS>,"RestFATByt"

        PUSH    BX
        PUSH    DX
        PUSH    DI
        XOR     BX,BX
        MOV     DX,[FATBYT]
        invoke  PACK
        POP     DI
        POP     DX
        POP     BX
        return

EndProc RESTFATBYT
DOSCODE ENDS
	END
