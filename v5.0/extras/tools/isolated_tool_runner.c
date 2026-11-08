/* Bounded GUI tool execution on a private desktop, with no desktop input. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <stdio.h>

int main(int argc,char **argv)
{
    if (argc!=4) return 2; /* executable, working directory, mutable command line */
    char name[96];snprintf(name,sizeof(name),"DOS5Build_%lu_%llu",GetCurrentProcessId(),(unsigned long long)GetTickCount64());
    HDESK desk=CreateDesktopA(name,NULL,NULL,0,DESKTOP_CREATEWINDOW|DESKTOP_READOBJECTS|DESKTOP_WRITEOBJECTS,NULL);
    if (!desk) {printf("CreateDesktop error=%lu\n",GetLastError());return 3;}
    HANDLE job=CreateJobObjectA(NULL,NULL);
    JOBOBJECT_EXTENDED_LIMIT_INFORMATION limits={0};
    limits.BasicLimitInformation.LimitFlags=JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE;
    if (!job || !SetInformationJobObject(job,JobObjectExtendedLimitInformation,&limits,sizeof(limits))) return 4;
    STARTUPINFOA si={0}; PROCESS_INFORMATION pi={0};si.cb=sizeof(si);si.lpDesktop=name;
    if (!CreateProcessA(argv[1],argv[3],NULL,NULL,FALSE,CREATE_SUSPENDED|CREATE_NEW_CONSOLE,NULL,argv[2],&si,&pi)) {
        printf("CreateProcess error=%lu\n",GetLastError());CloseHandle(job);CloseDesktop(desk);return 5;
    }
    if (!AssignProcessToJobObject(job,pi.hProcess)) {
        TerminateProcess(pi.hProcess,6);WaitForSingleObject(pi.hProcess,5000);
        CloseHandle(pi.hThread);CloseHandle(pi.hProcess);CloseHandle(job);CloseDesktop(desk);return 6;
    }
    printf("private-desktop=%s owned-pid=%lu\n",name,pi.dwProcessId);fflush(stdout);
    ResumeThread(pi.hThread);CloseHandle(pi.hThread);
    DWORD wait=WAIT_TIMEOUT;
    for(int i=0;i<12 && wait==WAIT_TIMEOUT;i++) wait=WaitForSingleObject(pi.hProcess,5000);
    DWORD code=0;
    if(wait!=WAIT_OBJECT_0) {TerminateJobObject(job,124);WaitForSingleObject(pi.hProcess,5000);code=124;}
    else GetExitCodeProcess(pi.hProcess,&code);
    printf("child-exit=%lu timeout=%d\n",code,wait==WAIT_TIMEOUT);
    CloseHandle(pi.hProcess);CloseHandle(job);CloseDesktop(desk);
    return (int)code;
}
