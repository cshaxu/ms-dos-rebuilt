/* Diagnostic only: parse a disposable config and compose/destroy the machine.
 * No session, UI, CPU execution, product process, or host input is started. */
#include "app-softpc/product/config.h"
#include "app-softpc/product/composed_machine.h"
#include <stdio.h>

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    app_startup_config config = { {0}, {0}, {0}, {0}, 16u * 1024u * 1024u,
        EMULATOR_SESSION_DISPLAY_CONSOLE, 1, LIB_STORAGE_MEDIUM_OVERLAY,
        LIB_STORAGE_MEDIUM_OVERLAY };
    if (!app_load_startup_config(argv[1], &config)) { puts("config=fail"); return 3; }
    puts("config=ok");
    if (!app_resolve_image_path(config.floppy_path, argv[1]) ||
        !app_resolve_image_path(config.hard_disk_path, argv[1]) ||
        !app_resolve_image_path(config.serial_output_path, argv[1]) ||
        !app_resolve_image_path(config.printer_output_path, argv[1])) {
        puts("paths=fail"); return 4;
    }
    puts("paths=ok");
    x86_ibmpc_product_ui_options ui;
    lib_status status = app_startup_compose_ui(&config, &ui);
    printf("ui-options=%d\n", (int)status);
    if (status != LIB_STATUS_OK) return 5;
    emulator_product_machine machine = {0};
    status = softpc_product_compose_machine(&config, &machine);
    printf("machine-compose=%d\n", (int)status);
    if (status != LIB_STATUS_OK) return 6;
    status = machine.destroy(machine.machine);
    printf("machine-destroy=%d\n", (int)status);
    return status == LIB_STATUS_OK ? 0 : 7;
}
