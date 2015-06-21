#include <time.h>
#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>

static void
handler(int sig) {
  printf("Got signal %d\n", sig);
  exit(0);
}

int
main(int argc, char* argv[]) {
  int status = 0;

  struct sigaction sa;
  sigemptyset(&sa.sa_mask);
  sa.sa_handler = handler;
  if(sigaction(SIGINT, &sa, NULL) == -1) {
    printf("Ugh. sigaction failed\n");
    exit(2);
  }
  
  struct timespec requested;
  while(1) {
    printf("Howdy!\n");
    requested.tv_sec = 0;
    requested.tv_nsec = 500000000; // 500 ms
    status = nanosleep(&requested, NULL);
    if (status == -1) {
      printf("Interrupted by %d\n", errno);
    }
  }
  return 0;
}
