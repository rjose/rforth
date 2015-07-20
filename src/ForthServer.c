#include "ForthServer.h"

#include "defines.h"

#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <strings.h>
#include <fcntl.h>
#include <sys/epoll.h>

extern int TIMESTAMP_code(struct FMState *state, struct FMEntry *entry);
extern int WAIT_code(struct FMState *state, struct FMEntry *entry);


#define M_define_word(name, immediate, code)  FMC_define_word(&result, name, immediate, code);

//------------------------------------------------------------------------------
// Creates a nonblocking socket and listens on it
//
// Returns fd of socket
//------------------------------------------------------------------------------
static
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

//---------------------------------------------------------------------------
// Creates an http socket leaving its file descriptor on the stack
//
// Stack args (http_port -- http_fd)
//   * top: http_port
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
//---------------------------------------------------------------------------
static
int make_http_socket_code(struct FMState *state, struct FMEntry *entry) {
    int top = state->stack_top;

    if (top + 1 < 1) {                                       // Check that stack has at least 1 elem
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }
    struct FMParameter *http_port = &(state->stack[top]);    // Get http port to listen on
    if (http_port->type != INT_PARAM) {
        FMC_abort(state, "http_port should be an int", __FILE__, __LINE__);
        return -1;
    }

    int http_fd =
        make_http_socket(http_port->value.int_param);       // Make a nonblocking socket

    struct FMParameter result;                              // Package resulting http_fd
    result.type = INT_PARAM;                                // into an
    result.value.int_param = http_fd;                       // INT_PARAM and
    if (FMC_push(state, result) < 0) {                      // push it onto stack
        return -1;
    }

    return 0;
}


//------------------------------------------------------------------------------
// Uses epoll to monitor state of socket
//
// Returns fd to use for interactint with epoll
//------------------------------------------------------------------------------
static
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


//---------------------------------------------------------------------------
// Monitors file descriptor using epoll, leaving the epoll_fd on the stack
//
// Stack effect:
//   (http_fd -- epoll_fd)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
//---------------------------------------------------------------------------
static
int monitor_fd_code(struct FMState *state, struct FMEntry *entry) {
    int top = state->stack_top;

    if (top + 1 < 1) {                                       // Check that stack has at least 1 elem
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }
    struct FMParameter *http_fd = &(state->stack[top]);      // Get http fd to monitor
    if (http_fd->type != INT_PARAM) {
        FMC_abort(state, "http_fd should be an int", __FILE__, __LINE__);
        return -1;
    }

    int epoll_fd =
        monitor_fd(http_fd->value.int_param);               // Make a nonblocking socket

    struct FMParameter result;                              // Package resulting epoll_fd
    result.type = INT_PARAM;                                // into an
    result.value.int_param = epoll_fd;                      // INT_PARAM and
    if (FMC_push(state, result) < 0) {                      // push it onto stack
        return -1;
    }

    return 0;
}


//---------------------------------------------------------------------------
// Creates a forth server
//---------------------------------------------------------------------------
struct FMState CreateForthServer() {
    struct FMState result = CreateGenericFM();
 
    M_define_word("MAKE-HTTP-SOCKET", 0, make_http_socket_code);
    M_define_word("MONITOR-FD", 0, monitor_fd_code);
    M_define_word("TIMESTAMP", 0, TIMESTAMP_code);
    M_define_word("WAIT", 0, WAIT_code);

    return result;
}
