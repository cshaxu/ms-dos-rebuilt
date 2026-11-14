;*** Resident message storage and separately assembled resource text.
	public	ResMsgClass,ResMsgCount,ResMsgTable
	public	ResMsg101Ptr
	public	ResMsg102Ptr
	public	ResMsg103Ptr
	public	ResMsg104Ptr
	public	ResMsg105Ptr
	public	ResMsg106Ptr
	public	ResMsg107Ptr
	public	ResMsg108Ptr
	public	ResMsg109Ptr
	public	ResMsg110Ptr
	public	ResMsg111Ptr
	public	ResMsg112Ptr
	public	ResMsg113Ptr
	public	ResMsg114Ptr
	public	ResMsg115Ptr
	public	ResMsg116Ptr
	public	ResMsg117Ptr
	public	ResMsg118Ptr
	public	ResMsg119Ptr
	public	ResMsg121Ptr
	public	ResMsg122Ptr
	public	ResMsg123Ptr
	public	ResMsg124Ptr
	public	ResMsg125Ptr
	public	ResMsg126Ptr
	public	ResMsg127Ptr
	public	ResMsg128Ptr
	public	ResMsg129Ptr
	public	ResMsg130Ptr
	public	ResMsg131Ptr
	public	ResMsg132Ptr
	public	ResMsg133Ptr
	public	ResMsg219Ptr
	public	ResMsg220Ptr
	public	ResMsg221Ptr
	public	ResMsg222Ptr
	public	ResMsg223Ptr
	public	ResMsg224Ptr
	public	ResMsg225Ptr
	public	ResMsg226Ptr
	public	ResMsg227Ptr
	public	ResMsg228Ptr
	public	ResMsg229Ptr
	public	ResMsg230Ptr
	public	ResMsg231Ptr
	public	ResMsg232Ptr
	public	ResMsg233Ptr
	public	ResMsg234Ptr
	public	ResMsg235Ptr
	public	ResMsg236Ptr
	public	ResMsg237Ptr
	public	ResMsg238Ptr
	public	ResMsg239Ptr
	public	ResMsg301Ptr
	public	ResMsg302Ptr
	public	ResMsg303Ptr
	public	ResMsg304Ptr
	public	ResMsg305Ptr
	public	ResMsg306Ptr
	public	ResMsg307Ptr
	public	ResMsg308Ptr
	public	ResMsg309Ptr
	public	ResMsg310Ptr
	public	ResMsg311Ptr
	public	ResMsg201Ptr
	public	ResMsg202Ptr
	public	ResMsg203Ptr
	public	ResMsg204Ptr
	public	ResMsg205Ptr
	public	ResMsg206Ptr
	public	ResMsg207Ptr
	public	ResMsg208Ptr
	public	ResMsg209Ptr
	public	ResMsg210Ptr
	public	ResMsg211Ptr
	public	ResMsg212Ptr
	public	ResMsg213Ptr
	public	ResMsg214Ptr
	public	ResMsg215Ptr
	public	ResMsg216Ptr
	public	ResMsg217Ptr
	public	ResMsg218Ptr
	public	ResMsg280Ptr
	public	ResMsg281Ptr
	public	ResMsg282Ptr
	public	ResMsg283Ptr
	public	ResMsg284Ptr
	public	ResMsg285Ptr
	public	ResMsg286Ptr
	public	ResMsg287Ptr
	public	ResMsg288Ptr
	public	ResMsg289Ptr
	public	ResMsg290Ptr

