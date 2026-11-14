sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:sysinitseg
 org 2af1h
check_time:
 mov al,[secTimeOut]
 sub al,[secElapsed]
 jae show_time
 or byte ptr [query_mode_flags],10h
 mov byte ptr [secElapsed],0
 jmp select_done
show_time:
 ret
 org 2c40h
select_done:
 ret
 org 3375h
query_mode_flags db 0
 org 337bh
secTimeOut db 0
secElapsed db 0
sysinitseg ends
end
