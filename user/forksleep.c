#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char const *argv[])
{
    if(argc < 2){
        printf("Too few arguments. Expected 3 got $d.\n", argc);
        exit(0);
    }

    int m, n;
    m = atoi(argv[1]);
    n = atoi(argv[2]);

    if(fork() == 0){
        if(n == 0) sleep(m);
        printf("%d: Child.\n", getpid());
    }
    else{
        if(n == 1) sleep(m);
        printf("%d: Parent.\n", getpid());
        wait(0);
    }
    exit(0);
    return 0;
}
