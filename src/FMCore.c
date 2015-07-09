#include "FMCore.h"

#include "defines.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>


char FMC_err_message[ERR_MESSAGE_LEN];

//======================================
// String constants
//======================================
char *INT_PARAM = "int";
char *DOUBLE_PARAM = "double";
char *STRING_PARAM = "string";
char *ENTRY_PARAM = "entry";


//---------------------------------------------------------------------------
// Returns 1 if c is whitespace; 0 otherwise
//---------------------------------------------------------------------------
static
int is_whitespace(char c) {
    if (c == ' ' || c == '\t' || c == '\n') {
        return 1;
    }
    else {
        return 0;
    }
}

//---------------------------------------------------------------------------
// Do nothing
//
// Return value:
//   *  0: Success
//---------------------------------------------------------------------------
static
int nop_code(struct FMState *state, struct FMEntry *entry) {
    printf("NOP\n");
    return 0;
}




//======================================
// Public Functions
//======================================


//---------------------------------------------------------------------------
// Clears stack states, word state, and instruction pointer
//
// NOTE: This does *not* clear the dictionary
//---------------------------------------------------------------------------
void FMC_clear_state(struct FMState *state) {
    state->stack_top = -1;                             // Nothing in stack
    state->return_stack_top = -1;                      // Nothing in return stack
    state->word_len = 0;                               // No word has been read
    state->input_string = NULL;                        // No input has been set
    state->input_index = 0;                            // Input index is at the beginning
    state->next_instruction.entry = NULL;              // No instruction to execute next
    state->next_instruction.index = 0;
    state->compile = 0;                                // Not in compile mode
}


//---------------------------------------------------------------------------
// Prints message to STDERR and resets forth machine state
//---------------------------------------------------------------------------
void FMC_abort(struct FMState *state, const char *message, const char *file, int line) {
    fprintf(stderr, "ABORT: %s (at %s:%d)\n", message, file, line);

    // Free all strings on stack
    for (int i=0; i <= state->stack_top; i++) {
        struct FMParameter *item = &state->stack[i];
        if (item->type == STRING_PARAM) {
            free(item->value.string_param);
            item->value.string_param = NULL;
        }
    }

    FMC_clear_state(state);
}

//---------------------------------------------------------------------------
// Reads next word from input string
//
// Word is stored in state.word_buffer and its length in state.word_len
//
// Return value:
//   *  0: Success
//   * -1: No word
//   * -2: Word is longer than MAX_WORD_LEN
//---------------------------------------------------------------------------
int FMC_read_word(struct FMState *state) {
#define M_cur_char()    (state->input_string[state->input_index])
    
    state->word_len = 0;                                    // Reset word

    if (state->input_string == NULL) {                      // If no input string, no word
        return -1;
    }

    // Skip whitespace
    while (M_cur_char() != NUL && is_whitespace(M_cur_char())) {
        state->input_index++;
    }
    
    if (M_cur_char() == NUL) {                              // If at end of string, no word
        return -1;
    }

    // Copy word into buffer
    while(state->word_len <= MAX_WORD_LEN) {
        if (is_whitespace(M_cur_char())) {                  // Stop if hit whitespace,
            state->input_index++;                           // but advance past whitespace char first
            break;
        }
        if (M_cur_char() == NUL) {                          // Stop if hit EOS
            break;
        }
        if (state->word_len == MAX_WORD_LEN) {              // If we're about to exceed word_buffer...
            state->word_len = 0;                            // reset word,
            FMC_abort(state, "Dictionary full", __FILE__, __LINE__);
            return -2;                                      // and indicate error
        }

        state->word_buffer[state->word_len++] =             // Store next character
            M_cur_char();
        state->input_index++;                               // Go to next char in input
    }

    state->word_buffer[state->word_len] = NUL;              // When done, NUL terminate word,
    return 0;                                               // and indicate success
}

//---------------------------------------------------------------------------
// Looks up name in dictionary
//
// Returns pointer to entry or NULL if not found.
//---------------------------------------------------------------------------
struct FMEntry *FMC_find_entry(struct FMState *state, const char *name) {
    int cur_index = state->last_entry_index;

    struct FMEntry *result = NULL;
    while (cur_index >= 0) {                                // Start from last entry and go backwards
        if (strncmp(state->dictionary[cur_index].name,
                    name, NAME_LEN) == 0) {                 // If names match...
            result = &(state->dictionary[cur_index]);       // result is address of matching entry...
            break;                                          // and we're done with this loop.
        }
        cur_index--;
    }
    return result;
}


