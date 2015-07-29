#include <stdio.h>
#include <stdlib.h>
#include "macros.h"

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


//---------------------------------------------------------------------------
// Swaps top two elements of stack
//
// Stack effect: (v1 v2 -- v2 v1)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int SWAP_code(struct FMState *state, struct FMEntry *entry) {
    // Get values
    if (FMC_check_stack_args(state, 2) < 0) {               // Check that stack has at least 2 elems
        return -1;
    }
    struct FMParameter *v1;
    struct FMParameter *v2;
    M_get_stack_arg(v2, 0);                                 // v2 is at top of stack
    M_get_stack_arg(v1, 1);                                 // v1 is one below top

    // Copy values to swap
    struct FMParameter first;
    struct FMParameter second;

    if (FMC_copy_param(state, v1, &second) < 0) {           // v1 goes second
        return -1;
    }
    if (FMC_copy_param(state, v2, &first) < 0) {            // v2 goes first
        return -1;
    }

    // Push values onto stack
    if (FMC_drop(state) < 0) {return -1;}                   // Drop v2
    if (FMC_drop(state) < 0) {return -1;}                   // Drop v1

    if (FMC_push(state, first) < 0) {return -1;}
    if (FMC_push(state, second) < 0) {return -1;}

    return 0;
}


//---------------------------------------------------------------------------
// Copies element 1 below stack and pushes onto top
//
// Stack effect: (a b -- a b a)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int OVER_code(struct FMState *state, struct FMEntry *entry) {
    // Get values
    if (FMC_check_stack_args(state, 2) < 0) {               // Check that stack has at least 2 elems
        return -1;
    }
    struct FMParameter *a;
    M_get_stack_arg(a, 1);                                  // a is one below top

    // Copy values to swap
    struct FMParameter copy;

    if (FMC_copy_param(state, a, &copy) < 0) {              // Make a copy of a..
        return -1;
    }

    if (FMC_push(state, copy) < 0) {return -1;}             // ..and push it on the stack
    return 0;
}
