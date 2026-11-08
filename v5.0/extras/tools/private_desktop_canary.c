/* Test desktop assignment with a harmless child; no GUI or input injection. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>

static int describe(DWORD tid, char *name, DWORD size, DWORD *error)
{
    DWORD needed = 0;
    SetLastError(0);
    HDESK desk = GetThreadDesktop(tid);
    if (!desk) { *error = GetLastError(); return 0; }
    SetLastError(0);
    if (!GetUserObjectInformationA(desk, UOI_NAME, name, size, &needed)) {
        *error = GetLastError(); return 0;
    }
    *error = 0; return 1;
}

int main(int argc, char **argv)
{
    char name[128] = {0}; DWORD error = 0;
    if (argc == 3 && !strcmp(argv[1], "--child")) {
        int ok = describe(GetCurrentThreadId(), name, sizeof(name), &error);
        printf("child-desktop-ok=%d error=%lu actual=%s expected=%s\n", ok, error, ok ? name : "unavailable", argv[2]);
        fflush(stdout);
        return ok && !lstrcmpiA(name, argv[2]) ? 0 : 10;
    }
    if (argc != 1) return 2;
    char private_name[96], executable[MAX_PATH], command[2*MAX_PATH] = {0};
    if (!describe(GetCurrentThreadId(), name, sizeof(name), &error)) return 3;
    snprintf(private_name, sizeof(private_name), "DOS5Canary_%lu_%llu", GetCurrentProcessId(), (unsigned long long)GetTickCount64());
    HDESK existing = OpenDesktopA(private_name, 0, FALSE, DESKTOP_READOBJECTS);
    if (existing) { CloseDesktop(existing); return 4; }
    if (GetLastError() != ERROR_FILE_NOT_FOUND) return 4;
    HDESK desktop = CreateDesktopA(private_name, NULL, NULL, 0,
        DESKTOP_CREATEWINDOW|DESKTOP_READOBJECTS|DESKTOP_WRITEOBJECTS, NULL);
    if (!desktop || !GetModuleFileNameA(NULL, executable, sizeof(executable))) return 5;
    SECURITY_ATTRIBUTES sa = {sizeof(sa), NULL, TRUE}; HANDLE rd, wr;
    if (!CreatePipe(&rd, &wr, &sa, 0) || !SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0)) return 6;
    snprintf(command, sizeof(command), "\"%s\" --child %s", executable, private_name);
    STARTUPINFOA si = {0}; PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si); si.lpDesktop = private_name; si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = wr; si.hStdError = wr; si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    if (!CreateProcessA(executable, command, NULL, NULL, TRUE, CREATE_SUSPENDED|CREATE_NO_WINDOW,
                        NULL, NULL, &si, &pi)) return 7;
    char child_name[128] = {0}; DWORD parent_error = 0;
    int parent_can_read = describe(pi.dwThreadId, child_name, sizeof(child_name), &parent_error);
    printf("parent-desktop=%s private-desktop=%s suspended-child-readable=%d error=%lu\n",
           name, private_name, parent_can_read, parent_error); fflush(stdout);
    ResumeThread(pi.hThread); CloseHandle(pi.hThread); CloseHandle(wr);
    DWORD wait = WaitForSingleObject(pi.hProcess, 10000);
    if (wait != WAIT_OBJECT_0) { TerminateProcess(pi.hProcess, 124); WaitForSingleObject(pi.hProcess, 5000); }
    char buffer[512]; DWORD count = 0;
    while (ReadFile(rd, buffer, sizeof(buffer)-1, &count, NULL) && count) {
        buffer[count] = 0; fputs(buffer, stdout);
    }
    DWORD code = 0; GetExitCodeProcess(pi.hProcess, &code);
    printf("child-exit=%lu timeout=%d\n", code, wait != WAIT_OBJECT_0);
    CloseHandle(rd); CloseHandle(pi.hProcess); CloseDesktop(desktop);
    return wait == WAIT_OBJECT_0 ? (int)code : 124;
}
