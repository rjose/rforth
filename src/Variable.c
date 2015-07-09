#include <stdio.h>
#include <stdlib.h>

#include "FMCore.h"

//---------------------------------------------------------------------------
// Looks for variable's entry and pushes its address onto the stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int run_variable_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter value;                               // Create a param to push onto stack
    value.type = ENTRY_PARAM;                               // of type ENTRY
    value.value.entry_param = entry;                        // and with the variable's entry as its value

    if (FMC_push(state, value) < 0) {                        // Push onto forth stack
        return -1;
    }

    return 0;
}


//---------------------------------------------------------------------------
// Defines a variable
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int VARIABLE_code(struct FMState *state, struct FMEntry *entry) {
#define M_last_entry(state)   (&((state)->dictionary[(state)->last_entry_index]))

    if (FMC_read_word(state) < 0) {                             // If couldn't read word,
        FMC_abort(state,
                 "Can't define a variable without a name",
                 __FILE__, __LINE__);                       // abort.
        return -1;
    }

    const char *name = state->word_buffer;

    if (FMC_create_entry(state, name) != 0) {                   // Create entry,
        return -1;                                          // (returning -1 on failure)
    }

    struct FMEntry *cur_entry = M_last_entry(state);        // Get a pointer to newly created entry and
    cur_entry->code = run_variable_code;                    // set its code to run_variable_code.

    if ((cur_entry->params =
         malloc(sizeof(struct FMParameter))) == NULL) {     // Try allocating space for param.
        FMC_abort(state, "malloc failed",
                 __FILE__, __LINE__);                       // On failure, abort and
        FMC_delete_entry(cur_entry);                            // toss the entry we were working on.
        state->last_entry_index--;
        return -1;
    }
    cur_entry->num_params = 1;                              // There is now one param in the entry

    return 0;
}