IFDEF RESIDENT_MSG_BUFFER
; Resident messages are read from the executable resource at startup.
; Reserve the class directory and its message-text workspace.
ResMsgClass	db	0
ResMsgCount	db	0
ResMsgTable	label	word
ResMsg101	dw	0
ResMsg101Ptr	dw	0
ResMsg102	dw	0
ResMsg102Ptr	dw	0
ResMsg103	dw	0
ResMsg103Ptr	dw	0
ResMsg104	dw	0
ResMsg104Ptr	dw	0
ResMsg105	dw	0
ResMsg105Ptr	dw	0
ResMsg106	dw	0
ResMsg106Ptr	dw	0
ResMsg107	dw	0
ResMsg107Ptr	dw	0
ResMsg108	dw	0
ResMsg108Ptr	dw	0
ResMsg109	dw	0
ResMsg109Ptr	dw	0
ResMsg110	dw	0
ResMsg110Ptr	dw	0
ResMsg111	dw	0
ResMsg111Ptr	dw	0
ResMsg112	dw	0
ResMsg112Ptr	dw	0
ResMsg113	dw	0
ResMsg113Ptr	dw	0
ResMsg114	dw	0
ResMsg114Ptr	dw	0
ResMsg115	dw	0
ResMsg115Ptr	dw	0
ResMsg116	dw	0
ResMsg116Ptr	dw	0
ResMsg117	dw	0
ResMsg117Ptr	dw	0
ResMsg118	dw	0
ResMsg118Ptr	dw	0
ResMsg119	dw	0
ResMsg119Ptr	dw	0
ResMsg121	dw	0
ResMsg121Ptr	dw	0
ResMsg122	dw	0
ResMsg122Ptr	dw	0
ResMsg123	dw	0
ResMsg123Ptr	dw	0
ResMsg124	dw	0
ResMsg124Ptr	dw	0
ResMsg125	dw	0
ResMsg125Ptr	dw	0
ResMsg126	dw	0
ResMsg126Ptr	dw	0
ResMsg127	dw	0
ResMsg127Ptr	dw	0
ResMsg128	dw	0
ResMsg128Ptr	dw	0
ResMsg129	dw	0
ResMsg129Ptr	dw	0
ResMsg130	dw	0
ResMsg130Ptr	dw	0
ResMsg131	dw	0
ResMsg131Ptr	dw	0
ResMsg132	dw	0
ResMsg132Ptr	dw	0
ResMsg133	dw	0
ResMsg133Ptr	dw	0
ResMsg219	dw	0
ResMsg219Ptr	dw	0
ResMsg220	dw	0
ResMsg220Ptr	dw	0
ResMsg221	dw	0
ResMsg221Ptr	dw	0
ResMsg222	dw	0
ResMsg222Ptr	dw	0
ResMsg223	dw	0
ResMsg223Ptr	dw	0
ResMsg224	dw	0
ResMsg224Ptr	dw	0
ResMsg225	dw	0
ResMsg225Ptr	dw	0
ResMsg226	dw	0
ResMsg226Ptr	dw	0
ResMsg227	dw	0
ResMsg227Ptr	dw	0
ResMsg228	dw	0
ResMsg228Ptr	dw	0
ResMsg229	dw	0
ResMsg229Ptr	dw	0
ResMsg230	dw	0
ResMsg230Ptr	dw	0
ResMsg231	dw	0
ResMsg231Ptr	dw	0
ResMsg232	dw	0
ResMsg232Ptr	dw	0
ResMsg233	dw	0
ResMsg233Ptr	dw	0
ResMsg234	dw	0
ResMsg234Ptr	dw	0
ResMsg235	dw	0
ResMsg235Ptr	dw	0
ResMsg236	dw	0
ResMsg236Ptr	dw	0
ResMsg237	dw	0
ResMsg237Ptr	dw	0
ResMsg238	dw	0
ResMsg238Ptr	dw	0
ResMsg239	dw	0
ResMsg239Ptr	dw	0
ResMsg301	dw	0
ResMsg301Ptr	dw	0
ResMsg302	dw	0
ResMsg302Ptr	dw	0
ResMsg303	dw	0
ResMsg303Ptr	dw	0
ResMsg304	dw	0
ResMsg304Ptr	dw	0
ResMsg305	dw	0
ResMsg305Ptr	dw	0
ResMsg306	dw	0
ResMsg306Ptr	dw	0
ResMsg307	dw	0
ResMsg307Ptr	dw	0
ResMsg308	dw	0
ResMsg308Ptr	dw	0
ResMsg309	dw	0
ResMsg309Ptr	dw	0
ResMsg310	dw	0
ResMsg310Ptr	dw	0
ResMsg311	dw	0
ResMsg311Ptr	dw	0
ResMsg201	dw	0
ResMsg201Ptr	dw	0
ResMsg202	dw	0
ResMsg202Ptr	dw	0
ResMsg203	dw	0
ResMsg203Ptr	dw	0
ResMsg204	dw	0
ResMsg204Ptr	dw	0
ResMsg205	dw	0
ResMsg205Ptr	dw	0
ResMsg206	dw	0
ResMsg206Ptr	dw	0
ResMsg207	dw	0
ResMsg207Ptr	dw	0
ResMsg208	dw	0
ResMsg208Ptr	dw	0
ResMsg209	dw	0
ResMsg209Ptr	dw	0
ResMsg210	dw	0
ResMsg210Ptr	dw	0
ResMsg211	dw	0
ResMsg211Ptr	dw	0
ResMsg212	dw	0
ResMsg212Ptr	dw	0
ResMsg213	dw	0
ResMsg213Ptr	dw	0
ResMsg214	dw	0
ResMsg214Ptr	dw	0
ResMsg215	dw	0
ResMsg215Ptr	dw	0
ResMsg216	dw	0
ResMsg216Ptr	dw	0
ResMsg217	dw	0
ResMsg217Ptr	dw	0
ResMsg218	dw	0
ResMsg218Ptr	dw	0
ResMsg280	dw	0
ResMsg280Ptr	dw	0
ResMsg281	dw	0
ResMsg281Ptr	dw	0
ResMsg282	dw	0
ResMsg282Ptr	dw	0
ResMsg283	dw	0
ResMsg283Ptr	dw	0
ResMsg284	dw	0
ResMsg284Ptr	dw	0
ResMsg285	dw	0
ResMsg285Ptr	dw	0
ResMsg286	dw	0
ResMsg286Ptr	dw	0
ResMsg287	dw	0
ResMsg287Ptr	dw	0
ResMsg288	dw	0
ResMsg288Ptr	dw	0
ResMsg289	dw	0
ResMsg289Ptr	dw	0
ResMsg290	dw	0
ResMsg290Ptr	dw	0
	db	0B00h dup (0)
