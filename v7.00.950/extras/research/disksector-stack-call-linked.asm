sysinitseg segment para public 'code'
 assume cs:sysinitseg,ds:nothing
 org 39c5h
 call stackinit
 push cs
 pop ds
 call relocate_disksector
 org 3c1bh
relocate_disksector proc near
 ret
relocate_disksector endp
 org 3d0eh
stackinit proc near
 ret
stackinit endp
sysinitseg ends
end
