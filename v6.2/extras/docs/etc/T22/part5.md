# T22 S1: files 222 through 225

No same-name source exists under the original v6.0 tree for these four inputs.
They are accepted_no_reference, not accepted_exact and not a claim of original
Microsoft text recovery. Only DOS6 source consumers, macros and skeletons were
used to judge structure; no other DOS version was consulted.

222. comimsg.inc: initialization messages use the original resmsg.equ msg macro
    (length byte, text, exported label), CR/LF equates and RESGROUP pointer list.
    DOS6 COMMAND makefile explicitly requires this language include; INIT uses
    HelpMsgs. Preserve 6.20 banner, /Y help, punctuation and pointer order as
    target data. No defensible original-source replacement exists. Retain the
    existing EOF bytes rather than invent a speculative canonical text.
223. comrmsg.inc: uses the same msg macro, original resident include boundary
    and DATARES error pointer lists. Critical/extended error messages share
    labels rather than duplicate storage; null pointer slots preserve error
    number indexing. DataResEnd/ExtMsgEnd preserve /MSG boundaries. No edit.
224. usa-ms-command.msg: reviewed the COMMON, EXTEND, PARSE and COMMAND records,
    message continuations and all help records. Retain original message-tool
    record format, IDs and continuation lines. Original command.skl and
    tranmsg.asm define the consuming interfaces. Added batch/COPY messages and
    exact spacing are target data; placeholders and repeated text serve
    separate indexed messages and must not be collapsed. No edit.
225. usa-ms-dos.msg: reviewed all MSBIO, MSDOS and BOOT records. Original
    msbio.skl/msdos.skl/boot skeletons establish class and message use. Preserve
    6.20 startup/menu text, F8 AUTOEXEC prompt and exact OEM box bytes. Changing
    these to DOS6 skeleton fallback wording would change output. No edit.

The last accepted clean build used all four current inputs verbatim. The final
checker compares every one of the 225 source inputs with that build's source
copy; all match. Thus no redundant rebuild is needed for these unchanged files.
