#include <stdio.h>
#include <stdlib.h>

#include "FMCore.h"

//---------------------------------------------------------------------------
// Pushes constant's param value onto stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int run_constant_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter value;
    if (FMC_copy_param(state, entry->params, &value) < 0) {
        return -1;
    }
    if (FMC_push(state, value) < 0) {
        return -1;
    }

    return 0;
}


//---------------------------------------------------------------------------
// Defines a constant
//
// Stack args:
//   * top: constant's value
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int CONSTANT_code(struct FMState *state, struct FMEntry *entry) {
    if (FMC_read_word(state) < 0) {                         // If couldn't read word,
        FMC_abort(state,
                 "Can't define a constant without a name",
                 __FILE__, __LINE__);                       // abort.
        return -1;
    }
    const char *name = state->word_buffer;                  // Get pointer to constant's name

    int top = state->stack_top;                             // Get index of stack top,
    if (top < 1) {                                          // and check that we have enough args
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    //==========================
    // Create entry for constant
    //==========================
    if (FMC_create_entry(state, name) != 0) {               // Create entry for constant
        return -1;
    }

    struct FMEntry *cur_entry = M_last_entry(state);        // Get a pointer to newly created entry and
    cur_entry->code = run_constant_code;                    // set its code.

    if ((cur_entry->params =
         malloc(sizeof(struct FMParameter))) == NULL) {     // Try allocating space for constant's param
        FMC_abort(state, "malloc failed",
                 __FILE__, __LINE__);                       // On failure, abort and
        FMC_delete_entry(cur_entry);                        // toss the entry we were working on.
        state->last_entry_index--;
        return -1;
    }
    cur_entry->num_params = 1;                              // There is now one param in the entry
                                                            // to hold the value of the variable

    //==========================
    // Store constant's value
    //==========================
    struct FMParameter *value = &(state->stack[top]);       // Get value to store
    cur_entry->params[0] = *value;                          // Store constant's value in param,
    FMC_null_param(value);                                  // NULL it out,
    if (FMC_drop(state) < 0) {return -1;}                   // and drop the stack arg

    return 0;
}
