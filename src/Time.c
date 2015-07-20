#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <sys/time.h>

#include "defines.h"
#include "FMCore.h"


//---------------------------------------------------------------------------
// Pushes current timestamp onto stack
//
// Stack args ( -- timestamp_ms)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int TIMESTAMP_code(struct FMState *state, struct FMEntry *entry) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    long timestamp_ms = tv.tv_sec * 1000 + tv.tv_usec/1000;
    
    struct FMParameter result;                              // Create a param
    result.type = INT_PARAM;                                // of type INT_PARAM and
    result.value.int_param = timestamp_ms;                  // with the timestamp as its value, and
    if (FMC_push(state, result) < 0) {                      // push it onto the stack
        return -1;
    }

    return 0;
}


//---------------------------------------------------------------------------
// Waits some num of ms
//
// Stack args ( delay_ms -- )
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int WAIT_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }

    
    struct FMParameter *delay_ms;
    if (NULL == (delay_ms = FMC_stack_arg(state, 0))) {     // Get delay_ms from top of stack
        return -1;
    }
    if (delay_ms->type != INT_PARAM) {                      // (aborting if not an INT_PARAM)
        FMC_abort(state, "WAIT_code expecting int param for delay_ms", __FILE__, __LINE__);
        return -1;
    }

    long total_ms = delay_ms->value.int_param;              // Get total delay in ms,
    long num_s = total_ms / 1000;                           // figuring out the number of seconds and
    long num_ms = total_ms - num_s * 1000;                  // the number of ms leftover


    struct timespec requested;                              // Prepare arg to nanosleep
    requested.tv_sec = num_s;                               // waiting the num_s and
    requested.tv_nsec = num_ms * NS_PER_MS;                 // the num ms
    if (nanosleep(&requested, NULL) == -1) {
        FMC_abort(state, "nanosleep failed", __FILE__, __LINE__);
        return -1;
    }

    if (FMC_drop(state) < 0) {                              // Pop the value off the stack
        return -1;
    }

    return 0;
}
