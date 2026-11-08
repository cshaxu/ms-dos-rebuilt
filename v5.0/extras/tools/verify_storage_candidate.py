"""Assemble a storage candidate and resolve its OMF at the target layout.

This bounded OMF resolver rejects unsupported record/fixup forms. It is a
comparison harness, not a production linker or replacement for disk routines.
No bytes from the target are copied into the resolved candidate.
"""
from pathlib import Path
import argparse, hashlib, json, os, re, shutil, subprocess, tempfile
from fat12_guest_file import read_root_file

root = Path(__file__).resolve().parent.parent.parent
e = root / 'extras/docs/etc/evidence'
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
parser=argparse.ArgumentParser()
parser.add_argument('--module',choices=('macro2-full','util-full','srvcall-full','alloc-full','macro-full','cpmio-full','msdisp-full','cpmio2-full','msctrlc-full','mscode-full','misc-full','dinfo-full','getset-full','ioctl-full','path-full','search-full','buf','disk-read','disk2-io','dev-io','dev-openclose','dev-iofunc','disk-full','disk2-full','disk3-full','rom-full','lock-full','close-full','finfo-full','delete-full','rename-full','create-full','isearch-full','open-full','abort-full','init-sft','handle-full','file-full','fcbio2-full','fcbio-full','crit','fat','validatecds','getpath','fastpath','dir','dirread','figrec','time','dircall','release','mknode','allocate','fastopen','share','create-error'),default='buf')
args=parser.parse_args()
configs={
 'macro2-full': ('macro2.full.recovery.asm','macro2.asm',0x6d07,0x70dd,{'GETEXTENDED': (27936, 7468), 'GETTHISDRV': (27955, 27788), 'GETCHARTYPE': (27968, 21022), 'PACKNAME': (27980, 8588), 'ECRITDISK': (28098, 4950), 'FATREAD_CDS': (28101, 22681), 'LCRITDISK': (28104, 4982), 'PATHCHRCMP': (28130, 21051), 'UCASE': (28147, 20966), 'CHECKTHISDEVICE': (28183, 17545), 'STRCPY': (28211, 4629), 'GETVISDRV': (28218, 27759), 'VALIDATECDS': (28229, 17355), 'FSTRCPY': (28256, 4644), 'NAMETRANS': (28558, 20857), 'STRLEN': (28606, 4653), 'GETCDSFROMDRV': (28679, 27875), 'SETATTRIB': (28797, 29505), 'SYS_RET_ERR': (28813, 1565), 'SYS_RET_OK': (28824, 1556), 'DSTRLEN': (28858, 4667)}),
 'util-full': ('util.full.recovery.asm','util.asm',0x683d,0x68fb,{}),
 'srvcall-full': ('srvcall.full.recovery.asm','srvcall.asm',0x66e7,0x683d,{'TABLEDISPATCH':(0x672f,0x1266),'SYS_RET_ERR':(0x673a,0x61d),'ECRITDISK':(0x6742,0x1356),'SFFROMSFN':(0x6746,0x6874),'DOS_COMMIT':(0x6767,0x31a2),'LCRITDISK':(0x676e,0x1376),'SYS_RET_OK':(0x6772,0x614),'GET_USER_STACK':(0x6795,0x4a5),'XCHGP':(0x67ae,0x1245),'REDISP':(0x67e4,0x393)}),
 'alloc-full': ('alloc.full.recovery.asm','alloc.asm',0x63f2,0x66e7,{'ECRITMEM':(0x645e,0x1356),'LCRITMEM':(0x64d2,0x1376),'SYS_RET_ERR':(0x64d7,0x61d),'GET_USER_STACK':(0x64fe,0x4a5),'SYS_RET_OK':(0x65bc,0x614)}),
 'macro-full': ('macro.full.recovery.asm','macro.asm',0x6b7b,0x6d07,{'SYS_RET_OK':(0x6bb2,0x614),'SYS_RET_ERR':(0x6bb5,0x61d),'GET_USER_STACK':(0x6c39,0x4a5)}),
 'cpmio-full': ('cpmio.full.recovery.asm','cpmio.asm',0x13d6,0x16fc,{'STATCHK':(0x13d8,0x530b),'IOFUNC':(0x13e7,0x4608),'READTIME':(0x1403,0xb1b),'OUTT':(0x1437,0x1707),'ESCCHAR':(0x147e,0xa18),'CANCHAR':(0x149d,0xa17),'BUFOUT':(0x14ab,0x179e),'OEMFUNCTIONKEY':(0x14c8,0xa43),'TAB':(0x151c,0x177b),'GET_IO_SFT':(0x1648,0x379f),'SPOOLINT':(0x1654,0x52dd),'DSKSTATCHK':(0x16c0,0x5254)}),
 'msdisp-full': ('msdisp.full.recovery.asm','msdisp.asm',0x275,0x4af,{'DSKSTATCHK':(0x409,0x5254),'DISPATCH':(0x40d,0xbe)}),
 'cpmio2-full': ('cpmio2.full.recovery.asm','cpmio2.asm',0x16fc,0x1829,{'$STD_CON_INPUT_NO_ECHO':(0x16fc,0x13d6),'STATCHK':(0x1724,0x530b),'RAWOUT':(0x1728,0x1683),'GET_IO_SFT':(0x173b,0x379f),'SPOOLINT':(0x17c8,0x52dd),'IOFUNC':(0x17cd,0x4608),'RAWOUT2':(0x17eb,0x16ae),'REDISP':(0x1826,0x393)}),
 'msctrlc-full': ('msctrlc.full.recovery.asm','msctrlc.asm',0x5248,0x56ce,{'DEVIOCALL2':(0x5283,0x47e2),'GET_IO_SFT':(0x5311,0x379f),'IOFUNC':(0x5319,0x4608),'DEV_CLOSE_SFT':(0x536d,0x4766),'DEV_OPEN_SFT':(0x5372,0x475e),'BUFOUT':(0x53a2,0x179e),'CRLF':(0x53a5,0x162e),'SWAPBACK':(0x53b1,0x33ff),'RESTORE_USER_WORLD':(0x53bd,0x46f),'COMMAND':(0x540c,0x31b),'DIVMES':(0x542b,0x99b),'DIVMESLEN':(0x542e,0x9ae),'EXIT_INNER':(0x5604,0x63ba),'$GET_INTERRUPT_VECTOR':(0x5619,0xead),'ARENA_FREE_PROCESS':(0x563a,0x63f2),'DOS_ABORT':(0x563d,0x2fdd),'ECRITDISK':(0x5649,0x1356),'FLUSHBUF':(0x564c,0x5c0a),'LCRITDISK':(0x564f,0x1376),'CHECK_VIRT_OPEN':(0x5652,0x4dcb),'CAL_LK':(0x56c9,0x657)}),
 'mscode-full': ('mscode.full.recovery.asm','mscode.asm',0x4af,None,{'I21_MAP_E_TAB':(0x697,0xb),'NOVXDERRMSG':(0x7ba,0x9b0),'FOO':(0x913,0x198),'DTAB':(0x918,0x19a),'SET_RQ_SC_PARMS':(0x4e0,0x5d03),'SAVE_USER_WORLD':(0x52b,0x486),'ECRITDISK':(0x534,0x1356),'LCRITDISK':(0x53d,0x1376),'DSKREAD':(0x540,0x38b5),'DSKRDBUFSCAN':(0x551,0x3b0c),'RESTORE_USER_WORLD':(0x572,0x46f),'DSKWRTBUFPURGE':(0x5cb,0x3e04),'DSKWRITE':(0x5cf,0x38de),'GETTHISDRV':(0x5d9,0x6c8c),'GET_USER_STACK':(0x614,0x4a5),'TABLEDISPATCH':(0x925,0x1266),'FAST_DISPATCH':(0x994,0x27f2)}),
 'misc-full': ('misc.full.recovery.asm','misc.asm',0xf50,0x11f3,{'SFFROMHANDLE':(0x110c,0x685a),'DOS_DUP':(0x112e,0x2b3a),'PJFNFROMHANDLE':(0x1131,0x683d),'$IOCTL':(0x11ea,0x235e),'SYS_RET_ERR':(0x11f0,0x61d),'GETTHISDRV':(0xf56,0x6c8c),'DISK_INFO':(0xf5b,0x2df1),'GET_USER_STACK':(0xf69,0x4a5),'FCB_RET_ERR':(0xf79,0x633),'ECRITDISK':(0xfaa,0x1356),'FATREAD_CDS':(0xfad,0x5899),'LCRITDISK':(0xfb0,0x1376),'FLUSHBUF':(0xfd0,0x5c0a)}),
 'dinfo-full': ('dinfo.full.recovery.asm','dinfo.asm',0x2df1,0x2e52,{'TESTNET':(0x2df1,0x1291),'ECRITDISK':(0x2e01,0x1356),'FATREAD_CDS':(0x2e04,0x5899),'UNPACK':(0x2e0c,0x56e5),'LCRITDISK':(0x2e4a,0x1376)}),
 'getset-full': ('getset.full.recovery.asm','getset.asm',0xc3f,0xf45,{'GET_USER_STACK':(0xc58,0x4a5),'SYS_RET_OK':(0xce5,0x614),'SYS_RET_ERR':(0xcf4,0x61d),'GETLET3':(0xd11,0x520b),'FROM_GETSET':(0xe45,0x625),'GETTHISDRV':(0xe52,0x6c8c),'DISK_INFO':(0xe57,0x2df1),'FCB_RET_ERR':(0xe6f,0x633),'GETVISDRV':(0xe9f,0x6c6f),'NLS_YES':(0xd22,0xa13),'NLS_YES2':(0xd29,0xa15),'NLS_NO':(0xd30,0xa14),'NLS_NO2':(0xd37,0xa16)}),
 'ioctl-full': ('ioctl.full.recovery.asm','ioctl.asm',0x233a,0x2619,{'GETTHISDRV':(0x24c4,0x6c8c),'SFFROMHANDLE': (9080, 26714), 'SYS_RET_ERR': (9087, 1565), 'SYS_RET_OK': (9122, 1556), 'GET_USER_STACK': (9151, 1189), 'GET_IO_SFT': (9194, 14239), 'IOFUNC': (9202, 17928), 'DEVIOCALL2': (9391, 18402), 'SET_I24_EXTENDED_ERROR': (9601, 22183)}),
 'path-full': ('path.full.recovery.asm','path.asm',0x21cc,0x233a,{'DOS_RMDIR':(0x227b,0x333b),'DOS_MKDIR':(0x22fd,0x31f6),'ECRITDISK':(0x21cc,0x1356),'GETVISDRV':(0x21d1,0x6c6f),'LCRITDISK':(0x21d6,0x1376),'SYS_RET_ERR':(0x21e3,0x61d),'VALIDATECDS':(0x2207,0x43cb),'SYS_RET_OK':(0x2242,0x614),'TRANSPATHNOSET':(0x224d,0x6d75),'GETCDSFROMDRV':(0x2265,0x6ce3),'STRCMP':(0x226a,0x11f3),'TRANSPATH':(0x2286,0x6d69),'DOS_CHDIR':(0x229f,0x32f6),'GET_USER_STACK':(0x22b3,0x4a5),'FSTRCPY':(0x22f5,0x1224),'DSTRLEN':(0x2332,0x123b)}),
 'search-full': ('search.full.recovery.asm','search.asm',0x1ffb,0x21cc,{'TRANSFCB':(0x2016,0x6d07),'FCB_RET_ERR':(0x201c,0x633),'FCB_RET_OK':(0x208c,0x630),'DOS_SEARCH_NEXT':(0x20dd,0x2f43),'TRANSPATHSET':(0x210c,0x6d6d),'SYS_RET_ERR':(0x2113,0x61d),'SYS_RET_OK':(0x2157,0x614),'DOS_SEARCH_FIRST':(0x21c8,0x2e52)}),
 'fcbio-full': ('fcbio.full.recovery.asm','fcbio.asm',0x1829,0x1cf1,{
     'GETEXTENDED':(0x1829,0x1d2c),'GETEXTENT':(0x182c,0x1cff),
     'FCB_RET_OK':(0x183e,0x630),'FCB_RET_ERR':(0x1852,0x633),
     'TRANSFCB':(0x1844,0x6d07),'DOS_DELETE':(0x184b,0x2619),
     'GET_FILE_INFO':(0x1868,0x2a36),'CHECKSHARE':(0x18be,0x754b),
     'DOS_CLOSE':(0x18ef,0x304a),'DOS_RENAME':(0x1945,0x27f9),
     'ISSFTNET':(0x1954,0x12aa),'SAVE_USER_WORLD':(0x1a22,0x486),
     'RESTORE_USER_WORLD':(0x1afb,0x46f),'UCASE':(0x1b10,0x51e6),
     'DEVNAME':(0x1b88,0x433d),'FIND_DPB':(0x1bb3,0x6bb8),
     'HARDERR':(0x1cec,0x54aa)}),

 'fcbio2-full': ('fcbio2.full.recovery.asm','fcbio2.asm',0x1cf1,0x1ffb,{
     'DOS_OPEN':(0x70e4,0x2c7c),'DOS_CREATE':(0x71b5,0x2b50),
     'DOS_READ':(0x46fe,0x3419),'DOS_WRITE':(0x46ee,0x3648),
     'SFTFROMFCB':(0x1dcf,0x1c9a),'FCB_RET_ERR':(0x1dd4,0x633),
     'SAVEFCBINFO':(0x1e30,0x194f),'DATE16':(0x1ec8,0xaf1),
     'GET_USER_STACK':(0x1edb,0x4a5),'TRANSFCB':(0x1ef5,0x6d07),
     'LRUFCB':(0x1f07,0x1a21),'BLASTSFT':(0x1f29,0x1c0a),
     'FCBHARDERR':(0x1f38,0x1cd0),'ISSFTNET':(0x1f3e,0x12aa),
     'CHECKSHARE':(0x1f43,0x754b),'GETTHISDRV':(0x1f61,0x6c8c),
     'CHECKFCB':(0x1f9d,0x1c20),'SHAREEND':(0x1fc3,0x7583)}),

 'file-full': ('file.full.recovery.asm','file.asm',0x70dd,0x74a6,{
     'DOS_OPEN':(0x70e4,0x2c7c),'DOS_CREATE':(0x71b5,0x2b50),
     'DOS_CREATE_NEW':(0x72a0,0x2c1f),'ECRITDISK':(0x70e8,0x1356),
     'SFNFREE':(0x70eb,0x68b2),'LCRITDISK':(0x70ee,0x1376),
     'JFNFREE':(0x7102,0x689f),'TRANSPATH':(0x7127,0x6d69),
     'SET_EXT_MODE':(0x715c,0x2c68),'SYS_RET_OK':(0x7184,0x614),
     'FROM_GETSET':(0x71ae,0x625),'SYS_RET_ERR':(0x71b1,0x61d),
     'TRANSPATHSET':(0x71c8,0x6d6d),'GET_FILE_INFO':(0x71ec,0x2a36),
     'GET_USER_STACK':(0x71f1,0x4a5),'SET_FILE_ATTRIBUTE':(0x71fb,0x2a97),
     'DOS_DELETE':(0x7221,0x2619),'GETCDSFROMDRV':(0x7272,0x6ce3),
     'STRCMP':(0x7277,0x11f3),'DOS_RENAME':(0x7298,0x27f9),
     'PATHCHRCMP':(0x72ec,0x523b),'READTIME':(0x72fa,0xb1b),
     '$CLOSE':(0x7495,0x68fb)}),

 'handle-full': ('handle.full.recovery.asm','handle.asm',0x68fb,0x6b7b,{
     'PJFNFROMHANDLE':(0x691a,0x683d),'DOS_CLOSE':(0x6921,0x304a),
     'SYS_RET_OK':(0x6928,0x614),'SYS_RET_ERR':(0x692b,0x61d),
     'DOS_COMMIT':(0x693d,0x31a2),'$ALLOC':(0x6997,0x645e),
     '$DEALLOC':(0x69dd,0x65e3),'DOS_READ':(0x46fe,0x3419),
     'DOS_WRITE':(0x46ee,0x3648),'GET_USER_STACK':(0x6aa3,0x4a5),
     'ECRITDISK':(0x6aff,0x1356),'LCRITDISK':(0x6b1c,0x1376),
     'JFNFREE':(0x6b2d,0x689f),'DOS_DUP_DIRECT':(0x6b3c,0x2b44),
     'SFFROMHANDLE':(0x6b59,0x685a)}),

 'init-sft': ('msinit.sft.recovery.asm','msinit.asm',0x7a60,0x7a93,{}),
 'abort-full': ('abort.full.recovery.asm','abort.asm',0x2fdd,0x304a,{'$CLOSE':(0x2feb,0x68fb),'SFFROMSFN':(0x3021,0x6874)}),
 'isearch-full': ('isearch.full.recovery.asm','isearch.asm',0x2e52,0x2fdd,{
     'ECRITDISK':(0x2e6f,0x1356),'GETPATH':(0x2e8e,0x4071),
     'LCRITDISK':(0x2ea3,0x1376),'INITCDS':(0x2f68,0x6bcd),
     'GOTDPB':(0x2f75,0x60b),'SETDIRSRCH':(0x2fb0,0x400c),
     'STARTSRCH':(0x2fb8,0x431c),'GETENT':(0x2fbc,0x3fdd),
     'NEXTENT':(0x2fc1,0x3f11)}),
 'open-full': ('open.full.recovery.asm','open.asm',0x2c7c,0x2df1,{
     'ECRITDISK':(0x2cdc,0x1356),'GETPATH':(0x2ce4,0x4071),
     'LCRITDISK':(0x2cf9,0x1376),'DOOPEN':(0x2d4e,0x4cd9),
     'DEV_OPEN_SFT':(0x2d73,0x475e),'SHARE_VIOLATION':(0x2d9a,0x755d),
     'SHARE_CHECK':(0x2dac,0x7558),'IDLE':(0x2db2,0x124c)}),

 'create-full': ('create.full.recovery.asm','create.asm',0x2b50,0x2c7c,{
     'ECRITDISK':(0x2bc9,0x1356),'MAKENODE':(0x2bcc,0x4b1a),
     'LCRITDISK':(0x2bd6,0x1376),'FASTOPEN_DELETE':(0x2be8,0x27bb),
     'FATREAD_CDS':(0x2c08,0x5899),'SET_SFT_MODE':(0x2c1c,0x2d6f),
     '$IOCTL':(0x2c37,0x235e)}),

 'rename-full': ('rename.full.recovery.asm','rename.asm',0x27f9,0x2a36,{
     'TESTNET':(0x27f9,0x1291),'ECRITDISK':(0x2838,0x1356),
     'DOS_SEARCH_FIRST':(0x283b,0x2e52),'LCRITDISK':(0x2851,0x1376),
     'CHECK_PATHLEN2':(0x286a,0x232f),'REN_DEL_CHECK':(0x287c,0x274d),
     'FASTOPEN_DELETE':(0x2898,0x27bb),'GETPATHNOSET':(0x28b5,0x4077),
     'FLUSHBUF':(0x28c7,0x5c0a),'DEVNAME':(0x291f,0x433d),
     'SETDIRSRCH':(0x292c,0x400c),'FINDENTRY':(0x2931,0x3ec0),
     'RENAME_MAKE':(0x2962,0x4b40),'SHAREEND':(0x296f,0x7583),
     'INC_DIRTY_COUNT':(0x297e,0x5d16),'FASTOPEN_RENAME':(0x29d7,0x27d0),
     'RENAME_NEXT':(0x29e9,0x2f8f),'STARTSRCH':(0x2a20,0x431c),
     'GETENT':(0x2a26,0x3fdd)}),

 'delete-full': ('delete.full.recovery.asm','delete.asm',0x2619,0x27f9,{
     'TESTNET':(0x2619,0x1291),'ECRITDISK':(0x2629,0x1356),
     'GETPATHNOSET':(0x267c,0x4077),'LCRITDISK':(0x268b,0x1376),
     'INC_DIRTY_COUNT':(0x26d3,0x5d16),'RELEASE':(0x26ef,0x5069),
     'GETENTRY':(0x26fb,0x3fda),'NEXTENT':(0x2700,0x3f11),
     'FLUSHBUF':(0x270d,0x5c0a),'SET_MEDIA_ID':(0x2733,0x2c24),
     'FATREAD_CDS':(0x2736,0x5899),'STRLEN':(0x2765,0x122d),
     'SKIPBACK':(0x276b,0x6f4e),'PACKNAME':(0x2774,0x218c),
     'DOOPEN':(0x278d,0x4cd9),'SHAREENTER':(0x279f,0x7588),
     'SHAREEND':(0x27ad,0x7583)}),

 'finfo-full': ('finfo.full.recovery.asm','finfo.asm',0x2a36,0x2b3a,{
     'TESTNET':(0x2a36,0x1291),'ECRITDISK':(0x2a41,0x1356),
     'LCRITDISK':(0x2a58,0x1376),'GETPATH':(0x2ac6,0x4071),
     'REN_DEL_CHECK':(0x2ae0,0x274d),'INC_DIRTY_COUNT':(0x2b04,0x5d16),
     'FASTOPEN_UPDATE':(0x2b17,0x27ea),'FLUSHBUF':(0x2b1c,0x5c0a)}),

 'close-full': ('close.full.recovery.asm','close.asm',0x304a,0x31f6,{
     'ECRITDISK':(0x305e,0x1356),'SHAREEND':(0x306b,0x7583),
     'XCHGP':(0x3089,0x1245),'METACOMPARE':(0x308c,0x3f6f),
     'INC_DIRTY_COUNT':(0x30f4,0x5d16),'FASTOPEN_UPDATE':(0x312b,0x27ea),
     'FLUSHBUF':(0x312f,0x5c0a),'DEV_CLOSE_SFT':(0x313a,0x4766),
     'LCRITDISK':(0x3146,0x1376),'FATREAD_SFT':(0x3170,0x5887),
     'GETBUFFR':(0x3181,0x5b0b),'DEV_OPEN_SFT':(0x31cc,0x475e),
     'DATE16':(0x31e2,0xaf1)}),

 'lock-full': ('lock.full.recovery.asm','lock.asm',0x74a6,0x7558,{
     'SFFROMHANDLE':(0x74ab,0x685a),'SYS_RET_ERR':(0x74b3,0x61d),
     'SYS_RET_OK':(0x74f8,0x614),'IDLE':(0x751d,0x124c),
     'HARDERR':(0x753e,0x54aa)}),

 'rom-full': ('rom.full.recovery.asm','rom.asm',0x4de7,0x50a7,{
     'UNPACK':(0x4e07,0x56e5),'ISEOF':(0x4e0e,0x56ce),
     'GETBUFFR':(0x4e31,0x5b0b),'PLACEBUF':(0x4e86,0x5abf),
     'INC_DIRTY_COUNT':(0x4edf,0x5d16),'PACK':(0x4ff0,0x5739)}),

 'disk3-full': ('disk3.full.recovery.asm','disk3.asm',0x3b96,0x3ec0,{
     'CHECK_WRITE_LOCK':(0x3b96,0x387e),'BREAKDOWN':(0x3bb7,0x39b1),
     'SKPCLP':(0x3c5e,0x4e07),'ALLOCATE':(0x3c63,0x4fb7),
     'FNDCLUS':(0x3c8c,0x4de7),'BUFWRT':(0x3cc8,0x4e98),
     'NEXTSEC':(0x3cdd,0x4efa),'OPTIMIZE':(0x3cf3,0x4f2b),
     'DWRITE':(0x3d08,0x38c5),'SETCLUS':(0x3d55,0x3ae2),
     'SET_ACC_ERR_DS':(0x3d58,0x3a4a),'ADDREC':(0x3da2,0x3aff),
     'RELBLKS':(0x3dc5,0x506b),'FASTOPEN_UPDATE':(0x3df5,0x27ea),
     'RELEASE':(0x3dfd,0x5069),'GETCURHEAD':(0x3e4f,0x5aa6),
     'DEC_DIRTY_COUNT':(0x3e71,0x5d1c),'SCANPLACE':(0x3e79,0x5ab8)}),

 'disk2-full': ('disk2.full.recovery.asm','disk2.asm',0x38b5,0x3b96,{
     'SETREAD':(0x38c0,0x485e),'SETWRITE':(0x38e9,0x4891),
     'DEVIOCALL2':(0x38f4,0x47e2),'HARDERR':(0x3923,0x54aa),
     'DIV32':(0x396c,0x3e8a),'SHR32':(0x3986,0x3eb1),
     'LOCK_VIOLATION':(0x39f5,0x7525),'CHECK_READ_LOCK':(0x3a26,0x389d),
     'FNDCLUS':(0x3a37,0x4de7),'WRTERR22':(0x3a42,0x3c6a),
     'BUFRD':(0x3a62,0x4e5d),'NEXTSEC':(0x3a6e,0x4efa),
     'OPTIMIZE':(0x3a84,0x4f2b),'SET_RQ_SC_PARMS':(0x3a97,0x5d03),
     'DREAD':(0x3a9a,0x3863),'ISEOF':(0x3ab4,0x56ce),
     'GETCURHEAD':(0x3b20,0x5aa6),'SCANPLACE':(0x3b89,0x5ab8)}),

 'disk-full': ('disk.full.recovery.asm','disk.asm',0x33ff,0x38b5,{
     'SET_ACC_ERR':(0x3427,0x3a4c),'SETUP':(0x342a,0x3927),
     'ISSFTNET':(0x342f,0x12aa),'ECRITDISK':(0x3448,0x1356),
     'DISKREAD':(0x344b,0x3a08),'LCRITDISK':(0x344e,0x1376),
     'SETREAD':(0x3493,0x485e),'DEVIOCALL':(0x349c,0x47df),
     'CHARHARD':(0x34ac,0x5479),'SET_ACC_ERR_DS':(0x34cc,0x3a4a),
     'DSKSTATCHK':(0x34f3,0x5254),'DEVIOCALL2':(0x34f6,0x47e2),
     'OUTT':(0x35ec,0x1707),'SETSFT':(0x360b,0x3ade),
     '$STD_CON_STRING_INPUT':(0x362d,0x143c),'DISKWRITE':(0x3684,0x3b96),
     'DOS_COMMIT':(0x3695,0x31a2),'SETWRITE':(0x369f,0x4891),
     'ADDREC':(0x36e3,0x3aff),'SFFROMHANDLE':(0x37ab,0x685a),
     'UNPACK':(0x3805,0x56e5),'ISEOF':(0x380c,0x56ce),
     'FIGREC':(0x381b,0x4f8b),'GETBUFFR':(0x3825,0x5b0b),
     'DSKREAD':(0x3855,0x38b5),'HARDERRRW':(0x386e,0x390d),
     'LOCK_CHECK':(0x3891,0x750f),'WRITE_LOCK_VIOLATION':(0x3897,0x3a01),
     'READ_LOCK_VIOLATION':(0x38af,0x39db)}),

 'dev-iofunc': ('dev.iofunc.recovery.asm','dev.asm',0x45f6,0x475e,{
     'SAVE_USER_WORLD':(0x4632,0x486),'RESTORE_USER_WORLD':(0x4691,0x46f),
     'DEVIOCALL':(0x466d,0x47df),'CHARHARD':(0x46af,0x5479),
     'DOS_WRITE':(0x46ee,0x3648),'DOS_READ':(0x46fe,0x3419)}),
 'dev-openclose': ('dev.openclose.recovery.asm','dev.asm',0x475e,0x47df,{
     'SAVE_USER_WORLD':(0x475f,0x486),'RESTORE_USER_WORLD':(0x47da,0x46f),
     'DEVIOCALL2':(0x47b6,0x47e2),'CHARHARD':(0x47cf,0x5479)}),
 'create-error': ('create.error.recovery.asm','create.asm',0x2bd9,0x2be8,{}),
 'share': ('share.recovery.asm','share.asm',0x7558,0x75aa,{
     'HARDERR':(0x7577,0x54aa),'IDLE':(0x759e,0x124c)}),
 'fastopen': ('fastopen.recovery.asm','delete.asm',0x27bb,None,{}),
 'allocate': ('allocate.recovery.asm','rom.asm',0x4fb6,0x5069,{
     'UNPACK':(0x4fba,0x56e5),'PACK':(0x4ff0,0x5739),'RELBLKS':(0x5049,0x506b)}),
 'mknode': ('mknode.recovery.asm','mknode.asm',0x4a3a,None,{'GETEOF': (19029, 20629), 'ALLOCATE': (19037, 20407), 'SETDIRSRCH': (19050, 16396), 'ISEOF': (19068, 22222), 'FASTOPEN_UPDATE': (19093, 10218), 'FIGREC': (19103, 20363), 'GETBUFFR': (19122, 23307), 'INC_DIRTY_COUNT': (19164, 23830), 'GETPATHNOSET': (19241, 16503), 'MATCHATTRIBUTES': (19330, 17200), 'SHAREENTER': (19353, 30088), 'FLUSHBUF': (19442, 23562), 'ECRITDISK': (19454, 4950), 'SHAREEND': (19464, 30083), 'LCRITDISK': (19473, 4982), 'GETENT': (19516, 16349), 'DATE16': (19576, 2801), 'DEV_OPEN_SFT': (19649, 18270), 'RELEASE': (19876, 20585), 'SET_BUF_AS_DIR': (19901, 14378), 'DEV_CLOSE_SFT': (19935, 18278)}),
 'release': ('release.recovery.asm','rom.asm',0x5068,0x50a7,{
     'UNPACK':(0x506b,0x56e5),'PACK':(0x5075,0x5739),'ISEOF':(0x508f,0x56ce)}),
 'dircall': ('dircall.full.recovery.asm','dircall.asm',0x31f6,0x33ff,{
     'TESTNET':(0x31f6,0x1291),'LCRITDISK':(0x3205,0x1376),
     'SET_MKND_ERR':(0x320c,0x2bd9),'ECRITDISK':(0x320f,0x1356),
     'MAKENODE':(0x3224,0x4b1a),'NEWDIR':(0x324a,0x4a4d),
     'GETENT':(0x324f,0x3fdd),'INC_DIRTY_COUNT':(0x325f,0x5d16),
     'SETDOTENT':(0x3271,0x4af6),'GETBUFFR':(0x328b,0x5b0b),
     'FLUSHBUF':(0x32bc,0x5c0a),'GETPATH':(0x3321,0x4071),
     'STARTSRCH':(0x338e,0x431c),'GETENTRY':(0x3391,0x3fda),
     'SRCH':(0x33bd,0x3ed7),'RELEASE':(0x33d1,0x5069),
     'FASTOPEN_DELETE':(0x33f8,0x27bb)}),
 'time': ('time.recovery.asm','time.asm',0xa5c,0xc3f,{
     'GET_USER_STACK':(0xa68,0x4a5),'SETREAD':(0xacf,0x485e),
     'DEVIOCALL2':(0xad7,0x47e2),'SETWRITE':(0xadc,0x4891)}),
 'figrec': ('figrec.recovery.asm','rom.asm',0x4f8b,None,{}),
 'dirread': ('disk.dirread.recovery.asm','disk.asm',0x37c4,0x3837,{
     'UNPACK':(0x3805,0x56e5),'ISEOF':(0x380c,0x56ce),
     'FIGREC':(0x381b,0x4f8b),'GETBUFFR':(0x3825,0x5b0b)}),
 'dir': ('dir.recovery.asm','dir.asm',0x3ec0,0x4071,{
     'STARTSRCH':(0x3ec0,0x431c),'MATCHATTRIBUTES':(0x3f58,0x4330),
     'ISEOF':(0x3f9f,0x56ce),'FIRSTCLUSTER':(0x3fd3,0x381e),
     'DIRREAD':(0x3ff8,0x37c5),'UNPACK':(0x4025,0x56e5),'FIGREC':(0x4038,0x4f8b)}),
 'fastpath': ('fastpath.recovery.asm','dir2.asm',0x44ce,None,{'MATCHATTRIBUTES':(0x451b,0x4330)}),
 'getpath': ('getpath.recovery.asm','dir2.asm',0x4071,0x43cb,{
     'SETDIRSRCH':(0x413c,0x400c),'GETLET':(0x4153,0x51e5),
     'PATHCHRCMP':(0x415a,0x523b),'SETROOTSRCH':(0x4177,0x404c),
     'LOOKUPPATH':(0x422a,0x44ce),'FINDENTRY':(0x422f,0x3ec0),
     'GETBUFFR':(0x42b5,0x5b0b),'SET_BUF_AS_DIR':(0x42c3,0x382a),
     'INSERTPATH':(0x42cf,0x4572),'DATE16':(0x43af,0xaf1)}),
 'validatecds': ('validatecds.recovery.asm','dir2.asm',0x43cb,0x4489,{
     'ECRITDISK':(0x43df,0x1356),'LCRITDISK':(0x447f,0x1376),
     'FSTRCPY':(0x43f5,0x1224),'SPLICE':(0x43fd,0x6fef),
     'FATREAD_CDS':(0x440b,0x5899),'DOS_CHDIR':(0x4439,0x32f6)}),
 'fat': ('fat.recovery.asm','fat.asm',0x56ce,0x5aa6,{
     'FATAL':(0x572e,0x54f8),'INC_DIRTY_COUNT':(0x5779,0x5d16),
     'GETBUFFRB':(0x57ad,0x5b0d),'GOTDPB':(0x5892,0x60b),
     'FATAL1':(0x5904,0x54fc),'DEVIOCALL2':(0x5938,0x47e2),
     'HARDERR':(0x5997,0x54aa),'GETCURHEAD':(0x59ab,0x5aa6),
     'SCANPLACE':(0x59e3,0x5ab8),'BUFWRITE':(0x5a2c,0x5c75),
     '$SETDPB':(0x5a88,0xff9)}),
 'crit': ('crit.recovery.asm','crit.asm',0x1356,0x13d6,{}),
 'dev-io': ('dev.io.recovery.asm','dev.asm',0x47df,None,{'ECRITDEVICE':(0x47e2,0x1396),'LCRITDEVICE':(0x485a,0x13b6)}),
 'buf': ('buf.recovery.asm','buf.asm',0x5aa6,0x5d2a,{'FATSECRD':(0x5b91,0x3837),'DREAD':(0x5b98,0x3863),'DWRITE':(0x5cea,0x38c5)}),
 'disk-read': ('disk.read.recovery.asm','disk.asm',0x3836,0x387e,{'DSKREAD':(0x3855,0x38b5),'HARDERRRW':(0x386e,0x390d)}),
 'disk2-io': ('disk2.io.recovery.asm','disk2.asm',0x38b5,0x3927,{'SETREAD':(0x38c0,0x485e),'SETWRITE':(0x38e9,0x4891),'DEVIOCALL2':(0x38f4,0x47e2),'HARDERR':(0x3923,0x54aa)}),
}
filename,reference_name,target_start,target_end,code_symbols=configs[args.module]
source = root / 'dos' / filename
reference = root.parent / 'v6.0/dos' / reference_name
header_snapshot = {str(p.relative_to(root)):sha(p) for directory in ('dos','inc')
                   for p in (root / directory).rglob('*.inc')}
