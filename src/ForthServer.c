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
#include <unistd.h>


extern int TIMESTAMP_code(struct FMState *state, struct FMEntry *entry);
extern int WAIT_code(struct FMState *state, struct FMEntry *entry);
extern int run_variable_code(struct FMState *state, struct FMEntry *entry);

#define M_define_word(name, immediate, code)  FMC_define_word(&result, name, immediate, code);


//============================
// Globals
//============================
static
struct epoll_event G_epoll_events[MAX_EPOLL_EVENTS];


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
    printf("Socket: %d\n", result);
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
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *http_port;
    if (NULL == (http_port = FMC_stack_arg(state, 0))) {    // http_port is on top
        return -1;
    }

    if (http_port->type != INT_PARAM) {
        FMC_abort(state, "http_port should be an int", __FILE__, __LINE__);
        return -1;
    }

    int http_fd =
        make_http_socket(http_port->value.int_param);       // Make a nonblocking socket

    if (FMC_drop(state) < 0) {return -1;}                   // Drop the http_port, and
    struct FMParameter result;                              // package resulting http_fd
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
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *http_fd;
    if (NULL == (http_fd = FMC_stack_arg(state, 0))) {      // http_fd is on top
        return -1;
    }
    if (http_fd->type != INT_PARAM) {
        FMC_abort(state, "http_fd should be an int", __FILE__, __LINE__);
        return -1;
    }

    int epoll_fd =
        monitor_fd(http_fd->value.int_param);               // Make a nonblocking socket

    if (FMC_drop(state) < 0) {return -1;}                   // Drop http_fd, and then
    struct FMParameter result;                              // package resulting epoll_fd
    result.type = INT_PARAM;                                // into an
    result.value.int_param = epoll_fd;                      // INT_PARAM and
    if (FMC_push(state, result) < 0) {                      // push it onto stack
        return -1;
    }

    return 0;
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
static
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


    //    RR_Create(connected_fd);
    

    printf("Connected with %d\n", connected_fd);
    // TODO: Do something better here
#define MAXLINE 256
    char buf[MAXLINE];
    int n = read(connected_fd, buf, MAXLINE-1);
    printf("Read %d chars\n", n);
    buf[n] = '\0';
    printf("=====\n%s\n=====", buf);

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
static
void establish_all_pending_connections(int http_fd) {
    while(1) {
        if (establish_http_connection(http_fd) < 0) {
            break;
        }
    }
}

/*
//------------------------------------------------------------------------------
// Updates any sockets requiring attention
//
// Args:
//   * epoll_fd: fd used to get epoll info from kernel
//   * http_fd: fd used for HTTP connection requests
//------------------------------------------------------------------------------
static
void update_connections(int epoll_fd, int http_fd) {
    // TODO: Make this global
    static struct epoll_event evlist[MAX_EPOLL_EVENTS];

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
*/

//---------------------------------------------------------------------------
// Looks up int variable, returning NULL if a problem
//---------------------------------------------------------------------------
static
struct FMParameter *get_int_variable(struct FMState *state, const char *name) {
    struct FMEntry *entry = FMC_find_entry(state, name);    // Look up variable entry,
    if (entry == NULL) {                                    // aborting if we couldn't find it..
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Coulnd't find variable '%s'", name);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return NULL;
    }
    if (entry->code != run_variable_code) {                 // ..or if it wasn't a variable..
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Entry '%s' must be a variable", name);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return NULL;
   }

    struct FMParameter *result = &(entry->params[0]);
    if (result->type != INT_PARAM) {                        // ..or if it wasn't an INT_PARAM
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Variable '%s' must be an INT_PARAM", name);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return NULL;
    }

    return result;                                          // Otherwise, return variable's param
}

/*
//---------------------------------------------------------------------------
// Update connections
//
// Stack effect:
//   ( -- )
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
//---------------------------------------------------------------------------
static
int UPDATE_CONNECTIONS_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter *epoll_fd =
        get_int_variable(state, "epoll_fd");                // Look up epoll_fd variable
    if (epoll_fd == NULL) {
        return -1;
    }
    struct FMParameter *http_fd =
        get_int_variable(state, "http_fd");                 // Look up http_fd variable
    if (http_fd == NULL) {
        return -1;
    }

    update_connections(epoll_fd->value.int_param,
                       http_fd->value.int_param);           // Update connections and
    return 0;                                               // indicate success
}
*/

