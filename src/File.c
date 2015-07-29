#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <errno.h>

#include "defines.h"
#include "macros.h"
#include "FMCore.h"

//---------------------------------------------------------------------------
// Writes len bytes of vptr to fd
//
// From "Unix Network Programming", Vol 1, 3rd Ed, p. 89
//
// Return value: num written or -1 if error
//---------------------------------------------------------------------------
static
int writen(int fd, const void *vptr, size_t len) {
    size_t nleft;
    ssize_t nwritten;
    const char *ptr;

    ptr = vptr;
    nleft = len;
    while (nleft > 0) {
        if ( (nwritten = write(fd, ptr, nleft)) <= 0) {
            if (nwritten < 0 && errno == EINTR) {           // If interrupted, try again
                nwritten = 0;
            }
            else {
                return -1;
            }
        }
        nleft -= nwritten;
        ptr += nwritten;
    }

    return len;
}

//---------------------------------------------------------------------------
// Writes string to fd
//
// Stack effect (fd string -- )
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int WRITE_code(struct FMState *state, struct FMEntry *entry) {
    // Get values
    if (FMC_check_stack_args(state, 2) < 0) {               // Check that stack has at least 2 elems
        return -1;
    }
    struct FMParameter *string;
    struct FMParameter *fd;
    M_get_stack_arg(string, 0);                             // string is at top of stack
    M_get_stack_arg(fd, 1);                                 // fd is one below top

    // Check values
    if (string->type != STRING_PARAM ||
        fd->type != INT_PARAM) {
        FMC_abort(state, "WRITE expecting fd and string",
                  __FILE__, __LINE__);
        return -1;
    }

    char *message = string->value.string_param;
    if (-1 == writen(fd->value.int_param,
                     (const void *) message, strlen(message))) {
        FMC_abort(state, "WRITE failed", __FILE__, __LINE__);
        return -1;
    }

    if (FMC_drop(state) < 0) {return -1;}                   // Drop string
    if (FMC_drop(state) < 0) {return -1;}                   // Drop fd

    return 0;
}


//---------------------------------------------------------------------------
// Closes fd
//
// Stack effect (fd -- )
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int CLOSE_code(struct FMState *state, struct FMEntry *entry) {
    // Get values
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *fd;
    M_get_stack_arg(fd, 0);                                 // fd is at top of stack

    // Check values
    if (fd->type != INT_PARAM) {
        FMC_abort(state, "CLOSE expecting fd",
                  __FILE__, __LINE__);
        return -1;
    }

    while (1) {
        if (-1 == close(fd->value.int_param)) {
            if (errno != EINTR) {
                FMC_abort(state, "Problem closing file", __FILE__, __LINE__);
                return -1;
            }
            // Otherwise, try again (we were just interrupted)
        }
        else {
            break;
        }
    }

    if (FMC_drop(state) < 0) {return -1;}                   // Drop fd

    return 0;
}
