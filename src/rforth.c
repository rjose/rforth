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
#include "GenericForthMachine.h"
#include "ForthServer.h"


//------------------------------------------------------------------------------
// Runs a string using forth machine
//------------------------------------------------------------------------------
void run_string(struct FMState *machine, const char *input) {
    FM_SetInput(machine, input);                            // Set input to machine
    while (FM_Step(machine)) {};                            // Step through input until done
}

//------------------------------------------------------------------------------
// Loads a file and runs it
//------------------------------------------------------------------------------
void run_file(struct FMState *machine, const char *filename) {
    char *buf;                                              // Will hold contents of file
    const size_t alloc_step = 256;                          // Step size of memory allocation
    size_t buf_len = 0;                                     // How big is the buffer
    size_t space_left = 0;                                  // How much space is left in buf
    long bytes_read;

    int fd = open(filename, O_RDONLY);                      // Open file
    if (fd == -1) {
        printf("Ugh. Couldn't open file: %s\n", filename);
        exit(ERR_OPEN);
    }

    // Read contents into buf
    while(1) {
        if (space_left == 0) {                              // If we don't have any space left,
            if (NULL == (buf = realloc(buf, buf_len + alloc_step))) {
                                                            // allocate alloc_step more
                printf("Ugh. Couldn't realloc memory\n");
                exit(ERR_REALLOC);
            }
            space_left = alloc_step;
        }
        bytes_read = read(fd, buf + buf_len, space_left);
        buf_len += bytes_read;
        space_left -= bytes_read;
        if (space_left > 0) {
            break;
        }
    }

    // Resize buf and NUL terminate
    if (NULL == (buf = realloc(buf, buf_len + 1))) {
        printf("Ugh. Couldn't realloc memory\n");
        exit(ERR_REALLOC);
    }
    buf[buf_len] = NUL;


    // Run string
    run_string(machine, buf);
}

//------------------------------------------------------------------------------
// Main function
//------------------------------------------------------------------------------
int main(int argc, char* argv[]) {
    struct FMState forth_server = CreateForthServer();
    run_file(&forth_server , "server.fth");
    return 0;
}