ResidentClassEnd	label	byte
ELSE
;***	Translateable text for command.com resident data.

;   Class six contains record-relative message pointers.
ResMsgClass	db	6
ResMsgCount	db	93
ResMsgTable	label	word
ResMsg101	dw	101
ResMsg101Ptr	dw	ResChar101-ResMsg101
ResMsg102	dw	102
ResMsg102Ptr	dw	ResChar102-ResMsg102
ResMsg103	dw	103
ResMsg103Ptr	dw	ResChar103-ResMsg103
ResMsg104	dw	104
ResMsg104Ptr	dw	ResChar104-ResMsg104
ResMsg105	dw	105
ResMsg105Ptr	dw	ResChar105-ResMsg105
ResMsg106	dw	106
ResMsg106Ptr	dw	ResChar106-ResMsg106
ResMsg107	dw	107
ResMsg107Ptr	dw	Req_Abort-ResMsg107
ResMsg108	dw	108
ResMsg108Ptr	dw	Req_Retry-ResMsg108
ResMsg109	dw	109
ResMsg109Ptr	dw	Req_Ignore-ResMsg109
ResMsg110	dw	110
ResMsg110Ptr	dw	Req_Fail-ResMsg110
ResMsg111	dw	111
ResMsg111Ptr	dw	Req_End-ResMsg111
ResMsg112	dw	112
ResMsg112Ptr	dw	MRead-ResMsg112
ResMsg113	dw	113
ResMsg113Ptr	dw	MWrite-ResMsg113
ResMsg114	dw	114
ResMsg114Ptr	dw	BlkDevErr-ResMsg114
ResMsg115	dw	115
ResMsg115Ptr	dw	CharDevErr-ResMsg115
ResMsg116	dw	116
ResMsg116Ptr	dw	NeedVolMsg-ResMsg116
ResMsg117	dw	117
ResMsg117Ptr	dw	BadFatMsg-ResMsg117
ResMsg118	dw	118
ResMsg118Ptr	dw	ComBad-ResMsg118
ResMsg119	dw	119
ResMsg119Ptr	dw	PutBackMsg-ResMsg119
ResMsg121	dw	121
ResMsg121Ptr	dw	EndBatMes-ResMsg121
ResMsg122	dw	122
ResMsg122Ptr	dw	ExecEMes-ResMsg122
ResMsg123	dw	123
ResMsg123Ptr	dw	ExeBad-ResMsg123
ResMsg124	dw	124
ResMsg124Ptr	dw	TooBig-ResMsg124
ResMsg125	dw	125
ResMsg125Ptr	dw	NoHandMes-ResMsg125
ResMsg126	dw	126
ResMsg126Ptr	dw	RBadNam-ResMsg126
ResMsg127	dw	127
ResMsg127Ptr	dw	AccDen-ResMsg127
ResMsg128	dw	128
ResMsg128Ptr	dw	BMemMes-ResMsg128
ResMsg129	dw	129
ResMsg129Ptr	dw	HaltMes-ResMsg129
ResMsg130	dw	130
ResMsg130Ptr	dw	FRetMes-ResMsg130
ResMsg131	dw	131
ResMsg131Ptr	dw	Patricide-ResMsg131
ResMsg132	dw	132
ResMsg132Ptr	dw	MissingDllMsg-ResMsg132
ResMsg133	dw	133
ResMsg133Ptr	dw	Newlin-ResMsg133
ResMsg219	dw	219
ResMsg219Ptr	dw	ExtErr19-ResMsg219
ResMsg220	dw	220
ResMsg220Ptr	dw	ExtErr20-ResMsg220
ResMsg221	dw	221
ResMsg221Ptr	dw	ExtErr21-ResMsg221
ResMsg222	dw	222
ResMsg222Ptr	dw	ExtErr22-ResMsg222
ResMsg223	dw	223
ResMsg223Ptr	dw	ExtErr23-ResMsg223
ResMsg224	dw	224
ResMsg224Ptr	dw	ExtErr24-ResMsg224
ResMsg225	dw	225
ResMsg225Ptr	dw	ExtErr25-ResMsg225
ResMsg226	dw	226
ResMsg226Ptr	dw	ExtErr26-ResMsg226
ResMsg227	dw	227
ResMsg227Ptr	dw	ExtErr27-ResMsg227
ResMsg228	dw	228
ResMsg228Ptr	dw	ExtErr28-ResMsg228
ResMsg229	dw	229
ResMsg229Ptr	dw	ExtErr29-ResMsg229
ResMsg230	dw	230
ResMsg230Ptr	dw	ExtErr30-ResMsg230
ResMsg231	dw	231
ResMsg231Ptr	dw	ExtErr31-ResMsg231
ResMsg232	dw	232
ResMsg232Ptr	dw	ExtErr32-ResMsg232
ResMsg233	dw	233
ResMsg233Ptr	dw	ExtErr33-ResMsg233
ResMsg234	dw	234
ResMsg234Ptr	dw	ExtErr34-ResMsg234
ResMsg235	dw	235
ResMsg235Ptr	dw	ExtErr35-ResMsg235
ResMsg236	dw	236
ResMsg236Ptr	dw	ExtErr36-ResMsg236
ResMsg237	dw	237
ResMsg237Ptr	dw	ExtErr37-ResMsg237
ResMsg238	dw	238
ResMsg238Ptr	dw	ExtErr38-ResMsg238
ResMsg239	dw	239
ResMsg239Ptr	dw	ExtErr39-ResMsg239
ResMsg301	dw	301
ResMsg301Ptr	dw	ParsErr01-ResMsg301
ResMsg302	dw	302
ResMsg302Ptr	dw	ParsErr02-ResMsg302
ResMsg303	dw	303
ResMsg303Ptr	dw	ParsErr03-ResMsg303
ResMsg304	dw	304
ResMsg304Ptr	dw	ParsErr04-ResMsg304
ResMsg305	dw	305
ResMsg305Ptr	dw	ParsErr05-ResMsg305
ResMsg306	dw	306
ResMsg306Ptr	dw	ParsErr06-ResMsg306
ResMsg307	dw	307
ResMsg307Ptr	dw	ParsErr07-ResMsg307
ResMsg308	dw	308
ResMsg308Ptr	dw	ParsErr08-ResMsg308
ResMsg309	dw	309
ResMsg309Ptr	dw	ParsErr09-ResMsg309
ResMsg310	dw	310
ResMsg310Ptr	dw	ParsErr10-ResMsg310
ResMsg311	dw	311
ResMsg311Ptr	dw	ParsErr11-ResMsg311
ResMsg201	dw	201
ResMsg201Ptr	dw	ExtErr01-ResMsg201
ResMsg202	dw	202
ResMsg202Ptr	dw	ExtErr02-ResMsg202
ResMsg203	dw	203
ResMsg203Ptr	dw	ExtErr03-ResMsg203
ResMsg204	dw	204
ResMsg204Ptr	dw	ExtErr04-ResMsg204
ResMsg205	dw	205
ResMsg205Ptr	dw	ExtErr05-ResMsg205
ResMsg206	dw	206
ResMsg206Ptr	dw	ExtErr06-ResMsg206
ResMsg207	dw	207
ResMsg207Ptr	dw	ExtErr07-ResMsg207
ResMsg208	dw	208
ResMsg208Ptr	dw	ExtErr08-ResMsg208
ResMsg209	dw	209
ResMsg209Ptr	dw	ExtErr09-ResMsg209
ResMsg210	dw	210
ResMsg210Ptr	dw	ExtErr10-ResMsg210
ResMsg211	dw	211
ResMsg211Ptr	dw	ExtErr11-ResMsg211
ResMsg212	dw	212
ResMsg212Ptr	dw	ExtErr12-ResMsg212
ResMsg213	dw	213
ResMsg213Ptr	dw	ExtErr13-ResMsg213
ResMsg214	dw	214
ResMsg214Ptr	dw	ExtErr14-ResMsg214
ResMsg215	dw	215
ResMsg215Ptr	dw	ExtErr15-ResMsg215
ResMsg216	dw	216
ResMsg216Ptr	dw	ExtErr16-ResMsg216
ResMsg217	dw	217
ResMsg217Ptr	dw	ExtErr17-ResMsg217
ResMsg218	dw	218
ResMsg218Ptr	dw	ExtErr18-ResMsg218
ResMsg280	dw	280
ResMsg280Ptr	dw	ExtErr80-ResMsg280
ResMsg281	dw	281
ResMsg281Ptr	dw	ExtErr81-ResMsg281
ResMsg282	dw	282
ResMsg282Ptr	dw	ExtErr82-ResMsg282
ResMsg283	dw	283
ResMsg283Ptr	dw	ExtErr83-ResMsg283
ResMsg284	dw	284
ResMsg284Ptr	dw	ExtErr84-ResMsg284
ResMsg285	dw	285
ResMsg285Ptr	dw	ExtErr85-ResMsg285
ResMsg286	dw	286
ResMsg286Ptr	dw	ExtErr86-ResMsg286
ResMsg287	dw	287
ResMsg287Ptr	dw	ExtErr87-ResMsg287
ResMsg288	dw	288
ResMsg288Ptr	dw	ExtErr88-ResMsg288
ResMsg289	dw	289
ResMsg289Ptr	dw	ExtErr89-ResMsg289
ResMsg290	dw	290
ResMsg290Ptr	dw	ExtErr90-ResMsg290

