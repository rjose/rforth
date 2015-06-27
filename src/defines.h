#ifndef DEFINES_H
#define DEFINES_H

#define NS_PER_MS             1000000
#define LISTEN_BACKLOG        1024
#define INITIAL_NUM_SOCKETS   5
#define MAX_EPOLL_EVENTS      5
#define CYCLE_PERIOD_MS       50             // Minimum event loop period
#define NUL                   '\0'

// Error codes
#define ERR_FORTH_SERVER      1
#define ERR_NANOSLEEP         10
#define ERR_SET_SOCK_OPT      11
#define ERR_FCNTL             12
#define ERR_BIND              13
#define ERR_LISTEN            14
#define ERR_EPOLL_CREATE      15
#define ERR_EPOLL_CTL         16
#define ERR_EPOLL_WAIT        17
#define ERR_CLOSE             18

#endif
