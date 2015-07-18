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
// Unconditionally jumps to index
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int jmp_code(struct FMState *state, struct FMEntry *entry) { 
    state->next_instruction.index =
            entry->params[0].value.int_param;               // jmp to specified index
    return 0;
}


//---------------------------------------------------------------------------
// Allocates a pseudo entry with one param for a jump index and adds to entry
//
// This is added as the |entry|'s next parameter.
//
// Args:
//   * entry: The colon definition currently being compiled
//
// Returns a pointer to the |entry|'s next parameter or NULL if something
// went wrong.
//---------------------------------------------------------------------------
static
struct FMParameter *add_pseudo_param(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter *result =
        entry->params + entry->num_params;                  // Get definition's next parameter

    if (NULL == (result->value.entry_param =
                 malloc(sizeof (struct FMEntry)))) {        // Allocate memory for pseudo entry,
        FMC_abort(state, "malloc failed",
                  __FILE__, __LINE__);                      // aborting and returning if there was
        return NULL;                                        // a problem
    }

    if (NULL == (result->value.entry_param->params =
                 malloc(sizeof (struct FMParameter)))) {    // Allocate memory pseudo entry's param,
        FMC_abort(state, "malloc failed",                   
                  __FILE__, __LINE__);                      // aborting and
        FMC_delete_entry(result->value.entry_param);        // deleting entry if there was
        return NULL;                                        // a problem
    }
    result->type = PSEUDO_ENTRY_PARAM;                     // Indicate that it's a pseudo entry
    result->value.entry_param->params[0].type = INT_PARAM; // whose own param holds an instruction index

    entry->num_params++;                                    // Otherwise, increase param count for entry and
    return result;                                          // return a pointer to the new param
}


//---------------------------------------------------------------------------
// Pushes pseudo entry onto return stack to finish up later
//
// Args:
//   * pseudo_entry_index: index of the pseudo entry in its parent's definition
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int push_pseudo_entry(struct FMState *state, struct FMParameter *pseudo_entry,
                      int pseudo_entry_index) {
    struct FMInstruction jmp_index;                         // Use an instruction
    jmp_index.entry = pseudo_entry->value.entry_param;      // to package the pseudo entry in an "instruction",
    jmp_index.index = pseudo_entry_index;                   // noting its index in its definition, and
    if (FMC_rpush(state, jmp_index) < 0) {                  // then push it onto the return stack for later
        return -1;
    }
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

    struct FMParameter *param_p;                            // Declare pointer to pseudo entry and
    if (NULL ==
        (param_p = add_pseudo_param(state, entry))) {       // allocate some space for it
        return -1;
    }

    int if_index = entry->num_params - 1;                   // Get index of our pseudo entry
    param_p->value.entry_param->code = jmp_false_code;      // "IF" uses a jmp false construct whose
    if (push_pseudo_entry(state, param_p, if_index) < 0) {  // jmp index we have to fill out later
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


//---------------------------------------------------------------------------
// Implements the ELSE word
//
// Args:
//   * entry: colon definition currently being compiled
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int ELSE_code(struct FMState *state, struct FMEntry *entry) {
    if (state->compile != 1) {                              // ELSE is a compile-time only word
        FMC_abort(state, "ELSE can only be executed in compile mode.", __FILE__, __LINE__);
        return -1;
    }

    int rtop = state->rstack_top;                           // Get top of return stack

    if (rtop < 0) {                                         // Check that we have enough args
        FMC_abort(state, "Return stack underflow", __FILE__, __LINE__);
        return -1;
    }

    // Pop the return stack to get the previous jump entry to fill out
    struct FMInstruction previous_jmp_entry;
    if (FMC_rpop(state, &previous_jmp_entry) < 0) {
        return -1;
    }

    // Add unconditional jump at the end of the "true" branch of the conditional
    // (which is right here)
    struct FMParameter *param_p;                            // Declare pointer to pseudo entry and
    if (NULL ==
        (param_p = add_pseudo_param(state, entry))) {       // allocate some space for it
        return -1;
    }

    int else_index = entry->num_params - 1;                 // Get index of our pseudo entry
    param_p->value.entry_param->code = jmp_code;            // "ELSE" uses a jmp construct whose
    if (push_pseudo_entry(state, param_p,
                          else_index) < 0) {                // jmp index we have to fill out later
        FMC_delete_param(param_p);                          // (delete this entry and return if
        return -1;                                          // there was a problem)
    }


    // Fill out previous jump entry
    struct FMEntry *pseudo_entry =
        previous_jmp_entry.entry;                           // Get pseudo entry to tie up

    pseudo_entry->params[0].value.int_param =
        entry->num_params;                                  // jmp param is next instruction

    return 0;
}


//---------------------------------------------------------------------------
// Implements the WHILE word
//
// WHILE is essentially equivalent to an IF
//
// Args:
//   * entry: colon definition currently being compiled
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int WHILE_code(struct FMState *state, struct FMEntry *entry) {
    return IF_code(state, entry);
}


//---------------------------------------------------------------------------
// Implements the REPEAT word
//
// Does an uncondtional jump to the <TEST> word in the loop
//
// Args:
//   * entry: colon definition currently being compiled
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int REPEAT_code(struct FMState *state, struct FMEntry *entry) {
    if (state->compile != 1) {                              // REPEAT is a compile-time only word
        FMC_abort(state, "REPEAT can only be executed in compile mode.", __FILE__, __LINE__);
        return -1;
    }

    int rtop = state->rstack_top;                           // Get top of return stack

    if (rtop < 0) {                                         // Check that we have enough args
        FMC_abort(state, "Return stack underflow", __FILE__, __LINE__);
        return -1;
    }

    // Pop the return stack to get the "WHILE" entry to fill out
    struct FMInstruction while_entry;
    if (FMC_rpop(state, &while_entry) < 0) {
        return -1;
    }
    if (while_entry.index < 1) {
        FMC_abort(state, "WHILE..REPEAT missing its test!", __FILE__, __LINE__);
        return -1;
    }

    // Add unconditional jump to top of loop
    struct FMParameter *param_p;                            // Declare pointer to pseudo entry and
    if (NULL ==
        (param_p = add_pseudo_param(state, entry))) {       // allocate some space for it
        return -1;
    }
    param_p->value.entry_param->code = jmp_code;            // Unconditionally jump to
    param_p->value.entry_param->params[0].value.int_param =
        while_entry.index - 1;                              // beginning of loop (instruction before WHILE)

    // Update "WHILE" entry
    while_entry.entry->params[0].value.int_param =
        entry->num_params;                                  // On loop end, jump to instruction after "REPEAT"

    return 0;
}