stage = Path(tempfile.mkdtemp(prefix=args.module+'-recovery-', dir=root / 'extras/build'))
shutil.copyfile(source, stage / 'buf.asm')
comparison_headers={}
if args.module in ('macro2-full','util-full','srvcall-full','alloc-full','macro-full','cpmio-full','msdisp-full','cpmio2-full','msctrlc-full','mscode-full','ioctl-full','dircall','mknode','allocate','share','dev-iofunc','disk-full','disk2-full','disk3-full','rom-full','close-full','delete-full','rename-full','create-full','open-full','abort-full','init-sft','handle-full','file-full','fcbio2-full','fcbio-full'):
    sf_reference=root.parent/'v6.0/inc/sf.inc'
    shutil.copyfile(sf_reference,stage/'sf.inc')
    comparison_headers[str(sf_reference)]=sha(sf_reference)

if args.module in ('fcbio2-full','fcbio-full'):
    fcb_reference=root.parent/'v6.0/inc/cpmfcb.inc'
    shutil.copyfile(fcb_reference,stage/'cpmfcb.inc')
    comparison_headers[str(fcb_reference)]=sha(fcb_reference)

tool = Path(r'O:\repos.hobby\ntvdm64\tools\opennt\tools16\masm.exe')
command = [str(tool), '-Mx', '-t', '-W1', '-I.',
           *['-I'+os.path.relpath(root / d, stage) for d in ('dos','extras/research/inc/kernel','inc','extras/research/inc/ntvdm')],
           'buf.asm,buf.obj,buf.lst;']