;   Length-prefixed text, in message-index order.
ResChar101	db	1
Abort_Char	db	"A"
ResChar102	db	1
Retry_Char	db	"R"
ResChar103	db	1
Ignore_Char	db	"I"
ResChar104	db	1
Fail_Char	db	"F"
ResChar105	db	1
Yes_Char	db	"Y"
ResChar106	db	1
No_Char 	db	"N"
msg	Req_Abort, <"Abort">
msg	Req_Retry, <", Retry">
msg	Req_Ignore,<", Ignore">
msg	Req_Fail,  <", Fail">
msg	Req_End,   <"?">
msg	MRead,	   <"reading",0>
msg	MWrite,	   <"writing",0>
msg	BlkDevErr, <" %1 drive %2",CR,LF>
msg	CharDevErr,<" %1 device %2",CR,LF>
msg	NeedVolMsg,<"Please insert volume %1 serial %2-%3",CR,LF>
msg	BadFatMsg, <"File allocation table bad, drive %1",CR,LF>
msg	ComBad,	   <"Invalid COMMAND.COM",CR,LF>
msg	PutBackMsg,<"Enter correct name of Command Interpreter (eg, C:\COMMAND.COM)",CR,LF,">>">
msg	EndBatMes, <CR,LF,"Terminate batch job (Y/N)?">
msg	ExecEMes,  <"Cannot execute %1",CR,LF>
msg	ExeBad,	   <"Error in EXE file",CR,LF>
msg	TooBig,	   <"Program too big to fit in memory",CR,LF>
msg	NoHandMes, <CR,LF,"No free file handles">
msg	RBadNam,   <"Bad command or file name",CR,LF>
msg	AccDen,	   <"Access denied ">
msg	BMemMes,   <CR,LF,"Memory allocation error">
msg	HaltMes,   <CR,LF,"Cannot load COMMAND, system halted",CR,LF>
msg	FRetMes,   <CR,LF,"Cannot start COMMAND, exiting",CR,LF>
msg	Patricide, <CR,LF,"Top level process aborted, cannot continue",CR,LF>
msg	MissingDllMsg,<CR,LF,"Cannot find File DLL - %1",CR,LF>
msg	Newlin,	   <CR,LF>
msg	ExtErr19,<"Write protect error">
msg	ExtErr20,<"Invalid unit">
msg	ExtErr21,<"Not ready">
msg	ExtErr22,<"Invalid device request">
msg	ExtErr23,<"Data error">
msg	ExtErr24,<"Invalid device request parameters">
msg	ExtErr25,<"Seek error">
msg	ExtErr26,<"Invalid media type">
msg	ExtErr27,<"Sector not found">
msg	ExtErr28,<"Printer out of paper error">
msg	ExtErr29,<"Write fault error">
msg	ExtErr30,<"Read fault error">
msg	ExtErr31,<"General failure">
msg	ExtErr32,<"Sharing violation">
msg	ExtErr33,<"Lock violation">
msg	ExtErr34,<"Invalid disk change">
msg	ExtErr35,<"FCB unavailable">
msg	ExtErr36,<"System resource exhausted">
msg	ExtErr37,<"Code page mismatch">
msg	ExtErr38,<"Out of input">
msg	ExtErr39,<"Insufficient disk space">
msg	ParsErr01,<"Too many parameters">
msg	ParsErr02,<"Required parameter missing">
msg	ParsErr03,<"Invalid switch">
msg	ParsErr04,<"Invalid keyword">
msg	ParsErr05,<" ">
msg	ParsErr06,<"Parameter value not in allowed range">
msg	ParsErr07,<"Parameter value not allowed">
msg	ParsErr08,<"Parameter value not allowed">
msg	ParsErr09,<"Parameter format not correct">
msg	ParsErr10,<"Invalid parameter">
msg	ParsErr11,<"Invalid parameter combination">
msg	ExtErr01,<"Invalid function">
msg	ExtErr02,<"File not found">
msg	ExtErr03,<"Path not found">
msg	ExtErr04,<"Too many open files">
msg	ExtErr05,<"Access denied ">
msg	ExtErr06,<"Invalid handle">
msg	ExtErr07,<"Memory control blocks destroyed">
msg	ExtErr08,<"Insufficient memory">
msg	ExtErr09,<"Invalid memory block address">
msg	ExtErr10,<"Invalid Environment">
msg	ExtErr11,<"Invalid format">
msg	ExtErr12,<"Invalid function parameter">
msg	ExtErr13,<"Invalid data">
ExtErr14	db	0
	public	ExtErr14
