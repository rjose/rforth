#include <stdio.h>
#include <time.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <strings.h>
#include <unistd.h>
#include <sys/epoll.h>
#include <fcntl.h>

#include "defines.h"

//------------------------------------------------------------------------------
// Delays by specified number of ms
//------------------------------------------------------------------------------
void wait_ms(int ms_delay) {
    struct timespec requested;

    requested.tv_sec = 0;
    requested.tv_nsec = ms_delay * NS_PER_MS;
    if (nanosleep(&requested, NULL) == -1) {
        printf("Ugh. nanosleep failed: %s\n", strerror(errno));
        exit(ERR_NANOSLEEP);
    }
}


//------------------------------------------------------------------------------
// Creates a nonblocking socket and listens on it
//
// Returns fd of socket
//------------------------------------------------------------------------------
int make_http_socket(int port) {
    struct sockaddr_in server_addr;

    // Create socket
    int result = socket(AF_INET, SOCK_STREAM, 0);

    // Reuse address so we can restart quickly
    int enable = 1;
    if (setsockopt(result, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0) {
        printf("Ugh. setsockopt failed\n");
        exit(ERR_SET_SOCK_OPT);
    }

    // Make socket nonblocking
    int flags;
    if ( (flags = fcntl(result, F_GETFL, 0)) < 0) {
        printf("Ugh. fcntl failed\n");
        exit(ERR_FCNTL);
    }
    flags |= O_NONBLOCK;
    if (fcntl(result, F_SETFL, flags) < 0) {
        printf("Ugh. fcntl failed\n");
        exit(ERR_FCNTL);
    }

    // Bind to port on 0.0.0.0
    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    server_addr.sin_port = htons(port);
    if (bind(result, (struct sockaddr*) &server_addr, sizeof(server_addr)) == -1) {
        printf("Ugh. bind failed: %s\n", strerror(errno));
        exit(ERR_BIND);
    }

    // Start listening
    if (listen(result, LISTEN_BACKLOG) == -1) {
        printf("Ugh. listen failed\n");
        exit(ERR_LISTEN);
    }
    return result;
}

//------------------------------------------------------------------------------
// Uses epoll to monitor state of socket
//
// Returns fd to use for interactint with epoll
//------------------------------------------------------------------------------
int monitor_fd(int new_fd) {
    struct epoll_event ev;

    // Set up epoll in kernel
    int result = epoll_create(INITIAL_NUM_SOCKETS);
    if (result == -1) {
        printf("Ugh. epoll_create failed\n");
        exit(ERR_EPOLL_CREATE);
    }

    // Listen to file descriptor
    ev.data.fd = new_fd;
    ev.events = EPOLLIN | EPOLLOUT | EPOLLET;               // Wait for edge triggered read/write
    if (epoll_ctl(result, EPOLL_CTL_ADD, new_fd, &ev) == -1) {
        printf("Ugh. epoll_ctl failed\n");
        exit(ERR_EPOLL_CTL);
    }
    return result;
}


//------------------------------------------------------------------------------
// Establishes new http connections
//
// TODO: Does an initial read of data as well
//
// Returns:
//   *  0 if OK
//   * -1 if would block (i.e., no more outstanding connection requests).
//   * -2 if there was a genuine problem
//------------------------------------------------------------------------------
int establish_http_connection(int http_fd) {
    socklen_t client_len;
    struct sockaddr_in client_addr;

    int connected_fd = accept(http_fd, (struct sockaddr*) &client_addr, &client_len);
    if (connected_fd == -1) {
        if (errno & (EWOULDBLOCK | ECONNABORTED | EPROTO | EINTR)) {
            printf("Ignoring error: %d\n", errno);
            return -1;
        }
        else {
            printf("Ugh. Connect failed\n");
            return -2;
        }
    }
                    
    printf("Connected with %d\n", connected_fd);
    // TODO: Monitor this connection as well
    // TODO: Read initial HTTP request
    if (close(connected_fd) == -1) {
        printf("Ugh. close failed\n");
        exit(ERR_CLOSE);
    }
}

//------------------------------------------------------------------------------
// Establishes connections for all pending HTTP client requests
//------------------------------------------------------------------------------
void establish_all_pending_connections(int http_fd) {
    while(1) {
        if (establish_http_connection(http_fd) < 0) {
            break;
        }
    }
}

//------------------------------------------------------------------------------
// Updates any sockets requiring attention
//
// Args:
//   * epoll_fd: fd used to get epoll info from kernel
//   * http_fd: fd used for HTTP connection requests
//------------------------------------------------------------------------------
void update_connections(int epoll_fd, int http_fd) {
    struct epoll_event evlist[MAX_EPOLL_EVENTS];

    int num_descriptors = epoll_wait(epoll_fd, evlist, MAX_EPOLL_EVENTS, 0);
    if (num_descriptors == -1) {
        if (errno != EINTR) {
            printf("Ugh. epoll_wait failed\n");
            exit(ERR_EPOLL_WAIT);
        }
    }

    printf("Num descriptors: %d\n", num_descriptors);
    for (int i=0; i < num_descriptors; i++) {
        if (evlist[i].data.fd == http_fd) {
            establish_all_pending_connections(http_fd);
        }
        else {
            // TODO: Handle reads/writes
        }
    }
}

//------------------------------------------------------------------------------
// Main function
//------------------------------------------------------------------------------
int main(int argc, char* argv[]) {
    int http_port = 9876;                                   // TODO: Read this from the command line
    int http_fd = make_http_socket(http_port);              // Create socket for http
    int epoll_fd = monitor_fd(http_fd);                     // Use epoll to monitor client connections

    // Main event loop
    while (1) {
        update_connections(epoll_fd, http_fd);              // Updates any sockets that have changed
        printf("Howdy\n");
        wait_ms(10);
    }
    return 0;
}
