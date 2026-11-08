/* Product probe on a private desktop. Only its owned console receives start. */
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <tlhelp32.h>
#include <stdio.h>
#include <stdlib.h>

static DWORD owned_pid;
static HANDLE owned_process;
static int start_owned_console(void)
{
    /* Attach only to the child created on our private desktop. No global input. */
    FreeConsole();
    if (!AttachConsole(owned_pid)) return 0;
    HANDLE input=CreateFileA("CONIN$",GENERIC_READ|GENERIC_WRITE,
        FILE_SHARE_READ|FILE_SHARE_WRITE,NULL,OPEN_EXISTING,0,NULL);
    if (input==INVALID_HANDLE_VALUE) {FreeConsole();return 0;}
    const char *command="start\r"; INPUT_RECORD records[12]={0};
    for (int i=0;i<6;i++) {
        records[2*i].EventType=KEY_EVENT;
        records[2*i].Event.KeyEvent.bKeyDown=TRUE;
        records[2*i].Event.KeyEvent.wRepeatCount=1;
        records[2*i].Event.KeyEvent.uChar.AsciiChar=command[i];
        records[2*i].Event.KeyEvent.wVirtualKeyCode=command[i]=='\r'?VK_RETURN:(WORD)(command[i]-32);
        records[2*i+1]=records[2*i];records[2*i+1].Event.KeyEvent.bKeyDown=FALSE;
    }
    DWORD written=0;BOOL ok=WriteConsoleInputA(input,records,12,&written);
    CloseHandle(input);FreeConsole();return ok && written==12;
}
static void report_threads(void)
{
    HANDLE snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD,0);
    THREADENTRY32 entry={0};entry.dwSize=sizeof(entry);
    if (snapshot==INVALID_HANDLE_VALUE) return;
    if (Thread32First(snapshot,&entry)) do {
        if (entry.th32OwnerProcessID!=owned_pid) continue;
        HANDLE thread=OpenThread(THREAD_SUSPEND_RESUME|THREAD_GET_CONTEXT,FALSE,entry.th32ThreadID);
        if (!thread) continue;
        if (SuspendThread(thread)!=(DWORD)-1) {
            CONTEXT context={0};context.ContextFlags=CONTEXT_CONTROL;
            if (GetThreadContext(thread,&context)) {
                printf("thread=%lu rip=%llx\n",entry.th32ThreadID,(unsigned long long)context.Rip);
                unsigned long long stack[128]; SIZE_T read=0;
                if (ReadProcessMemory(owned_process,(void*)context.Rsp,stack,sizeof(stack),&read)) {
                    printf("stack-candidates:");
                    for (SIZE_T n=0;n<read/sizeof(stack[0]);n++)
                        if (stack[n]>0x100000000ULL) printf(" %llx",stack[n]);
                    printf("\n");
                }
            }
            ResumeThread(thread);
        }
        CloseHandle(thread);
    } while(Thread32Next(snapshot,&entry));
    CloseHandle(snapshot);
    snapshot=CreateToolhelp32Snapshot(TH32CS_SNAPMODULE,owned_pid);
    MODULEENTRY32 module={0};module.dwSize=sizeof(module);
    if (snapshot==INVALID_HANDLE_VALUE) return;
    if (Module32First(snapshot,&module)) do {
        printf("module=%s base=%p size=%lu\n",module.szModule,(void*)module.modBaseAddr,module.modBaseSize);
    } while(Module32Next(snapshot,&module));
    CloseHandle(snapshot);
}
static BOOL CALLBACK report_window(HWND window, LPARAM unused)
{
    DWORD pid=0; char title[512]={0}, cls[128]={0};
    (void)unused; GetWindowThreadProcessId(window,&pid);
    if (pid != owned_pid) return TRUE;
    GetWindowTextA(window,title,sizeof(title)); GetClassNameA(window,cls,sizeof(cls));
    printf("owned-window class=%s title=%s visible=%d\n",cls,title,IsWindowVisible(window));
    return TRUE;
}
int main(int argc,char **argv)
{
    char name[96], input_before[128]={0}, input_after[128]={0}, actual[128]={0};
    DWORD needed=0; STARTUPINFOA si={0}; PROCESS_INFORMATION pi={0};
    if (argc!=3) return 2;
    HDESK input=OpenInputDesktop(0,FALSE,DESKTOP_READOBJECTS);
    if (!input || !GetUserObjectInformationA(input,UOI_NAME,input_before,sizeof(input_before),&needed)) return 3;
    CloseDesktop(input);
    snprintf(name,sizeof(name),"DOS5Probe_%lu_%llu",GetCurrentProcessId(),(unsigned long long)GetTickCount64());
    HDESK desktop=CreateDesktopA(name,NULL,NULL,0,DESKTOP_CREATEWINDOW|DESKTOP_READOBJECTS|DESKTOP_WRITEOBJECTS|DESKTOP_ENUMERATE,NULL);
    if (!desktop) {printf("CreateDesktop error=%lu\n",GetLastError()); return 4;}
    if (!GetUserObjectInformationA(desktop,UOI_NAME,actual,sizeof(actual),&needed) || lstrcmpA(actual,input_before)==0) {CloseDesktop(desktop);return 5;}
    printf("input-desktop=%s isolated-desktop=%s\n",input_before,actual); fflush(stdout);
    si.cb=sizeof(si); si.lpDesktop=name;
    si.dwFlags=STARTF_USESHOWWINDOW; si.wShowWindow=SW_SHOWNORMAL;
    if (!CreateProcessA(argv[1],NULL,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,argv[2],&si,&pi)) {
        printf("CreateProcess error=%lu\n",GetLastError()); CloseDesktop(desktop);return 6;
    }
    owned_pid=pi.dwProcessId; owned_process=pi.hProcess;
    printf("owned-pid=%lu\n",owned_pid);fflush(stdout);
    DWORD wait=WAIT_TIMEOUT;
    for (int i=0;i<6;i++) {
        wait=WaitForSingleObject(pi.hProcess,5000);
        EnumDesktopWindows(desktop,report_window,0);fflush(stdout);
        if (wait!=WAIT_TIMEOUT) break;
        if (i==0) {printf("owned-console-start=%d\n",start_owned_console());fflush(stdout);}
        if (i==2) report_threads();
    }
    if (wait==WAIT_TIMEOUT) {printf("budget-end: terminate owned process\n");TerminateProcess(pi.hProcess,0);WaitForSingleObject(pi.hProcess,5000);}
    DWORD code=0;GetExitCodeProcess(pi.hProcess,&code);printf("product-exit=%lu\n",code);
    CloseHandle(pi.hThread);CloseHandle(pi.hProcess);
    input=OpenInputDesktop(0,FALSE,DESKTOP_READOBJECTS);
    if (!input || !GetUserObjectInformationA(input,UOI_NAME,input_after,sizeof(input_after),&needed)) {CloseDesktop(desktop);return 7;}
    CloseDesktop(input); CloseDesktop(desktop);
    printf("input-desktop-after=%s\n",input_after);
    return lstrcmpA(input_before,input_after)==0 ? 0 : 8;
}
