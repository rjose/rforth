#include "ForthMachine.h"
#include "defines.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

//---------------------------------------------------------------------------
// String constants
//---------------------------------------------------------------------------
static char *GENERIC_FM = "GENERIC";


//================================================
// Internal Functions
//================================================

//---------------------------------------------------------------------------
// Clears stack states, word state, and instruction pointer
//
// NOTE: This does *not* clear the dictionary
//---------------------------------------------------------------------------
static
void clear_state(struct FMState *state) {
    state->stack_top = -1;                             // Nothing in stack
    state->return_stack_top = -1;                      // Nothing in return stack
    state->word_len = 0;                               // No word has been read
    state->input_string = NULL;                        // No input has been set
    state->input_index = 0;                            // Input index is at the beginning
    state->next_instruction = NULL;                    // No instruction to execute next
    state->compile = 0;                                // Not in compile mode
}

//---------------------------------------------------------------------------
// Creates the builtins for a generic interpreter
//---------------------------------------------------------------------------
static
void add_builtin_words(struct FMState *state) {
    /*
    define_word(state, ".\"", 1, dot_quote_code);
    define_word(state, "DROP", 0, drop_code);
    define_word(state, ":", 0, colon_code);
    define_word(state, ";", 0, exit_code);
    */
}


//================================================
// Public Functions
//================================================

//---------------------------------------------------------------------------
// Creates an empty FMState object
//
// Also initializes data structures where appropriate
//---------------------------------------------------------------------------
struct FMState FM_CreateState() {
    struct FMState result;

    strncpy(result.type, GENERIC_FM, TYPE_LEN);             // Classify as a GENERIC machine
    clear_state(&result);                                   // Ensure state is cleared
    result.last_entry_index = -1;                           // Start with an empty dictionary

    // Add builtin words
    add_builtin_words(&result);                             // Add basic words

    return result;
}

//---------------------------------------------------------------------------
// Sets the current input string for a forth machine
//---------------------------------------------------------------------------
void FM_SetInput(struct FMState *state, const char *string) {
    state->input_string = string;                           // Set input string
    state->input_index = 0;                                 // Start at beginning of input
}


//---------------------------------------------------------------------------
// Executes next word/instruction in forth machine
//
// Return value:
//   * 1: Executed word/instruction
//   * 0: Nothing more to execute
//---------------------------------------------------------------------------
int FM_Step(struct FMState *state) {
    // TODO: Implement
    return 0;
}
