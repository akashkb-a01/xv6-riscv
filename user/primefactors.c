#include "kernel/types.h"
#include "user/user.h"

int primes[]={2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97};

int main(int argc, char const *argv[])
{
    if(argc != 2){
        printf("Error: Expected 2 arguments, got %d.\n", argc);
        exit(0);
    }

    int n = atoi(argv[1]);
    int fd[2];
    pipe(fd);
    int i = 0;
    write(fd[1], &n, 8);
    while(i != 25){
        if(fork() == 0){
            read(fd[0], &n, 8);
            if(n % primes[i] == 0){
                while(n % primes[i] == 0){
                    printf("%d, ", primes[i]);
                    n /= primes[i];
                }
                printf("[%d]\n", getpid());
            }
            write(fd[1], &n, 8);
        }
        else{
            wait(0);
            close(fd[0]);
            close(fd[1]);
            exit(0);
        }
        i++;
    }
    
    exit(0);
    return 0;
}