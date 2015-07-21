#include <stdio.h>
#include <stdlib.h>

#include "FMCore.h"


//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int DROP_code(struct FMState *state, struct FMEntry *entry) {
    return FMC_drop(state);
}


//---------------------------------------------------------------------------
// Duplicates top of stack
//
// Stack args:
//   * 0: value
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int DUP_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *original;;
    if (NULL == (original = FMC_stack_arg(state, 0))) {      // original is on top
        return -1;
    }

    struct FMParameter copy;
    if (FMC_copy_param(state, original, &copy) < 0) {       // Make a copy of the top of the stack and
        return -1;
    }

    if (FMC_push(state, copy) < 0) {                        // push it onto stack
        return -1;
    }
    return 0;
}
