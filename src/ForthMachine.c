#include "ForthMachine.h"
#include "defines.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

//---------------------------------------------------------------------------
// String constants and macros
//---------------------------------------------------------------------------
static char *GENERIC_FM = "GENERIC";

//================================================
// Internal Functions
//================================================


//---------------------------------------------------------------------------
// Tries to convert a word into a number param.
//
// Return value:
//   *  0: Success
//   * -1: Unable to parse word as a number
//
// This updates the fields in param.
//---------------------------------------------------------------------------
static
int load_number_param(const char *word, struct FMParameter *param) {
    double double_val;
    int int_val;

    int result = -1;
    if (sscanf(word, "%lf", &double_val) == 1) {       // If was a number
        int_val = double_val;                          // Get int truncation
        if (double_val - (double) int_val == 0) {      // If num is int...
            param->type = INT_PARAM;                   // store value as int
            param->value.int_param = int_val;
        }
        else {
            param->type = DOUBLE_PARAM;                // Otherwise, store value as double
            param->value.double_param = double_val;
        }
        result = 0;
    }
    return result;
}


//---------------------------------------------------------------------------
// Loads a param with an entry value
//---------------------------------------------------------------------------
static
void load_entry_param(struct FMEntry *entry_val, struct FMParameter *param) {
    param->type = ENTRY_PARAM;
    param->value.entry_param = entry_val;
}


//---------------------------------------------------------------------------
// Executes a colon definition
//
// Args:
//   * entry: colon definition to execute
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int run_colon_def_code(struct FMState *state, struct FMEntry *entry) {
    FMC_rpush(state, state->next_instruction);                // Push previous instruction onto ret stack
    state->next_instruction.entry = entry;                  // Set next instruction to first one of this entry
    state->next_instruction.index = 0;
    return 0;
}


//---------------------------------------------------------------------------
// Exits a definition
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int exit_code(struct FMState *state, struct FMEntry *entry) {
    struct FMInstruction previous;
    if (FMC_rpop(state, &previous) != 0) {                    // Pop previous instruction from ret stack
        return -1;                                          // (returning -1 if an abort)
    }

    state->next_instruction = previous;                     // Set next instruction to previous value
    return 0;
}


//---------------------------------------------------------------------------
// Compiles next word in a colon definition to |entry->params|
//
// Args:
//   * state:  Forth machine state
//   * entry:  Entry whose definition is being compiled
//
// Return value:
//   *  0: Successfully compiled word
//   *  1: Compiled the ";" word, meaning the definition is complete
//   * -1: Aborted
//
// NOTE: This updates entry->num_params on success
// ALSO: We assume that entry->params has enough space for one more entry
//---------------------------------------------------------------------------
static
int compile_word(struct FMState *state, struct FMEntry *entry) {
#define  RETURN_FROM_COMPILE(status)   state->compile = 0; return status;

    state->compile = 1;                               // Put forth machine in compile mode

    if (FMC_read_word(state) != 0) {                  // If no next word, return -1
        FMC_abort(state, "Incomplete definition",
                 __FILE__, __LINE__);
        RETURN_FROM_COMPILE(-1);
    }

    struct FMParameter *param_p =
        entry->params + entry->num_params;            // Compiled word goes here

    struct FMEntry *word_entry =
        FMC_find_entry(state, state->word_buffer);    // Look up word entry

    int result = 0;

    if (word_entry && word_entry->immediate) {        // If an immediate word,
        result = word_entry->code(state, entry);      // execute it with entry being compiled
        RETURN_FROM_COMPILE(result);
    }
    else if (word_entry) {                             // If it's just a word,
        load_entry_param(word_entry, param_p);         // store it in the next parameter,
        entry->num_params++;                           //
        result = 0;                                    // and indicate successful compile
        
        if (word_entry->code == exit_code) {           // If the entry is an "exit" (i.e., ";"),
            result = 1;                                // indicate definition is complete
        }
    }
    else {                                             // If not an entry, try word as number
        if (load_number_param(state->word_buffer, param_p) == 0) {
            entry->num_params++;                       // On success, increment param count
            result = 0;                                // and indicate that word was compiled.
        }
        else {                                         // Otherwise, abort compilation
            snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                     "%s '%s'", "Unable to compile:",state->word_buffer);
            FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
            RETURN_FROM_COMPILE(-1);
        }
    }

    RETURN_FROM_COMPILE(result);
}


//---------------------------------------------------------------------------
// Interprets next word in the input string
//
// If the next word is a dictionary entry, set the next instruction to be
// the first instruction of the entry.
//
// Return value:
//   * 0: Nothing to interpret
//   * 1: Interpreted word
//---------------------------------------------------------------------------
static
int interpret_next_word(struct FMState *state) {
    if (FMC_read_word(state) < 0) {                             // If couldn't read,
        return 0;                                           // there's nothing to interpret
    }
    const char *word = state->word_buffer;
    struct FMEntry *entry = FMC_find_entry(state, word);

    // Handle an entry
    if (entry != NULL) {                                    // If entry in dictionary,
        if (entry->code(state, entry) < 0) {                // execute its code,
            return 0;                                       // returning 0 on failure..
        }
        else {
            return 1;                                       // ..and 1 on success
        }
    }


    // Handle a number
    struct FMParameter value;
    if (load_number_param(word, &value) == 0) {
        // TODO: Check return value
        FMC_push(state, value);                              // Push number onto stack,
        return 1;                                           // and indicate success
    }
    else {
        snprintf(FMC_err_message, ERR_MESSAGE_LEN, "Unhandled word: %s", word);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return 0;
    }

    return 0;                                               // Shouldn't get here, but just in case.
}