run = subprocess.run(command, cwd=stage, capture_output=True, timeout=30)
(stage / 'buf.log').write_bytes(run.stdout + run.stderr)
assert run.returncode == 0, (run.stdout + run.stderr).decode(errors='replace')
if target_end is None:
    raw=(stage/'buf.obj').read_bytes();pos=0
    while pos<len(raw):
        kind=raw[pos];length=int.from_bytes(raw[pos+1:pos+3],'little')
        if kind==0x98:
            assert raw[pos+3] & 2 == 0
            target_end=target_start+int.from_bytes(raw[pos+4:pos+6],'little')
            break
        pos+=3+length
    assert target_end is not None
build = json.loads((e / 'm4-t5-cds-harderr-build.json').read_text())
map_path = Path(build['stage']) / 'ntdos.map'
assert sha(map_path) == build['map_sha256']
mapping = map_path.read_text()
data_segment = re.search(r'^\s*([0-9A-F]{4}):[0-9A-F]{4}\s+BufferQueue\b', mapping, re.M)[1]
data_symbols = {m[2].lower(): int(m[1],16) for m in re.finditer(
    r'^\s*'+data_segment+r':([0-9A-F]{4})\s+(\S+)', mapping, re.M)}
# Audited E8 sites in the target BUF identify these three callees. Their
# source-name attribution comes from corresponding DOS 6 invoke statements.
target_media = Path(r'E:\core\collection\systems\x86_16_dos\msdos_5xx\msdos500_boot.img')
target_copy = root / 'extras/build/target-kernel-inspect.bin'
try:
    target = read_root_file(target_media, 'MSDOS.SYS')
    target_source = str(target_media)