msg	ExtErr15,<"Invalid drive specification">
msg	ExtErr16,<"Attempt to remove current directory">
msg	ExtErr17,<"Not same device">
msg	ExtErr18,<"No more files">
msg	ExtErr80,<"File exists">
ExtErr81	db	0
	public	ExtErr81
msg	ExtErr82,<"Cannot make directory entry">
msg	ExtErr83,<"Fail on INT 24">
msg	ExtErr84,<"Too many redirections">
msg	ExtErr85,<"Duplicate redirection">
msg	ExtErr86,<"Invalid password">
msg	ExtErr87,<"Invalid parameter">
msg	ExtErr88,<"Network data fault">
msg	ExtErr89,<"Function not supported by network">
msg	ExtErr90,<"Required system component not installed">
ResidentClassEnd	label	byte
ENDIF
	public	ResidentClassEnd
IFDEF RESIDENT_MSG_BUFFER
ResidentMsgFileOffset	dd	0	; resident class offset in command file
ENDIF

;   Message-service and critical-error pointer tables.
IFNDEF RESOURCE_ONLY
MsgPtrLists	label	dword
	dw	DATARES:ExtMsgPtrs,1	; extended error messages
	dw	DATARES:ParsMsgPtrs,1	; parse error messages
	dw	DATARES:ExtMsgPtrs,1	; critical error messages -
					;  use extended error list
	dw	0,0			; file system error messages - none
	dw	DATARES:MsgRetrv_Trap		; address of message retriever