//---------------------------------------------------------------------------
// Compiles a definition
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int colon_code(struct FMState *state, struct FMEntry *entry) {
#define M_delete_entry()   FMC_delete_entry(cur_entry); state->last_entry_index--;
#define NUM_ALLOCATED_PARAMS   10

    // Get name of entry to define
    if (FMC_read_word(state) < 0) {                         // If couldn't read word,
        return 0;                                           // there's nothing to interpret
    }
    const char *name = state->word_buffer;

    if (FMC_create_entry(state, name) != 0) {               // Create entry,
        return -1;                                          // (returning -1 on failure)
    }

    struct FMEntry *cur_entry = M_last_entry(state);        // Get a pointer to newly created entry and
    cur_entry->code = run_colon_def_code;                   // set its code to be a colon def runner

    int start_return_stack_top = state->rstack_top;   // Note state of return stack before we start

    // Compile each word of the definition
    int params_left = 0;
    size_t param_size = sizeof(struct FMParameter);

    while(1) {
        if (params_left == 0) {                             // If no more space for parameters..
            cur_entry->params =
                realloc(cur_entry->params,
                        param_size * (cur_entry->num_params + NUM_ALLOCATED_PARAMS));
                                                            // ..allocate some space

            if (cur_entry->params == NULL) {                // If something went wrong with alloc,
                FMC_abort(state, "Unable to realloc", __FILE__, __LINE__);
                                                            // abort,
                M_delete_entry();                           // delete the entry we're working on,
                return -1;                                  // and return an abort
            }
            params_left = NUM_ALLOCATED_PARAMS;             // Otherwise, we have space for more params
        }

        int status = compile_word(state, cur_entry);        // Compile next word into entry's params
        if (status == 1) {                                  // If last word was an "exit", we're done.
            break;
        }
        if (status == -1) {                                 // If something went wrong with compile,
            M_delete_entry();                               // delete the entry we're working on,
            return -1;                                      // and return an abort
        }

        params_left--;                                      // Otherwise, we've used a parameter slot
    }

    // Resize memory to number of params
    if ((cur_entry->params = realloc(cur_entry->params, param_size * cur_entry->num_params)) == NULL) {
        FMC_abort(state, "Unable to realloc", __FILE__, __LINE__);
        M_delete_entry();
        return -1;
    }

    // Check that the return stack is unchanged
    if (start_return_stack_top != state->rstack_top) {
        FMC_abort(state, "Return stack was changed when compiling a colon def", __FILE__, __LINE__);
        M_delete_entry();
        return -1;
   }

    return 0;
}


//---------------------------------------------------------------------------
// If next instruction, execute it
//
// Return value:
//   * 1: Executed instruction
//   * 0: Nothing more to execute
//---------------------------------------------------------------------------
static
int step_colon_def(struct FMState *state) {
    if (!state->next_instruction.entry) {
        return 0;
    }
    struct FMEntry *def_entry = state->next_instruction.entry;
    struct FMParameter *cur_instruction = &def_entry->params[state->next_instruction.index];
    struct FMParameter tmp_param;                           // Used in case we need to clone a param

    if (cur_instruction->type == INT_PARAM ||
        cur_instruction->type == DOUBLE_PARAM ||
        cur_instruction->type == STRING_PARAM) {            // If an int, double, or string..
        if (FMC_copy_param(state, cur_instruction,
                           &tmp_param) == -1) {             // ..copy param,
            return 0;
        }
        if (FMC_push(state, tmp_param) < 0) {               // and push it onto the stack
            return 0;
        }
        state->next_instruction.index++;                    // and then go to next instruction.
    }
    else if (cur_instruction->type == PSEUDO_ENTRY_PARAM) {
        struct FMEntry *pseudo_entry =
            cur_instruction->value.entry_param;             // Get pointer to pseudo entry
        return (pseudo_entry->
                code(state, pseudo_entry) == 0);            // and execute it, returning 1 if OK
    }
    else if (cur_instruction->type == ENTRY_PARAM) {        // If an entry,
        state->next_instruction.index++;                    // advance to next instruction,
        struct FMEntry *word =
            cur_instruction->value.entry_param;             // Get pointer to instruction's word,
        return (word->code(state, word) == 0);              // and execute, returning 1 if OK
    }
    else {
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Unknown param type: %s",
                 cur_instruction->type);                    // Construct error message,
        FMC_abort(state,
                 FMC_err_message, __FILE__, __LINE__);        // abort,
        return -1;                                          // and indicate abort
    }

    return 1;                                               // Everything is good.
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
    FMC_clear_state(&result);                                   // Ensure state is cleared
    result.last_entry_index = -1;                           // Start with an empty dictionary

    // Add builtin words
    FMC_define_word(&result, ":", 0, colon_code);
    FMC_define_word(&result, ";", 0, exit_code);

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
    if (state->next_instruction.entry) {
        return step_colon_def(state);
    }
    else {
        return interpret_next_word(state);
    }
}
