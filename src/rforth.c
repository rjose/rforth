#include <time.h>
#include <stdio.h>
#include <errno.h>
#include <signal.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <strings.h>
#include <unistd.h>

static void
handler(int sig) {
    printf("Got signal %d\n", sig);
    exit(0);
}

int
main(int argc, char* argv[]) {
    int status = 0;
    struct sigaction sa;
    socklen_t client_len;
    struct sockaddr_in client_addr, server_addr;
    
    sigemptyset(&sa.sa_mask);
    sa.sa_handler = handler;
    if(sigaction(SIGINT, &sa, NULL) == -1) {
        printf("Ugh. sigaction failed\n");
        exit(2);
    }

    // Open a socket, listen, and accept
    int listening_fd = socket(AF_INET, SOCK_STREAM, 0);

    bzero(&server_addr, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
    server_addr.sin_port = htons(9876);
    
    if (bind(listening_fd, (struct sockaddr*) &server_addr, sizeof(server_addr)) == -1) {
        printf("Ugh. bind failed\n");
        exit(3);
    }

    if (listen(listening_fd, 1024) == -1) {
        printf("Ugh. listen failed\n");
        exit(4);
    }

    struct timespec requested;
    while(1) {
        printf("Howdy!\n");

        // TODO: Don't block while waiting for a connection
        int connected_fd = accept(listening_fd, (struct sockaddr*) &client_addr, &client_len);
        printf("Connected with %d\n", connected_fd);
        if (close(connected_fd) == -1) {
            printf("Ugh. close failed\n");
            exit(5);
        }
        
        requested.tv_sec = 0;
        requested.tv_nsec = 500000000; // 500 ms
        status = nanosleep(&requested, NULL);
        if (status == -1) {
            printf("Interrupted by %d\n", errno);
        }
    }
    return 0;
}
