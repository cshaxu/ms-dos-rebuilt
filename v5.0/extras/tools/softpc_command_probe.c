/* Headless machine probe: no product UI or host input injection. */
#include "machine_fixture.h"
#include <windows.h>
#include <stdio.h>

int main(int argc, char **argv)
{
    softpc_machine_options options = {0};
    softpc_machine *core = NULL;
    softpc_machine_fixture fixture = {0};
    unsigned char screen[4000] = {0};
    lib_u16 cs = 0; lib_u32 ip = 0;
    if (argc != 2) return 2;
    options.floppy_path = argv[1];
    options.memory_bytes = 16u*1024u*1024u;
    options.floppy_mode = LIB_STORAGE_MEDIUM_DIRECT;
    options.hard_disk_mode = LIB_STORAGE_MEDIUM_READONLY;
    int result = softpc_machine_create(&options, &core);
    printf("create=%d\n", result); fflush(stdout);
    if (result != SOFTPC_MACHINE_OK) return 3;
    if (!softpc_machine_fixture_create(core, &fixture)) return 4;
    if (!emulator_machine_start(fixture.machine)) return 5;
    printf("started state=%d\n", emulator_machine_state_get(fixture.machine)); fflush(stdout);
    Sleep(15000);
    printf("state-before-stop=%d\n", emulator_machine_state_get(fixture.machine));
    if (!emulator_machine_stop(fixture.machine)) return 6;
    softpc_machine_instruction_pointer(core, &cs, &ip);
    printf("stopped CS:IP=%04x:%08lx\n", (unsigned)cs, (unsigned long)ip);
    result = softpc_machine_read_physical(core, 0xb8000, screen, sizeof(screen));
    printf("video-read=%d\n", result);
    for (unsigned row=0; row<25; ++row) {
        for (unsigned col=0; col<80; ++col) {
            unsigned char ch = screen[(row*80+col)*2];
            putchar(ch>=32 && ch<127 ? ch : ' ');
        }
        putchar('\n');
    }
    softpc_machine_fixture_destroy(&fixture);
    softpc_machine_destroy(core);
    return 0;
}
