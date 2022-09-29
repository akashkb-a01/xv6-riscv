#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  if(argint(0, &pid) < 0)
    return -1;
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;

  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

//Returns the pid of the parent of the calling process
uint64
sys_getppid(void)
{
  struct proc* par_proc = myproc()->parent;
  //if parent process exists
  if(par_proc) 
    return par_proc->pid;
  
  else 
    return -1;
}

//Calling process is de-scheduled
uint64
sys_yield(void)
{
  yield();
  return 0;
}

//Takes a virtual address and returns the corresponding physical address
uint64
sys_getpa(void)
{
  uint64 va;  //virtual address

  if(argaddr(0, &va) < 0)
    return -1;
    
  return walkaddr(myproc()->pagetable, va) + (va & (PGSIZE - 1));
}

//Forked child first executes passed function
uint64
sys_forkf(void)
{
  uint64 fa;  //funtion pointer
  
  if(argaddr(0, &fa) < 0)
    return -1;
  
  return forkf(fa);
}

//Waits for the process with the passed pid
uint64
sys_waitpid(void)
{
  uint64 pid;
  uint64 p; //pointer for status
  
  if(argaddr(0, &pid) < 0)
    return -1;
  
  if(argaddr(1, &p) < 0)
    return -1;
  
  //Case when passed pid is -1 simply execute wait()
  if(pid == -1)
    return wait(p);
  
  return waitpid(pid, p);
}

//Walks over the process table and prints the fields of it.
uint64
sys_ps(void){
  ps();
  return 0;
}

//returns the information about a specific process to the calling program
uint64
sys_pinfo(void){
  uint64 pid;
  uint64 p;   //pointer to the procstat struct
  
  if(argaddr(0, &pid) < 0)
    return -1;
  
  //Case when passed pid is -1
  if(pid == -1) 
    pid = myproc()->pid;
  
  if(argaddr(1, &p) < 0)
    return -1;
  
  return pinfo(pid, p);
}