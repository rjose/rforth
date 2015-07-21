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
    if (FMC_read_word(state) < 0) {                         // If couldn't read word,
        FMC_abort(state,
                 "Can't define a variable without a name",
                 __FILE__, __LINE__);                       // abort.
        return -1;
    }

    const char *name = state->word_buffer;

    if (FMC_create_entry(state, name) != 0) {               // Create entry for variable,
        return -1;                                          // (returning -1 on failure)
    }

    struct FMEntry *cur_entry = M_last_entry(state);        // Get a pointer to newly created entry and
    cur_entry->code = run_variable_code;                    // set its code to run_variable_code.

    if ((cur_entry->params =
         malloc(sizeof(struct FMParameter))) == NULL) {     // Try allocating space for param.
        FMC_abort(state, "malloc failed",
                 __FILE__, __LINE__);                       // On failure, abort and
        FMC_delete_entry(cur_entry);                        // toss the entry we were working on.
        state->last_entry_index--;
        return -1;
    }
    cur_entry->num_params = 1;                              // There is now one param in the entry
                                                            // to hold the value of the variable

    cur_entry->params[0].type = INT_PARAM;                  // Initialize new variable's value to
    cur_entry->params[0].value.int_param = 0;               // an integer with value of 0

    return 0;
}


//---------------------------------------------------------------------------
// Defines "!" for storing values in variables
//
// Stack args:
//   * top: variable address
//   * top-1: value
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int bang_code(struct FMState *state, struct FMEntry *entry) {
    int top = state->stack_top;

    if (top + 1 < 2) {                                       // Check that stack has at least 2 elems
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    struct FMParameter *variable = &(state->stack[top]);    // Access
    struct FMParameter *value = &(state->stack[top-1]);     // stack arguments

    if (variable->type != ENTRY_PARAM) {                    // Make sure "variable" is an entry
        FMC_abort(state, "Exepcting a variable", __FILE__, __LINE__);
        return -1;
    }

    struct FMEntry *variable_entry = variable->value.entry_param;

    FMC_delete_param(&(variable_entry->params[0]));         // Delete variable's param
    variable_entry->params[0] = *value;                     // Copy value into variable
    FMC_null_param(value);                                  // NULL out value

    if (FMC_drop(state) < 0) {return -1;}                   // Drop both params
    if (FMC_drop(state) < 0) {return -1;}                   // from stack

    return 0;
}


//---------------------------------------------------------------------------
// Defines "@" for retrieving values from variables
//
// Stack args:
//   * top: variable address
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int at_code(struct FMState *state, struct FMEntry *entry) {
    int top = state->stack_top;
    if (top < 0) {                                          // Check that we have enough args
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    struct FMParameter *variable = &(state->stack[top]);    // Access stack arg

    if (variable->type != ENTRY_PARAM) {                    // Make sure "variable" is an entry
        FMC_abort(state, "Exepcting a variable", __FILE__, __LINE__);
        return -1;
    }
    struct FMEntry *variable_entry = variable->value.entry_param;

    struct FMParameter value;
    if (FMC_copy_param(state, &(variable_entry->params[0]),
                       &value) < 0) {                       // Copy variable's param into value..
        return -1;
    }

    if (FMC_drop(state) < 0) {return -1;}                   // Drop stack arg
    if (FMC_push(state, value) < 0) {return -1;}            // ..and push onto stack
    return 0;
}