except OSError:
    target = target_copy.read_bytes()
    target_source = str(target_copy)
assert hashlib.sha256(target).hexdigest() == '4e41ca4e5893d4cf293f81ad01adbdbd12f7039534f59148214a9cca309529a2'
code_origin = 0x3dd0
for site, destination in code_symbols.values():
    if args.module=='cpmio-full' and site in (0x147e,0x149d):
        assert target[site:site+3]==bytes.fromhex('2e3a06')
        assert int.from_bytes(target[site+3:site+5],'little')==code_origin+destination
        continue
    if args.module=='msdisp-full' and site==0x40d:
        assert target[site:site+3]==bytes.fromhex('2e8b9f')
        assert int.from_bytes(target[site+3:site+5],'little')==code_origin+destination
        continue
    if args.module=='msctrlc-full' and site in (0x542b,0x542e):
        prefix=bytes.fromhex('be') if site==0x542b else bytes.fromhex('2e8b1e')
        assert target[site:site+len(prefix)]==prefix
        assert int.from_bytes(target[site+len(prefix):site+len(prefix)+2],'little')==code_origin+destination
        continue
    if args.module=='mscode-full' and site in (0x697,0x7ba,0x913,0x918):
        prefix=bytes.fromhex('2eff36') if site in (0x913,0x918) else bytes.fromhex('be')
        assert target[site:site+len(prefix)]==prefix
        assert int.from_bytes(target[site+len(prefix):site+len(prefix)+2],'little')==code_origin+destination
        continue
    if args.module=='getset-full' and site in (0xd22,0xd29,0xd30,0xd37):
        assert target[site:site+3]==bytes.fromhex('2e3a16')
        assert int.from_bytes(target[site+3:site+5],'little')==code_origin+destination
        continue
    if args.module=='path-full' and site in (0x227b,0x22fd):
        assert target[site]==0xbe and int.from_bytes(target[site+1:site+3],'little')==code_origin+destination
        continue
    if args.module=='file-full' and site in (0x70e4,0x71b5,0x72a0):
        assert target[site]==0xb9
        assert int.from_bytes(target[site+1:site+3],'little')==code_origin+destination
        continue
    assert target[site] == (0xe9 if (args.module=='macro2-full' and site in (0x708d,0x7098)) or (args.module=='srvcall-full' and site in (0x673a,0x6772,0x67e4)) or (args.module=='alloc-full' and site in (0x64d7,0x65bc)) or (args.module=='macro-full' and site in (0x6bb2,0x6bb5)) or (args.module=='cpmio-full' and site==0x14c8) or (args.module=='cpmio2-full' and site==0x1826) or (args.module=='msctrlc-full' and site in (0x540c,0x5604)) or (args.module=='misc-full' and site in (0xf79,0x11f0)) or (args.module=='getset-full' and site in (0xce5,0xcf4,0xe45)) or (args.module=='ioctl-full' and site in (0x237f,0x23a2)) or (args.module=='path-full' and site in (0x21e3,0x2242)) or (args.module=='search-full' and site in (0x201c,0x208c,0x2113,0x2157)) or (args.module=='dircall' and site==0x320c) or (args.module=='disk-full' and site in (0x3427,0x34cc)) or (args.module=='disk2-full' and site==0x3a42) or (args.module=='disk3-full' and site in (0x3d55,0x3d58,0x3da2)) or (args.module=='lock-full' and site in (0x74b3,0x74f8)) or (args.module=='create-full' and site==0x2c1c) or (args.module=='handle-full' and site in (0x6928,0x692b)) or (args.module=='file-full' and site in (0x7184,0x71ae,0x71b1)) or (args.module=='fcbio-full' and site in (0x183e,0x1852)) else 0xe8)
    assert (site+3+int.from_bytes(target[site+1:site+3],'little',signed=True)) & 65535 == destination

