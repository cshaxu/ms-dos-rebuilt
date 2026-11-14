int dup2(int,int);
int system(char *);
int main(void) { dup2(1,2); return system("nmake msdos.sys"); }
