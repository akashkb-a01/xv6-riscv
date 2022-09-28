#include "kernel/types.h"
#include "user/user.h"

//getpa
int main(int argc, char const *argv[])
{
    char x = '0';
    int z,y;
    z = 9;
    y = 8;
    printf("%l \n%l \n%l",getpa(&z), getpa(&x), getpa(&y));
    exit(0);
    return 0;
}

/*
//yield
int main(int argc, char const *argv[])
{
    if(fork() == 0){
        printf("C1\n");
    }
    else{
        yield();
        printf("P\n");
        }
    exit(0);
    return 0;
}

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