# Earlier comparisons required a ReadOp override. The corrected production
# map must now provide the target value without any relocation substitution.
data_layout_differences = []
if args.module=='srvcall-full':
    assert data_symbols['iswin386']==0x100e
    assert int.from_bytes(target[0x6712:0x6714],'little')==0x1030
    data_layout_differences.append(dict(symbol='IsWin386',production=0x100e,target=0x1030,operand_site=0x6712,scope='Comparison-only physical DOSTAB placement'))
    data_symbols['iswin386']=0x1030
if args.module=='msdisp-full':
    for name,value in {'doshashma':0x1211,'iswin386':0x1030,'disa20_iret':0x112d}.items():
        assert name in data_symbols
        data_layout_differences.append(dict(symbol=name,production=data_symbols[name],target=value,scope='Comparison-only physical DOSTAB/LMSTUB placement'))
        data_symbols[name]=value
if args.module=='msctrlc-full':
    # Physical low-memory stubs and HMA flag are verified in the linked probe.
    for name,value in {'lowint23':0x10e7,'lowint24':0x10fb,'lowint28':0x110f,'doshashma':0x1211}.items():
        assert name in data_symbols
        data_layout_differences.append(dict(symbol=name,production=data_symbols[name],target=value,scope='Comparison-only physical LMSTUB placement'))
        data_symbols[name]=value
