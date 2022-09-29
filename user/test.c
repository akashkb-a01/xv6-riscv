#include "kernel/types.h"
#include "kernel/procstat.h"
#include "user/user.h"

int
main(void)
{
  struct procstat pstat;

  int x = fork();
  if (x < 0) {
     fprintf(2, "Error: cannot fork\nAborting...\n");
     exit(0);
  }
  else if (x > 0) {
     sleep(5);
     fprintf(1, "%d: Parent.\n", getpid());
     if (pinfo(-1, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
     else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n",
         pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
     if (pinfo(x, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
     else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n\n",
         pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
     fprintf(1, "Return value of waitpid=%d\n", waitpid(x, 0));
  }
  else {
     fprintf(1, "%d: Child.\n", getpid());
     if (pinfo(-1, &pstat) < 0) fprintf(1, "Cannot get pinfo\n");
     else fprintf(1, "pid=%d, ppid=%d, state=%s, cmd=%s, ctime=%d, stime=%d, etime=%d, size=%p\n\n",
         pstat.pid, pstat.ppid, pstat.state, pstat.command, pstat.ctime, pstat.stime, pstat.etime, pstat.size);
  }

  exit(0);
}

/*
int main(int argc, char const *argv[])
{
    struct procstat p;
    printf("main: %x\n", &p);
    pinfo(-1, &p);
    printf("%d\n", p.pid);

    exit(0);
    return 0;
}

//ps
int main(int argc, char const *argv[])
{
    int y = fork();
    if(y == 0){
        printf("\n");
        while(1);
    }
    else{
        kill(y);
        ps();}
    exit(0);
    return 0;
}

int g(int x)
{
    return x * x;
}

int f(void)
{
    int x = 10;

    fprintf(2, "Hello world! %d\n", g(x));
    return 0;
}

int main(void)
{
    int x = forkf(f);
    if (x < 0)
    {
        fprintf(2, "Error: cannot fork\nAborting...\n");
        exit(0);
    }
    else if (x > 0)
    {
        sleep(1);
        fprintf(1, "%d: Parent.\n", getpid());
        wait(0);
    }
    else
    {
        fprintf(1, "%d: Child.\n", getpid());
    }

    exit(0);
}

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