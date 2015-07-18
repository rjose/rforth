#include <stdio.h>
#include <stdlib.h>

#include "FMCore.h"

//---------------------------------------------------------------------------
// If top of stack is false, jumps to params index. Otherwise, goes to next instruction
//
// Stack args:
//   * top: int value
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int jmp_false_code(struct FMState *state, struct FMEntry *entry) { 
    int top = state->stack_top;

    if (top < 0) {                                          // Check that we have enough args
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }
    struct FMParameter *value = &(state->stack[top]);       // Get value

    if (value->type != INT_PARAM) {                         // Abort if not an int
        FMC_abort(state, "Expecting an integer", __FILE__, __LINE__);
        return -1;
    }

    if (value->value.int_param == 0) {                      // If false..
        state->next_instruction.index =
            entry->params[0].value.int_param;               // ..jmp to specified index
    }
    else {
        state->next_instruction.index++;                    // Otherwise, go to next instruction in def
    }

    FMC_drop(state);                                        // Pop value off of stack
    return 0;
}


//---------------------------------------------------------------------------
// Implements the IF word
//
// Args:
//   * entry: colon definition currently being compiled
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int IF_code(struct FMState *state, struct FMEntry *entry) {
    if (state->compile != 1) {                              // IF is a compile-time only word
        FMC_abort(state, "IF can only be executed in compile mode.", __FILE__, __LINE__);
        return -1;
    }

    struct FMParameter *param_p =
        entry->params + entry->num_params;                  // Get definition's next parameter

    if (NULL == (param_p->value.entry_param =
                 malloc(sizeof (struct FMEntry)))) {        // Allocate memory for pseudo entry,
        FMC_abort(state, "malloc failed",
                  __FILE__, __LINE__);                      // aborting and returning if there was
        return -1;                                          // a problem
    }

    if (NULL == (param_p->value.entry_param->params =
                 malloc(sizeof (struct FMParameter)))) {    // Allocate memory pseudo entry's param,
        FMC_abort(state, "malloc failed",                   
                  __FILE__, __LINE__);                      // aborting and
        FMC_delete_entry(param_p->value.entry_param);       // deleting entry if there was
        return -1;                                          // a problem
    }

    entry->num_params++;                                    // Otherwise, definition has another param

    param_p->type = PSEUDO_ENTRY_PARAM;                     // And that parameter is a pseudo entry
    param_p->value.entry_param->params[0].type = INT_PARAM; // whose own param holds an instruction index
    param_p->value.entry_param->code = jmp_false_code;      // that is jumped to when stack top is false

    struct FMInstruction jmp_index;                         // Create a pseudo instruction so
    jmp_index.entry = param_p->value.entry_param;           // we can fill out the instruction index later,
    if (FMC_rpush(state, jmp_index) < 0) {                  // and push it onto the return stack
        FMC_delete_param(param_p);                          // (delete this entry and return if
        return -1;                                          // there was a problem)
    }

    return 0;                                               // Otherwise, all is good
}


//---------------------------------------------------------------------------
// Implements the THEN word
//
// Args:
//   * entry: colon definition currently being compiled
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int THEN_code(struct FMState *state, struct FMEntry *entry) {
    if (state->compile != 1) {                              // THEN is a compile-time only word
        FMC_abort(state, "THEN can only be executed in compile mode.", __FILE__, __LINE__);
        return -1;
    }

    int rtop = state->rstack_top;                           // Get top of return stack

    if (rtop < 0) {                                         // Check that we have enough args
        FMC_abort(state, "Return stack underflow", __FILE__, __LINE__);
        return -1;
    }

    struct FMEntry *pseudo_entry =
        state->rstack[rtop].entry;                          // Get pseudo entry to tie up

    pseudo_entry->params[0].value.int_param =
        entry->num_params;                                  // jmp param is next instruction

    if (FMC_rdrop(state) < 0) {                             // Pop return stack
        return -1;
    }
    
    return 0;
}
