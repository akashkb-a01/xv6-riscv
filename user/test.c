#include "kernel/types.h"
#include "user/user.h"

//waitpid
int main(int argc, char const *argv[])
{
    int x = fork();
    if(x == 0){
        printf("%d: Child Here\n", getpid());
        x = fork();
        if(x == 0) printf("%d\n", getpid());
        else{
            // printf("%d\n", getpid());
            while(1);
        }
    }
    else{
        waitpid(x, 0);
        printf("%d: Child Not here\n", x);
    }
    exit(0);
    return 0;
}


/*
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