if args.module=='mscode-full':
    # Physical DOSTAB/LMSTUB placement established by linked probe proofs.
    placements={'win386_info':0xfe2,'umbsave1':0x121f,
                'vxdpath':0x1031,'iswin386':0x1030,'win386_dosvars':0x1022,
                'oldinstancejunk':0x11e7}
    for name,value in placements.items():
        assert name in data_symbols
        data_layout_differences.append(dict(symbol=name,production=data_symbols[name],target=value,scope='Comparison-only physical DOSTAB/LMSTUB placement'))
        data_symbols[name]=value
if args.module=='fcbio-full':
    sites={0x1a30:0,0x1a34:2,0x1a3a:0,0x1a77:0,0x1a7b:2,0x1ab8:0,0x1abe:2,0x1ac8:0,0x1acb:2,0x1ad6:0,0x1ada:2}
    assert data_symbols['localsft']==0x103b
    for site,addend in sites.items():
        assert int.from_bytes(target[site:site+2],'little')==0x105d+addend
    data_layout_differences.append(dict(symbol='LocalSFT',production=0x103b,target=0x105d,operand_sites=list(sites),scope='Comparison-only symbol placement'))
    data_symbols['localsft']=0x105d
if args.module=='fcbio2-full':
    assert target[0x1f48:0x1f52]==bytes.fromhex('36893e5d10368c065f10')
    assert data_symbols['localsft']==0x103b
    data_layout_differences.append(dict(symbol='LocalSFT',production=0x103b,
        target=0x105d,operand_sites=[0x1f4b,0x1f50],scope='Comparison-only symbol placement'))
    data_symbols['localsft']=0x105d