MySeg3	dw	?			;  (segment filled in during init)
CritMsgPtrs	label	word
	dw	DATARES:ResMsg219Ptr,DATARES:ResMsg220Ptr,DATARES:ResMsg221Ptr,DATARES:ResMsg222Ptr,DATARES:ResMsg223Ptr,DATARES:ResMsg224Ptr
	dw	DATARES:ResMsg225Ptr,DATARES:ResMsg226Ptr,DATARES:ResMsg227Ptr,DATARES:ResMsg228Ptr,DATARES:ResMsg229Ptr,DATARES:ResMsg230Ptr
	dw	DATARES:ResMsg231Ptr,DATARES:ResMsg232Ptr,DATARES:ResMsg233Ptr,DATARES:ResMsg234Ptr,DATARES:ResMsg235Ptr,DATARES:ResMsg236Ptr
	dw	DATARES:ResMsg237Ptr,DATARES:ResMsg238Ptr,DATARES:ResMsg239Ptr
DataResEnd	label	byte
ParsMsgPtrs	label	word
	dw	DATARES:ResMsg301Ptr,DATARES:ResMsg302Ptr,DATARES:ResMsg303Ptr
	dw	DATARES:ResMsg304Ptr,DATARES:ResMsg305Ptr,DATARES:ResMsg306Ptr
	dw	DATARES:ResMsg307Ptr,DATARES:ResMsg308Ptr,DATARES:ResMsg309Ptr
	dw	DATARES:ResMsg310Ptr,DATARES:ResMsg311Ptr

