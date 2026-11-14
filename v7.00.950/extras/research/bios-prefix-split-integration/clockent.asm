; Clock entry placement experiment; not a production provider.
Bios_Code segment byte public 'Bios_Code'
        assume cs:Bios_Code
        extrn read_real_date:near,read_real_time:near
        public int6c_code,int6c_update
int6c_code proc far
        call int6c_update
        ret 2
int6c_code endp
int6c_update proc near
        call read_real_date
        call read_real_time
        mov ah,1
        int 1Ah
        ret
int6c_update endp
Bios_Code ends
        end
