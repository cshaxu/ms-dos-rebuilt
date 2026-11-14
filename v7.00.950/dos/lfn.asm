        TITLE   LFN - Long filename directory state
        NAME    LFN
;
; Reconstructed from the DOS 7.0a target. Procedure names are assigned.
;
        include version.inc
        include dosseg.inc
        include dossym.inc
        include dpb.inc

        i_need  IoState1,WORD
        i_need  DirStart,WORD
        i_need  DirSec,DWORD
        i_need  ClusNum,WORD
        i_need  LastEnt,WORD
        i_need  EntLast,WORD
        i_need  ThisDPB,DWORD
        i_need  CurBuf,DWORD

DOSCODE segment
        ASSUME  CS:DOSCODE,SS:DOSDATA

; Input: AH = first name byte, AL = directory attributes.
; Output: ZF set for a long filename entry; CX destroyed.
; Keep the first directory position and count intervening deleted entries.
procedure LfnScanEntry,near
        push    ds
        push    ss
        pop     ds
        ASSUME  DS:DOSDATA
        test    ah,ah
        jz      lfn_scan_other
        cmp     ah,0e5h
        jz      lfn_scan_deleted
        and     al,0fh
        cmp     al,0fh
        jnz     lfn_scan_other
        cmp     IoState1,0
        jnz     lfn_scan_count
        mov     cx,DirStart
        mov     IoState1+2,cx
        mov     cx,WORD PTR DirSec
        mov     IoState1+4,cx
        mov     cx,WORD PTR DirSec+2
        mov     IoState1+6,cx
        mov     cx,ClusNum
        mov     IoState1+8,cx
        mov     cx,LastEnt
        mov     IoState1+10,cx
lfn_scan_count:
        inc     IoState1
        sub     al,al
        pop     ds
        ret
lfn_scan_deleted:
        cmp     IoState1,0
        jz      lfn_scan_other
        inc     IoState1
lfn_scan_other:
        or      al,0ffh
        pop     ds
        ret
EndProc LfnScanEntry

; Input: DS:DI -> saved seven-word directory state.
; Delete its entries, flush changed directory buffers, restore search state.
; Carry reports failure. The count is cleared after the state is restored.
lfn_delete_empty:
        clc
        ret
procedure LfnDeleteEntries,near
        ASSUME  DS:DOSDATA,ES:NOTHING
        mov     cx,[di]
        jcxz    lfn_delete_empty
        add     cx,[di+10]
        dec     cx
        cmp     cx,[di+12]
        jbe     lfn_delete_swap
        jmp     lfn_delete_bad
lfn_delete_swap:
        mov     ax,[di+2]
        xchg    ax,DirStart
        mov     [di+2],ax
        mov     ax,[di+4]
        xchg    ax,WORD PTR DirSec
        mov     [di+4],ax
        mov     ax,[di+6]
        xchg    ax,WORD PTR DirSec+2
        mov     [di+6],ax
        mov     ax,[di+8]
        xchg    ax,ClusNum
        mov     [di+8],ax
        mov     ax,[di+10]
        xchg    ax,LastEnt
        mov     [di+10],ax
        mov     ax,[di+12]
        xchg    ax,EntLast
        mov     [di+12],ax
        push    bp
        push    es
lfn_delete_read:
        les     bp,ThisDPB
        push    di
        invoke  GETENTRY
        pop     di
        jc      lfn_delete_restore
        les     bp,CurBuf
        xor     ah,ah
lfn_delete_entry:
        mov     al,es:[bx]
        or      al,al
        jz      lfn_delete_restore
        cmp     al,0e5h
        jz      lfn_delete_next
        mov     al,0fh
        and     al,es:[bx+11]
        cmp     al,0fh
        jz      lfn_delete_mark
        cmp     WORD PTR [di],1
        jnz     lfn_delete_failed
lfn_delete_mark:
        mov     BYTE PTR es:[bx],0e5h
        or      ah,40h
lfn_delete_next:
        inc     LastEnt
        dec     WORD PTR [di]
        jz      lfn_delete_dirty
        add     bx,32
        cmp     bx,dx
        jb      lfn_delete_entry
lfn_delete_dirty:
        test    BYTE PTR es:[bp+5],40h
        jnz     lfn_delete_flush
        test    ah,ah
        jz      lfn_delete_read
        invoke  INC_DIRTY_COUNT
lfn_delete_flush:
        or      BYTE PTR es:[bp+5],44h
        les     bp,ThisDPB
        mov     al,es:[bp.dpb_drive]
        push    di
        invoke  DeferredFlush
        pop     di
        jc      lfn_delete_restore
        cmp     WORD PTR [di],0
        jnz     lfn_delete_read
lfn_delete_restore:
        pop     es
        pop     bp
        mov     ax,[di+2]
        mov     DirStart,ax
        mov     ax,[di+4]
        mov     WORD PTR DirSec,ax
        mov     ax,[di+6]
        mov     WORD PTR DirSec+2,ax
        mov     ax,[di+8]
        mov     ClusNum,ax
        mov     ax,[di+10]
        mov     LastEnt,ax
        mov     ax,[di+12]
        mov     EntLast,ax
        mov     WORD PTR [di],0
        ret
lfn_delete_failed:
        stc
        jmp     short lfn_delete_restore
lfn_delete_bad:
        stc
        ret
EndProc LfnDeleteEntries

; Input: DS:DI -> destination record. Copy only when a chain was found.
; SI and ES preserved; CX and DI destroyed.
procedure LfnSaveState,near
        ASSUME  DS:DOSDATA
        mov     cx,IoState1
        mov     [di],cx
        jcxz    lfn_save_done
        push    si
        push    es
        mov     cx,ds
        mov     es,cx
        mov     si,OFFSET DOSDATA:IoState1
        mov     cx,7
        cld
        rep     movsw
        pop     es
        pop     si
lfn_save_done:
        ret
EndProc LfnSaveState

; Unsupported extended calls return the complete function code.
        EXTRN   From_GetSet:NEAR
procedure $LfnCall,near
        mov     ax,7100h
lfn_call_error:
        jmp     From_GetSet
EndProc $LfnCall

procedure $ExtendedCall,near
        mov     ax,7200h
        jmp     short lfn_call_error
EndProc $ExtendedCall

DOSCODE ends
        end
