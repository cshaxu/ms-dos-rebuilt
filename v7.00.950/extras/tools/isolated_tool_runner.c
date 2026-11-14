/* Bounded GUI tool execution on a private desktop, with no desktop input. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>
#include <stdarg.h>
#include <string.h>

static FILE *host_log;

static void report(const char *format, ...)
{
    va_list args;
    va_start(args, format);
    vprintf(format, args);
    va_end(args);
    fflush(stdout);
    if (host_log) {
        va_start(args, format);
        vfprintf(host_log, format, args);
        va_end(args);
        fflush(host_log);
    }
}

static void progress(const char *directory, unsigned seconds)
{
    char path[MAX_PATH], phase[160] = "Waiting for DOS build status";
    snprintf(path, sizeof(path), "%s\\progress.txt", directory);
    FILE *file = fopen(path, "r");
    if (file) {
        if (!fgets(phase, sizeof(phase), file))
            strcpy(phase, "Waiting for DOS build status");
        fclose(file);
    }
    phase[strcspn(phase, "\r\n")] = 0;
    report("[compile %us] %s\n", seconds, phase);
}

int main(int argc, char **argv)
{
    if (argc != 4)
        return 2; /* executable, working directory, mutable command line */

    char log_path[MAX_PATH];
    snprintf(log_path, sizeof(log_path), "%s\\host.log", argv[2]);
    host_log = fopen(log_path, "w");
    if (!host_log) {
        report("Cannot create host log: %s\n", log_path);
        return 7;
    }

    char name[96];
    snprintf(name, sizeof(name), "DOS5Build_%lu_%llu",
             GetCurrentProcessId(), (unsigned long long)GetTickCount64());
    HDESK desk = CreateDesktopA(name, NULL, NULL, 0,
                               DESKTOP_CREATEWINDOW | DESKTOP_READOBJECTS |
                               DESKTOP_WRITEOBJECTS, NULL);
    if (!desk) {
        report("CreateDesktop error=%lu\n", GetLastError());
        return 3;
    }

    HANDLE job = CreateJobObjectA(NULL, NULL);
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits = {0};
    limits.BasicLimitInformation.LimitFlags = JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!job || !SetInformationJobObject(job, JobObjectExtendedLimitInformation,
                                        &limits, sizeof(limits)))
        return 4;

    STARTUPINFOA si = {0};
    PROCESS_INFORMATION pi = {0};
    si.cb = sizeof(si);
    si.lpDesktop = name;
    if (!CreateProcessA(argv[1], argv[3], NULL, NULL, FALSE,
                        CREATE_SUSPENDED | CREATE_NEW_CONSOLE, NULL,
                        argv[2], &si, &pi)) {
        report("CreateProcess error=%lu\n", GetLastError());
        CloseHandle(job);
        CloseDesktop(desk);
        return 5;
    }
    if (!AssignProcessToJobObject(job, pi.hProcess)) {
        TerminateProcess(pi.hProcess, 6);
        WaitForSingleObject(pi.hProcess, 5000);
        CloseHandle(pi.hThread);
        CloseHandle(pi.hProcess);
        CloseHandle(job);
        CloseDesktop(desk);
        return 6;
    }

    report("private-desktop=%s owned-pid=%lu\n", name, pi.dwProcessId);
    fflush(stdout);
    ResumeThread(pi.hThread);
    CloseHandle(pi.hThread);

    DWORD wait = WAIT_TIMEOUT;
    progress(argv[2], 0);
    for (int i = 0; i < 12 && wait == WAIT_TIMEOUT; i++) {
        wait = WaitForSingleObject(pi.hProcess, 5000);
        if (wait == WAIT_TIMEOUT)
            progress(argv[2], (unsigned)(i + 1) * 5);
    }
    DWORD code = 0;
    if (wait != WAIT_OBJECT_0) {
        TerminateJobObject(job, 124);
        WaitForSingleObject(pi.hProcess, 5000);
        code = 124;
    } else
        GetExitCodeProcess(pi.hProcess, &code);
    report("child-exit=%lu timeout=%d\n", code, wait == WAIT_TIMEOUT);

    CloseHandle(pi.hProcess);
    CloseHandle(job);
    CloseDesktop(desk);
    return (int)code;
}
