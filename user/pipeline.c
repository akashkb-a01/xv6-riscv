#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char const *argv[])
{
    if(argc < 3){
        printf("Too few arguments. Expected 3 got %d.\n", argc);
        exit(0);
    }
    int n, x, k;
    n = atoi(argv[1]);
    x = atoi(argv[2]);
    
    if(n <= 0){
        printf("First argument expected positive.\n");
        exit(0);
    }

    int fd[2];
    if(pipe(fd) < 0){
        printf("Error: cannot create pipe. Aborting \n");
        exit(0);
    }
    int y, z;
    k = n;
    k--;
    y = getpid() + x;
    printf("%d: %d\n", getpid(), y);
    write(fd[1], &y, 1);
    while(k--){
        if(fork() == 0){
            read(fd[0], &z, 8);
            y = z + getpid();
            printf("%d: %d\n", getpid(), y);
            write(fd[1], &y, 8);
        }
        else{
            wait(0);
            close(fd[0]);
            close(fd[1]);
            exit(0);
        }
    }
    
    exit(0);
    return 0;
}