//---------------------------------------------------------------------------
// Checks for epoll events, stores them, and pushes num events onto stack
//
// Stack effect:
//   (epoll_fd -- count)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: This modifies G_epoll_events
//---------------------------------------------------------------------------
static
int EPOLL_WAIT_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *epoll_fd;
    if (NULL == (epoll_fd = FMC_stack_arg(state, 0))) {    // epoll_fd is on top
        return -1;
    }

    int num_descriptors =
        epoll_wait(epoll_fd->value.int_param,
                   G_epoll_events, MAX_EPOLL_EVENTS, 0);    // Check for any fd needing an update

    if (num_descriptors == -1) {                            // If something went wrong,
        if (errno != EINTR) {                               // and it wasn't because of an interrupt,
            printf("Ugh. epoll_wait failed\n");             // then exit hard (we may want to revisit this)
            exit(ERR_EPOLL_WAIT);
        }
        num_descriptors = 0;                                // If just interrupted, set num fds to 0
    }
    if (num_descriptors > 0) {
        printf("Got something\n");
    }

    // Push result onto stack
    if (FMC_drop(state) < 0) {return -1;}                   // First, drop the epoll_fd..
    struct FMParameter result;
    result.type = INT_PARAM;
    result.value.int_param = num_descriptors;
    if (FMC_push(state, result) < 0) {return -1;}           // ..then push num descriptors

    return 0;
}


//---------------------------------------------------------------------------
// Pushes web fd associated with index onto stack
//
// Stack effect:
//   (index -- fd)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: This reads from G_epoll_events
//---------------------------------------------------------------------------
static
int EPOLL_WEB_FD_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *index;
    if (NULL == (index = FMC_stack_arg(state, 0))) {    // index is on top
        return -1;
    }

    // Push result onto stack
    struct FMParameter result;
    result.type = INT_PARAM;
    result.value.int_param =
        G_epoll_events[index->value.int_param].data.fd;     // File descriptor is in G_epoll_events

    if (FMC_drop(state) < 0) {return -1;}                   // Drop index from stack,
    if (FMC_push(state, result) < 0) {return -1;}           // and push result.

    return 0;
}


//---------------------------------------------------------------------------
// Attempts to accept an HTTP connection
//
// Stack effect:
//   (http_fd -- fd status)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// On establish connection, push "fd 0" onto stack. On failure, push "-1 -1".
//---------------------------------------------------------------------------
static
int ACCEPT_CONNECTION_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *http_fd;
    if (NULL == (http_fd = FMC_stack_arg(state, 0))) {        // http_fd is on top
        return -1;
    }

    // Try to accept connection
    struct sockaddr_in client_addr;
    socklen_t client_len = sizeof(client_addr);
    int connected_fd = accept(http_fd->value.int_param, (struct sockaddr*) &client_addr, &client_len);
    if (connected_fd == -1) {
        if (errno && (EWOULDBLOCK | ECONNABORTED | EPROTO | EINTR)) {
            // Not really an error. Just no connection to make
        }
        else {
            FMC_abort(state, "accept failed", __FILE__, __LINE__);
            return -1;
        }
    }

    // Push result onto stack
    if (FMC_drop(state) < 0) {return -1;}                   // Drop http_fd from stack,

    struct FMParameter fd;
    fd.type = INT_PARAM;
    fd.value.int_param = connected_fd;                      // Prepare first result
    
    struct FMParameter status;
    status.type = INT_PARAM;
    status.value.int_param = 0;                             // Status is OK,
    if (connected_fd == -1) {                               // unless connected_fd is -1,
        status.value.int_param = -1;                        // in which case status is -1
    }

    if (FMC_push(state, fd) < 0) {return -1;}               // Push fd and
    if (FMC_push(state, status) < 0) {return -1;}           // then status,
    return 0;                                               // returning 0 for OK
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
    M_define_word("EPOLL-WAIT", 0, EPOLL_WAIT_code);
    M_define_word("EPOLL-WEB-FD", 0, EPOLL_WEB_FD_code);
    M_define_word("ACCEPT-CONNECTION", 0, ACCEPT_CONNECTION_code);

    return result;
}