//---------------------------------------------------------------------------
// Creates an FMParameter of "string" type
//---------------------------------------------------------------------------
struct FMParameter FMC_make_string_param(char *string) {
    struct FMParameter result;
    result.type = STRING_PARAM;
    result.value.string_param = string;
    return result;
}


//---------------------------------------------------------------------------
// Creates new entry
//
// Return value:
//   *  0: Success
//   * -2: Dictionary full
//---------------------------------------------------------------------------
int FMC_create_entry(struct FMState *state, const char *name) {
    if (M_is_dictionary_full(state)) {                // If dictonary full, return -2
        return -2;
    }

    state->last_entry_index++;                         // Go to next empty entry
    struct FMEntry *cur_entry = M_last_entry(state);

    strncpy(cur_entry->name,
            state->word_buffer, NAME_LEN);             // Entry name is last word read
    cur_entry->immediate = 0;                          // Default to not "immediate"
    cur_entry->pseudo_entry = 0;                       // Entries in dictionary aren't pseudo entries
    cur_entry->code = nop_code;                        // Default code to do nothing

    cur_entry->params = NULL;
    cur_entry->num_params = 0;                         // Start with no params

    return 0;
}


//---------------------------------------------------------------------------
// Frees all memory in param
//
// NOTE: Only strings are allocated
//---------------------------------------------------------------------------
void FMC_delete_param(struct FMParameter *param) {
    if (param->type == STRING_PARAM) {
        free(param->value.string_param);
    }
}


//---------------------------------------------------------------------------
// Frees all memory in entry
//---------------------------------------------------------------------------
void FMC_delete_entry(struct FMEntry *entry) {
    for (int i=0; i < entry->num_params; i++) {        // Free any allocated params
        FMC_delete_param(&entry->params[i]);
    }
    free(entry->params);                               // Free allocated params array
    // TODO: If pseudo_entry, delete entry, too.
}


//---------------------------------------------------------------------------
// Pushes value onto forth stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: If stack is full, this aborts
//---------------------------------------------------------------------------
int FMC_push(struct FMState *state, struct FMParameter value) {
    if (state->stack_top == MAX_STACK - 1) {           // Abort if stack is full
        FMC_abort(state, "Stack overflow", __FILE__, __LINE__);
        return -1;
    }

    state->stack[++state->stack_top] = value;
    return 0;
}


//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: Other forth machines use this
//---------------------------------------------------------------------------
int FMC_drop(struct FMState *state) {
#define M_top(state)   &((state)->stack[(state)->stack_top])
    
    if (state->stack_top == -1) {                      // Abort if stack is empty
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    // If top of stack is a string, then free it
    struct FMParameter *top = M_top(state);
    if (top->type == STRING_PARAM) {
        free(top->value.string_param);                 // Free the string memory
        top->value.string_param = NULL;                // NULL out pointer
    }

    state->stack_top--;                                // Drop the item
    return 0;
}


//---------------------------------------------------------------------------
// Defines a new word in the dictionary
//
// NOTE: Other forth machines use this function, too.
//---------------------------------------------------------------------------
void FMC_define_word(struct FMState *state, const char* name, int immediate, code_p code) {
    if (M_is_dictionary_full(state)) {
        FMC_abort(state, "Dictionary full", __FILE__, __LINE__);
        return;
    }
    state->last_entry_index++;                              // Claim next empty entry
    struct FMEntry *cur_entry = M_last_entry(state);
    strncpy(cur_entry->name, name, NAME_LEN);
    cur_entry->immediate = immediate;
    cur_entry->code = code;
}


// TODO: Consider making this a more generic function (like clone_parameter)
//---------------------------------------------------------------------------
// Clones a string parameter from src and stores in dest
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int FMC_clone_string_param(struct FMState *state, struct FMParameter *src, struct FMParameter *dest) {
    if (src->type != STRING_PARAM) {                        // If not a STRING_PARAM..
        FMC_abort(state, "Can only clone string params",
                 __FILE__, __LINE__);                       // ..abort
        return -1;
    }

    // Copy string
    size_t len = strlen(src->value.string_param);           // Get string length,
    char *new_string;
    if ((new_string = malloc(len+1)) == NULL) {             // allocate space for it,
        FMC_abort(state, "malloc failure",                   // (aborting on failure)
                 __FILE__, __LINE__);
        return -1;
    }
    strncpy(new_string, src->value.string_param, len);      // Copy string
    new_string[len] = NUL;                                  // (NUL terminating it, too)

    // Store in destination
    dest->type = STRING_PARAM;
    dest->value.string_param = new_string;

    return 0;                                               // Success
}
