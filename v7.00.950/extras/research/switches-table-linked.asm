p_parms struc
 dw ?
 db 1,1,';'
p_parms ends
p_pos struc
 dw ?
 dw ?
 dw ?
 dw ?
 db 0
p_pos ends
sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 648fh
noval db 0
result_val db 8 dup (0)
 org 64bdh
swit_e_range db 1,1,2
 dd 30h,400h
 org 65c2h
swit_parms	p_parms <swit_parmsx>

IFDEF DOS7_CONFIG
swit_parmsx dw  0                       ; no positionals
            db  8                       ; number of switches
            dw  swit_k_ctrl,swit_t_ctrl,swit_w_ctrl,swit_c_ctrl
            dw  swit_n_ctrl,swit_f_ctrl,swit_d_ctrl,swit_e_ctrl
            db  0                       ; no keywords

        public  swit_n,swit_f
swit_k_ctrl p_pos <0,0,result_val,noval,1>
swit_k  db      '/K',0
swit_t_ctrl p_pos <0,0,result_val,noval,1>
swit_t  db      '/T',0
swit_w_ctrl p_pos <0,0,result_val,noval,1>
swit_w  db      '/W',0
swit_c_ctrl p_pos <0,0,result_val,noval,1>
swit_c  db      '/C',0
swit_n_ctrl p_pos <0,0,result_val,noval,1>
swit_n  db      '/N',0
swit_f_ctrl p_pos <0,0,result_val,noval,1>
swit_f  db      '/F',0
swit_d_ctrl p_pos <0,0,result_val,noval,1>
swit_d  db      '/D',0
swit_e_ctrl p_pos <8001h,0,result_val,swit_e_range,1>
swit_e  db      '/E',0
ELSE
swit_parmsx dw	0		; no positionals
            db  5               ; # of switches
	    dw	swit_k_ctrl	; /k control
            dw  swit_n_ctrl     ; /n control (for MULTI_CONFIG only)
            dw  swit_f_ctrl     ; /f control (for MULTI_CONFIG only)
            dw  swit_t_ctrl     ; /t control
            dw  swit_w_ctrl     ; /w control
	    db	0		; no keywords

        public  swit_n          ; used by MULTI_CONFIG in sysinit2.asm
        public  swit_f          ; used by MULTI_CONFIG in sysinit2.asm

swit_k_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_k db	'/K',0
swit_n_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_n db       '/N',0
swit_f_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows
swit_f db       '/F',0
swit_t_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows	M059
swit_t db	'/T',0			   ;				M059
swit_w_ctrl p_pos <0,0,result_val,noval,1> ; switch string follows	M063
swit_w db	'/W',0			   ;				M063

ENDIF

;   There doesn't need to be p_swit_n or p_swit_f because /N and /F are
;   acted upon during MULTI_CONFIG processing;  we only needed entries
;   in the above table to prevent the parsing code from complaining about them

p_swit_k	db     0	; local variable
p_swit_t	db     0	; local variable			M059
p_swit_w	db     0	; local variable			M063
IFDEF DOS7_CONFIG
p_swit_c        db      0
ENDIF


sysinitseg ends
end
