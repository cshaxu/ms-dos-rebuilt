/* Product probe: create a new desktop and verify the child thread before start. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <string.h>

static int desktop_name(HDESK desk, char *name, DWORD size)
{
    DWORD needed = 0;
    return desk && GetUserObjectInformationA(desk, UOI_NAME, name, size, &needed);
}

static int start_owned_console(DWORD pid)
{
    FreeConsole();
    if (!AttachConsole(pid)) return 0;
    HANDLE input = CreateFileA("CONIN$", GENERIC_READ|GENERIC_WRITE,
        FILE_SHARE_READ|FILE_SHARE_WRITE, NULL, OPEN_EXISTING, 0, NULL);
    if (input == INVALID_HANDLE_VALUE) { FreeConsole(); return 0; }
    const char *command = "start\r";
    INPUT_RECORD records[12] = {0};
    for (int i = 0; i < 6; ++i) {
        records[2*i].EventType = KEY_EVENT;
        records[2*i].Event.KeyEvent.bKeyDown = TRUE;
        records[2*i].Event.KeyEvent.wRepeatCount = 1;
        records[2*i].Event.KeyEvent.uChar.AsciiChar = command[i];
        records[2*i].Event.KeyEvent.wVirtualKeyCode = command[i] == '\r' ? VK_RETURN : (WORD)(command[i]-32);
        records[2*i+1] = records[2*i];
        records[2*i+1].Event.KeyEvent.bKeyDown = FALSE;
    }
    DWORD written = 0;
    BOOL ok = WriteConsoleInputA(input, records, 12, &written);
    CloseHandle(input); FreeConsole();
    return ok && written == 12;
}

static int check_desktop_with_canary(const char *name)
{
    char executable[MAX_PATH], command[2*MAX_PATH], result[512] = {0};
    if (!GetModuleFileNameA(NULL, executable, sizeof(executable))) return 0;
    SECURITY_ATTRIBUTES sa = {sizeof(sa), NULL, TRUE}; HANDLE rd, wr;
    if (!CreatePipe(&rd, &wr, &sa, 0) || !SetHandleInformation(rd, HANDLE_FLAG_INHERIT, 0)) return 0;
    snprintf(command, sizeof(command), "\"%s\" --self-check %s", executable, name);
    STARTUPINFOA si = {0}; PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si); si.lpDesktop = (LPSTR)name; si.dwFlags = STARTF_USESTDHANDLES;
    si.hStdOutput = wr; si.hStdError = wr; si.hStdInput = GetStdHandle(STD_INPUT_HANDLE);
    if (!CreateProcessA(executable, command, NULL, NULL, TRUE, CREATE_NO_WINDOW, NULL, NULL, &si, &pi)) return 0;
    CloseHandle(wr); CloseHandle(pi.hThread);
    DWORD wait = WaitForSingleObject(pi.hProcess, 10000);
    if (wait != WAIT_OBJECT_0) { TerminateProcess(pi.hProcess, 124); WaitForSingleObject(pi.hProcess, 5000); }
    DWORD count = 0; ReadFile(rd, result, sizeof(result)-1, &count, NULL);
    DWORD code = 0; GetExitCodeProcess(pi.hProcess, &code);
    CloseHandle(rd); CloseHandle(pi.hProcess);
    printf("desktop-canary=%s exit=%lu timeout=%d\n", result, code, wait != WAIT_OBJECT_0); fflush(stdout);
    return wait == WAIT_OBJECT_0 && code == 0 && !strcmp(result, name);
}

int main(int argc, char **argv)
{
    char name[96], parent_name[128], actual[128], child_name[128];
    if (argc != 3) return 2;
    if (!strcmp(argv[1], "--self-check")) {
        if (!desktop_name(GetThreadDesktop(GetCurrentThreadId()), actual, sizeof(actual))) return 10;
        if (lstrcmpiA(actual, argv[2])) return 11;
        fputs(actual, stdout); fflush(stdout); return 0;
    }
    if (!desktop_name(GetThreadDesktop(GetCurrentThreadId()), parent_name, sizeof(parent_name))) return 3;
    snprintf(name, sizeof(name), "DOS5Product_%lu_%llu", GetCurrentProcessId(), (unsigned long long)GetTickCount64());
    HDESK existing = OpenDesktopA(name, 0, FALSE, DESKTOP_READOBJECTS);
    if (existing) { CloseDesktop(existing); return 4; }
    if (GetLastError() != ERROR_FILE_NOT_FOUND) return 4;
    HDESK desktop = CreateDesktopA(name, NULL, NULL, 0,
        DESKTOP_CREATEWINDOW|DESKTOP_READOBJECTS|DESKTOP_WRITEOBJECTS, NULL);
    if (!desktop || !desktop_name(desktop, actual, sizeof(actual)) ||
        lstrcmpiA(actual, name) || !lstrcmpiA(actual, parent_name)) return 5;
    if (!check_desktop_with_canary(name)) { CloseDesktop(desktop); return 9; }
    HANDLE job = CreateJobObjectA(NULL, NULL);
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {0};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!job || !SetInformationJobObject(job, JobObjectExtendedLimitInformation, &limits, sizeof(limits))) return 6;
    STARTUPINFOA si = {0}; PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si); si.lpDesktop = name;
    if (!CreateProcessA(argv[1], NULL, NULL, NULL, FALSE, CREATE_SUSPENDED|CREATE_NEW_CONSOLE,
                        NULL, argv[2], &si, &pi)) return 7;
    BOOL assigned = AssignProcessToJobObject(job, pi.hProcess);
    DWORD assign_error = assigned ? 0 : GetLastError();
    if (!assigned) {
        printf("job-assignment-failed error=%lu\n", assign_error);
        fflush(stdout);
        TerminateProcess(pi.hProcess, 8); WaitForSingleObject(pi.hProcess, 5000); return 8;
    }
    printf("parent-desktop=%s isolated-desktop=%s owned-pid=%lu\n", parent_name, actual, pi.dwProcessId); fflush(stdout);
    ResumeThread(pi.hThread);
    DWORD wait = WaitForSingleObject(pi.hProcess, 1000);
    BOOL named = desktop_name(GetThreadDesktop(pi.dwThreadId), child_name, sizeof(child_name));
    if (!named || lstrcmpiA(child_name, name)) {
        printf("product-desktop-unverified name=%s; terminating owned job\n", named ? child_name : "unavailable"); fflush(stdout);
        TerminateJobObject(job, 8); WaitForSingleObject(pi.hProcess, 5000); return 8;
    }
    printf("product-thread-desktop=%s\n", child_name); fflush(stdout);
    CloseHandle(pi.hThread);
    if (wait == WAIT_TIMEOUT) wait = WaitForSingleObject(pi.hProcess, 4000);
    if (wait == WAIT_TIMEOUT) {
        printf("owned-console-start=%d\n", start_owned_console(pi.dwProcessId)); fflush(stdout);
        for (int i = 0; i < 5 && wait == WAIT_TIMEOUT; ++i)
            wait = WaitForSingleObject(pi.hProcess, 5000);
    }
    if (wait == WAIT_TIMEOUT) { TerminateJobObject(job, 124); WaitForSingleObject(pi.hProcess, 5000); }
    DWORD code = 0; GetExitCodeProcess(pi.hProcess, &code);
    printf("product-exit=%lu bounded-stop=%d\n", code, wait == WAIT_TIMEOUT); fflush(stdout);
    CloseHandle(pi.hProcess); CloseHandle(job); CloseDesktop(desktop);
    return wait == WAIT_TIMEOUT ? 0 : (int)code;
}