if args.module in ('disk-full','handle-full'):
    # Native DOS 5 console/handle tests name IsWin386. Its DOSDATA
    # placement still differs in the NT-derived production layout.
    iswin_site=0x347d if args.module=='disk-full' else 0x6b5f
    assert target[iswin_site:iswin_site+6] == bytes.fromhex('36f606301001')
    assert data_symbols['iswin386']==0x100e
    data_layout_differences.append(dict(symbol='IsWin386',production=0x100e,
        target=0x1030,operand_site=iswin_site+3,scope='Comparison-only symbol placement'))
    data_symbols['iswin386']=0x1030
if args.module in ('disk-read','disk2-io'):
    assert target[0x3868:0x386e] == bytes.fromhex('36c606750500')
    assert target[0x38ca:0x38d0] == bytes.fromhex('36c606750501')
    assert data_symbols['readop'] == 0x575, 'Production layout must match; no comparison override'

def index(b, p):
    if b[p] & 128:
        return ((b[p]&127)*256+b[p+1],p+2)
    return b[p],p+1

obj = (stage / 'buf.obj').read_bytes()
ext, names, segs, relocations = [], [], [], []
image = bytearray(target_end-target_start)
covered = set()
p = 0
while p < len(obj):
    kind = obj[p]; n = int.from_bytes(obj[p+1:p+3],'little')
    record = obj[p:p+3+n]; p += 3+n
    assert len(record) == n+3 and sum(record)%256 == 0
    b = record[3:-1]; i = 0
    if kind == 0x96:
        while i < len(b):
            n = b[i]; i += 1; names.append(b[i:i+n].decode()); i += n
    elif kind == 0x98:
        assert not b[0] & 2
        size = int.from_bytes(b[1:3],'little'); name, _ = index(b,3)
        segs.append((names[name-1],size))
    elif kind == 0x8c:
        while i < len(b):
            n=b[i]; i+=1; ext.append(b[i:i+n].decode()); i+=n; _,i=index(b,i)
    elif kind == 0xa0:
        seg,i=index(b,0); assert seg==1
        chunk_start=int.from_bytes(b[i:i+2],'little'); payload=b[i+2:]
        assert chunk_start+len(payload)<=len(image)
        positions=set(range(chunk_start,chunk_start+len(payload)))
        assert not covered & positions
        covered |= positions
        image[chunk_start:chunk_start+len(payload)] = payload
    elif kind == 0x9c:
        while i < len(b):
            loc=b[i]; off=((loc&3)<<8)+b[i+1]; flags=b[i+2]; i+=3
            if args.module=='msdisp-full' and ((loc>>2)&15)==0:
                assert loc==0xc0 and chunk_start+off in (0x9f,0xa9),(hex(loc),hex(chunk_start+off),hex(flags))
                frame,i=index(b,i);dest,i=index(b,i)
                assert flags==0x26 and frame==dest
                label=ext[dest-1].lower();assert (chunk_start+off,label) in ((0x9f,'maxcall'),(0xa9,'maxcom')),(hex(chunk_start+off),label)
                at=chunk_start+off
                assert at in covered
                value=0x24 if label=='maxcall' else 0x6c
                assert target[target_start+at-2:target_start+at+1]==(bytes.fromhex('80f924') if label=='maxcall' else bytes.fromhex('80fc6c'))
                image[at]=value
                relocations.append(dict(offset=at,symbol=label,displacement=0,relative=False,value=value,kind='byte_constant'))
                continue
            if args.module=='mscode-full' and ((loc>>2)&15)==3:
                assert loc==0xcc and chunk_start+off==0x261
                frame,i=index(b,i);dest,i=index(b,i)
                assert flags in (2,6) and ext[dest-1].lower()=='bios_i2f'
                disp=0
                if not flags&4:
                    disp=int.from_bytes(b[i:i+2],'little');i+=2
                at=chunk_start+off
                assert disp==0 and {at,at+1,at+2,at+3} <= covered
                assert target[target_start+at-1:target_start+at+4]==bytes.fromhex('ea05007000')
                image[at:at+4]=bytes.fromhex('05007000')
                relocations.append(dict(offset=at,symbol='bios_i2f',displacement=0,relative=False,value=5,segment=0x70,kind='far_pointer'))
                continue
            assert loc&128 and ((loc>>2)&15)==1, ('Only 16-bit OFFSET fixups supported',hex(loc),hex(chunk_start+off))
            assert flags in (0,2,4,6,0x26), ('Unsupported frame/target form',hex(flags),hex(loc),hex(off))
            frame,i=index(b,i); dest,i=index(b,i)
            disp=0
            if not flags&4:
                disp=int.from_bytes(b[i:i+2],'little');i+=2
            at=chunk_start+off
            assert {at,at+1} <= covered
            if flags&2:
                label=ext[dest-1]
                if args.module in ('time','lock-full','fcbio-full','path-full','getset-full','misc-full','mscode-full','msctrlc-full','msdisp-full','util-full') and label.lower()=='dosdseg':
                    assert frame==1 and flags in (2,6)
                    # Header word at DOSCODE:7 is the runtime DOSDATA segment.
                    assert target[3:5]==code_origin.to_bytes(2,'little')
                    assert target[target_start+at-3:target_start+at]==bytes.fromhex('2e8e16' if ((args.module=='mscode-full' and target_start+at in (0x521,0x5a8)) or (args.module=='msctrlc-full' and target_start+at==0x5436) or (args.module=='msdisp-full' and target_start+at==0x391)) else '2e8e06' if (args.module=='fcbio-full' and target_start+at in (0x1b02,0x1cd3)) or (args.module=='getset-full' and target_start+at==0xf3d) or (args.module=='msdisp-full' and target_start+at in (0x472,0x489)) or (args.module=='util-full' and target_start+at in (0x6840,0x6877)) else '2e8e1e'),(hex(target_start+at),target[target_start+at-3:target_start+at].hex())
                    assert int.from_bytes(target[target_start+at:target_start+at+2],'little')==code_origin+7
                    value=code_origin+7
                elif args.module=='mscode-full' and flags==0x26 and label.upper()=='VXDMESLEN':
                    assert frame==dest and target[target_start+at-1:target_start+at+2]==bytes.fromhex('b96300')
                    value=0x63
                elif flags==0x26:
                    assert frame==dest and label.upper() in code_symbols,(label,frame,dest)
                    value=code_origin+code_symbols[label.upper()][1]
                elif frame==3:
                    value=data_symbols[label.lower()]
                else:
                    assert frame==1 and label.upper() in code_symbols,(frame,label)
                    value=code_origin+code_symbols[label.upper()][1]
            else:
                assert frame==dest==1
                label='DOSCODE';value=code_origin+target_start
            value+=disp+int.from_bytes(image[at:at+2],'little')
            relative=not bool(loc&64)
            if relative:
                value-=code_origin+target_start+at+2
            image[at:at+2]=(value&65535).to_bytes(2,'little')
            relocations.append(dict(offset=at,symbol=label,displacement=disp,relative=relative,value=value&65535))
    else:
        assert kind in (0x80,0x88,0x90,0x9a,0x8a), hex(kind)
