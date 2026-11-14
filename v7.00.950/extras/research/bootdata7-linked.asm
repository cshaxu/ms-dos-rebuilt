sysinitseg segment para public 'code'
 org 4060h
boot_delay      dw      2               ; startup delay in seconds
boot_menu       db      0               ; show startup menu
boot_menu_default db    1               ; default startup menu selection
boot_menu_delay db      30              ; startup menu timeout
                db      0               ; reserved
boot_safe       db      0               ; safe startup requested
boot_network    db      0               ; network startup requested
boot_config_name db     32 dup (0)      ; BOOTCONFIG selection
sysinitseg ends
end
