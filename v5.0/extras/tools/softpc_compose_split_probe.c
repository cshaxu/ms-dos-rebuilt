/* Split the headless machine/audio setup for diagnosis; never run the CPU. */
#include "app-softpc/product/config.h"
#include "app-softpc/machine/machine.h"
#include "app-softpc/compat/audio.h"
#include <stdio.h>

int main(int argc, char **argv)
{
    if (argc != 2) return 2;
    app_startup_config config = { {0}, {0}, {0}, {0}, 16u * 1024u * 1024u,
        EMULATOR_SESSION_DISPLAY_CONSOLE, 1, LIB_STORAGE_MEDIUM_OVERLAY,
        LIB_STORAGE_MEDIUM_OVERLAY };
    if (!app_load_startup_config(argv[1], &config) ||
        !app_resolve_image_path(config.floppy_path, argv[1]) ||
        !app_resolve_image_path(config.hard_disk_path, argv[1]) ||
        !app_resolve_image_path(config.serial_output_path, argv[1]) ||
        !app_resolve_image_path(config.printer_output_path, argv[1])) return 3;
    softpc_machine_options options = {0};
    options.floppy_path = config.floppy_path[0] ? config.floppy_path : NULL;
    options.hard_disk_path = config.hard_disk_path[0] ? config.hard_disk_path : NULL;
    options.serial_output_path = config.serial_output_path[0] ? config.serial_output_path : NULL;
    options.printer_output_path = config.printer_output_path[0] ? config.printer_output_path : NULL;
    options.memory_bytes = config.memory_bytes;
    options.floppy_mode = config.floppy_mode;
    options.hard_disk_mode = config.hard_disk_mode;
    softpc_machine *machine = NULL;
    softpc_machine_result result = softpc_machine_create(&options, &machine);
    printf("machine-create=%d\n", (int)result); fflush(stdout);
    if (result != SOFTPC_MACHINE_OK) return 4;
    lib_status audio = softpc_platform_audio_start();
    printf("audio-start=%d\n", (int)audio); fflush(stdout);
    lib_status audio_stop = softpc_platform_audio_shutdown();
    printf("audio-stop=%d\n", (int)audio_stop); fflush(stdout);
    result = softpc_machine_destroy(machine);
    printf("machine-destroy=%d\n", (int)result);
    return audio == LIB_STATUS_OK && audio_stop == LIB_STATUS_OK && result == SOFTPC_MACHINE_OK ? 0 : 5;
}