assert segs[0]==('DOSCODE',len(image)) and segs[2][0]=='DOSDATA',segs
assert covered==set(range(len(image)))
assert len({r['offset'] for r in relocations})==len(relocations)
assert all(sha(root/p)==digest for p,digest in header_snapshot.items())
expected=target[target_start:target_end]
differences=[dict(offset=i,candidate=a,target=b) for i,(a,b) in enumerate(zip(image,expected)) if a!=b]
(stage/'buf.resolved.bin').write_bytes(image)
out=dict(stage=str(stage),source=str(source),source_sha256=sha(source),tool_sha256=sha(tool),target_source=target_source,
         comparative_reference=str(reference),comparative_reference_sha256=sha(reference),
         local_header_inventory=header_snapshot,comparison_headers=comparison_headers,
         object_sha256=sha(stage/'buf.obj'),map_sha256=sha(map_path),command=command,exit=run.returncode,
         target_start=target_start,target_end=target_end,bytes=len(image),
         candidate_sha256=hashlib.sha256(image).hexdigest(),target_slice_sha256=hashlib.sha256(expected).hexdigest(),
         relocations=relocations,external_code_target_attributions=code_symbols,differences=differences,exact=not differences,
         data_layout_differences=data_layout_differences,
         scope='Bounded source object at target layout with explicit symbol relocations; external callees are addresses only. No integrated-kernel or runtime claim.')
(e / ('m4-t5-full-buf-verification.json' if args.module=='buf' else 'm4-t5-'+args.module+'-verification.json')).write_text(json.dumps(out,indent=2),encoding='utf-8')
print(json.dumps({k:v for k,v in out.items() if k not in ('relocations','local_header_inventory')},indent=2))
assert out['exact']


