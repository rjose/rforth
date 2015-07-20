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
    int top = state->stack_top;

    if (top + 1 < 1) {                                       // Check that stack has at least 1 elem
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }
    struct FMParameter *original = &(state->stack[top]);    // Get value

    struct FMParameter copy;
    if (FMC_copy_param(state, original, &copy) < 0) {       // Make a copy of the top of the stack and
        return -1;
    }

    if (FMC_push(state, copy) < 0) {                        // push it onto stack
        return -1;
    }
    return 0;
}