NUMPARSMSGS	equ	($ - ParsMsgPtrs) / 2	;M033
ExtMsgPtrs	label	word
	dw	DATARES:ResMsg201Ptr,DATARES:ResMsg202Ptr,DATARES:ResMsg203Ptr
	dw	DATARES:ResMsg204Ptr,DATARES:ResMsg205Ptr,DATARES:ResMsg206Ptr
	dw	DATARES:ResMsg207Ptr,DATARES:ResMsg208Ptr,DATARES:ResMsg209Ptr
	dw	DATARES:ResMsg210Ptr,DATARES:ResMsg211Ptr,DATARES:ResMsg212Ptr
	dw	DATARES:ResMsg213Ptr,0,                DATARES:ResMsg215Ptr
	dw	DATARES:ResMsg216Ptr,DATARES:ResMsg217Ptr,DATARES:ResMsg218Ptr
	dw	DATARES:ResMsg219Ptr,DATARES:ResMsg220Ptr,DATARES:ResMsg221Ptr
	dw	DATARES:ResMsg222Ptr,DATARES:ResMsg223Ptr,DATARES:ResMsg224Ptr
	dw	DATARES:ResMsg225Ptr,DATARES:ResMsg226Ptr,DATARES:ResMsg227Ptr
	dw	DATARES:ResMsg228Ptr,DATARES:ResMsg229Ptr,DATARES:ResMsg230Ptr
	dw	DATARES:ResMsg231Ptr,DATARES:ResMsg232Ptr,DATARES:ResMsg233Ptr
	dw	DATARES:ResMsg234Ptr,DATARES:ResMsg235Ptr,DATARES:ResMsg236Ptr
	dw	DATARES:ResMsg237Ptr,DATARES:ResMsg238Ptr,DATARES:ResMsg239Ptr
	dw	80-40 dup (0) ; null ptrs for errors 40-79
	dw	DATARES:ResMsg280Ptr,0,                DATARES:ResMsg282Ptr
	dw	DATARES:ResMsg283Ptr,DATARES:ResMsg284Ptr,DATARES:ResMsg285Ptr
	dw	DATARES:ResMsg286Ptr,DATARES:ResMsg287Ptr,DATARES:ResMsg288Ptr
	dw	DATARES:ResMsg289Ptr,DATARES:ResMsg290Ptr
ExtMsgPtrsEnd	label	word

NUMEXTMSGS	equ	($ - ExtMsgPtrs) / 2	;M033
ExtMsgEnd	label	byte
ENDIF
