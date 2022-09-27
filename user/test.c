#include "kernel/types.h"
#include "user/user.h"

//yield
int main(int argc, char const *argv[])
{
    if(fork() == 0){
        printf("C\n");
    }
    else{
        yield();
        printf("P\n");
        }
    exit(0);
    return 0;
}
/*
//getppid
int main(int argc, char const *argv[])
{
    if(fork() == 0){
        printf(" Child pid: %d\n Child ppid: %d\n", getpid(), getppid());
    }
    else{
        wait(0);
        printf(" Parent pid: %d\n Parent ppid: %d\n", getpid(), getppid());
        }
    exit(0);
    return 0;
}
*/