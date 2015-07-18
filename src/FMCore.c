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
char *PSEUDO_ENTRY_PARAM = "pseudo_entry";


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
int NOP_code(struct FMState *state, struct FMEntry *entry) {
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
    state->rstack_top = -1;                            // Nothing in return stack
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
    cur_entry->code = NOP_code;                        // Default code to do nothing

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
    if (param->type == STRING_PARAM) {                      // If a string,
        free(param->value.string_param);                    // free its memory
    }
    else if (param->type == ENTRY_PARAM) {                  // If an entry,
        FMC_delete_entry(param->value.entry_param);         // delete the entry contents
        free(param->value.entry_param);                     // and then free the entry itself
    }
}


//---------------------------------------------------------------------------
// Sets value to NULL if memory for it was allocated
//---------------------------------------------------------------------------
void FMC_null_param(struct FMParameter *param) {
    if (param->type == STRING_PARAM) {
        param->value.string_param = NULL;
    }
}


//---------------------------------------------------------------------------
// Creates a copy of a parameter, allocating memory if needed
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int FMC_copy_param(struct FMState *state, struct FMParameter *param, struct FMParameter *dest) {
    dest->type = param->type;                              // Copy the param type
    dest->value.int_param = 0;                             // Zero out value to start

    if (dest->type == STRING_PARAM) {                      // Handle strings
        size_t len = strlen(param->value.string_param)+1;  // Include NUL in length
        if (len > 0 && (dest->value.string_param = malloc(len)) == NULL) {
            FMC_abort(state, "malloc failed", __FILE__, __LINE__);
            return -1;
        }
        strncpy(dest->value.string_param, param->value.string_param, len);
    }
    else {
        dest->value.int_param = param->value.int_param;    // Since value is a union, this handles all other cases
    }
    return 0;
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
// Pushes value onto forth return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: If return stack is full, this aborts
//---------------------------------------------------------------------------
int FMC_rpush(struct FMState *state, struct FMInstruction value) {
    if (state->rstack_top == MAX_RETURN_STACK - 1) {        // Abort if stack is full
        FMC_abort(state, "Return stack overflow", __FILE__, __LINE__);
        return -1;
    }

    state->rstack[++state->rstack_top] = value;
    return 0;
}

//---------------------------------------------------------------------------
// Pops value from return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// The previous top of stack is returned via |res|.
//---------------------------------------------------------------------------
int FMC_rpop(struct FMState *state, struct FMInstruction *res) {
    if (state->rstack_top == -1) {                    // If stack is empty..
        FMC_abort(state, "Return stack underflow",
                 __FILE__, __LINE__);                       // ..abort,
        return -1;                                          // and return.
    }

    *res = state->rstack[state->rstack_top];    // Otherwise, set res to top of return stack,
    state->rstack_top--;                              // drop the top of return stack,
    return 0;                                               // and indicate success
}


//---------------------------------------------------------------------------
// Drops top of return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: Whatever's on the return stack is owned by someone, so no memory
//       should be freed here.
//---------------------------------------------------------------------------
int FMC_rdrop(struct FMState *state) {
    if (state->rstack_top == -1) {                     // Abort if stack is empty
        FMC_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    state->rstack_top--;                                // Drop the item
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
