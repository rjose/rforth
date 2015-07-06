#include "ForthMachine.h"
#include "defines.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

//---------------------------------------------------------------------------
// String constants and macros
//---------------------------------------------------------------------------
static char *GENERIC_FM = "GENERIC";

static char *INT_PARAM = "int";
static char *DOUBLE_PARAM = "double";
static char *STRING_PARAM = "string";
static char *ENTRY_PARAM = "entry";

#define ERR_MESSAGE_LEN  256
static char M_err_message[ERR_MESSAGE_LEN];

#define M_is_dictionary_full(state)   ((state)->last_entry_index >= MAX_ENTRIES - 1)
#define M_last_entry(state)   (&((state)->dictionary[(state)->last_entry_index]))


//================================================
// Internal Functions
//================================================

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
    state->next_instruction.entry = NULL;              // No instruction to execute next
    state->next_instruction.index = 0;
    state->compile = 0;                                // Not in compile mode
}

//---------------------------------------------------------------------------
// Prints message to STDERR and resets forth machine state
//---------------------------------------------------------------------------
static
void fm_abort(struct FMState *state, const char *message, const char *file, int line) {
    fprintf(stderr, "ABORT: %s (at %s:%d)\n", message, file, line);

    // Free all strings on stack
    for (int i=0; i <= state->stack_top; i++) {
        struct FMParameter *item = &state->stack[i];
        if (item->type == STRING_PARAM) {
            free(item->value.string_param);
            item->value.string_param = NULL;
        }
    }

    clear_state(state);
}


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
// Reads next word from input string
//
// Word is stored in state.word_buffer and its length in state.word_len
//
// Return value:
//   *  0: Success
//   * -1: No word
//   * -2: Word is longer than MAX_WORD_LEN
//---------------------------------------------------------------------------
static
int read_word(struct FMState *state) {
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
    while(state->word_len < MAX_WORD_LEN) {
        if (is_whitespace(M_cur_char())) {                  // Stop if hit whitespace,
            state->input_index++;                           // but advance past whitespace char first
            break;
        }
        if (M_cur_char() == NUL) {                          // Stop if hit EOS
            break;
        }
        if (state->word_len == MAX_WORD_LEN) {              // If we're about to exceed word_buffer...
            state->word_len = 0;                            // reset word,
            fm_abort(state, "Dictionary full", __FILE__, __LINE__);
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
static
struct FMEntry *find_entry(struct FMState *state, const char *name) {
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
// Do nothing
//
// Return value:
//   *  0: Success
//---------------------------------------------------------------------------
int nop_code(struct FMState *state, struct FMEntry *entry) {
    printf("NOP\n");
    return 0;
}


//---------------------------------------------------------------------------
// Creates new entry
//
// Return value:
//   *  0: Success
//   * -2: Dictionary full
//---------------------------------------------------------------------------
static
int create_entry(struct FMState *state, const char *name) {
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
static
void delete_param(struct FMParameter *param) {
    if (param->type == STRING_PARAM) {
        free(param->value.string_param);
    }
}


//---------------------------------------------------------------------------
// Frees all memory in entry
//---------------------------------------------------------------------------
static
void delete_entry(struct FMEntry *entry) {
    for (int i=0; i < entry->num_params; i++) {        // Free any allocated params
        delete_param(&entry->params[i]);
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
static
int fs_push(struct FMState *state, struct FMParameter value) {
    if (state->stack_top == MAX_STACK - 1) {           // Abort if stack is full
        fm_abort(state, "Stack overflow", __FILE__, __LINE__);
        return -1;
    }

    state->stack[++state->stack_top] = value;
    return 0;
}


//---------------------------------------------------------------------------
// Pushes value onto return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: If stack is full, this aborts
//---------------------------------------------------------------------------
static
int rs_push(struct FMState *state, struct FMInstruction value) {
    if (state->return_stack_top == MAX_RETURN_STACK - 1) {  // If stack is full..
        fm_abort(state, "Return stack overflow",
                 __FILE__, __LINE__);                       // ..abort
        return -1;
    }

    state->return_stack[++state->return_stack_top] = value;
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
static
int rs_pop(struct FMState *state, struct FMInstruction *res) {
    if (state->return_stack_top == -1) {                    // If stack is empty..
        fm_abort(state, "Return stack underflow",
                 __FILE__, __LINE__);                       // ..abort,
        return -1;                                          // and return.
    }

    *res = state->return_stack[state->return_stack_top];    // Otherwise, set res to top of return stack,
    state->return_stack_top--;                              // drop the top of return stack,
    return 0;                                               // and indicate success
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
    rs_push(state, state->next_instruction);                // Push previous instruction onto ret stack
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
    if (rs_pop(state, &previous) != 0) {                    // Pop previous instruction from ret stack
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

    if (read_word(state) != 0) {                      // If no next word, return -1
        fm_abort(state, "Incomplete definition",
                 __FILE__, __LINE__);
        RETURN_FROM_COMPILE(-1);
    }

    struct FMParameter *param_p =
        entry->params + entry->num_params;            // Compiled word goes here

    struct FMEntry *word_entry =
        find_entry(state, state->word_buffer);        // Look up word entry

    int result = 0;

    if (word_entry && word_entry->immediate) {        // If an immediate word,
        result = word_entry->code(state, entry);      // execute it with entry being compiled
        RETURN_FROM_COMPILE(result);
    }
    else if (word_entry) {                             // If it's just a word,
        load_entry_param(word_entry, param_p);         // store it in the next parameter,
        entry->num_params++;                           // increment the param count,
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
            snprintf(M_err_message, ERR_MESSAGE_LEN,
                     "%s '%s'", "Unable to compile:",state->word_buffer);
            fm_abort(state, M_err_message, __FILE__, __LINE__);
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
    if (read_word(state) < 0) {                             // If couldn't read,
        return 0;                                           // there's nothing to interpret
    }
    const char *word = state->word_buffer;
    struct FMEntry *entry = find_entry(state, word);

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
        fs_push(state, value);                              // Push number onto stack,
        return 1;                                           // and indicate success
    }
    else {
        snprintf(M_err_message, ERR_MESSAGE_LEN, "Unhandled word: %s", word);
        fm_abort(state, M_err_message, __FILE__, __LINE__);
        return 0;
    }

    return 0;                                               // Shouldn't get here, but just in case.
}


//---------------------------------------------------------------------------
// Defines a new word in the dictionary
//---------------------------------------------------------------------------
static
void define_word(struct FMState *state, const char* name, int immediate, code_p code) {
    if (M_is_dictionary_full(state)) {
        fm_abort(state, "Dictionary full", __FILE__, __LINE__);
        return;
    }
    state->last_entry_index++;                              // Claim next empty entry
    struct FMEntry *cur_entry = M_last_entry(state);
    strncpy(cur_entry->name, name, NAME_LEN);
    cur_entry->immediate = immediate;
    cur_entry->code = code;
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
#define M_delete_entry()   delete_entry(cur_entry); state->last_entry_index--;
#define NUM_ALLOCATED_PARAMS   10

    // Get name of entry to define
    if (read_word(state) < 0) {                             // If couldn't read word,
        return 0;                                           // there's nothing to interpret
    }
    const char *name = state->word_buffer;

    if (create_entry(state, name) != 0) {                   // Create entry,
        return -1;                                          // (returning -1 on failure)
    }

    struct FMEntry *cur_entry = M_last_entry(state);        // Get a pointer to newly created entry and
    cur_entry->code = run_colon_def_code;                   // set its code to be a colon def runner

    
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
                fm_abort(state, "Unable to realloc", __FILE__, __LINE__);
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
        fm_abort(state, "Unable to realloc", __FILE__, __LINE__);
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
int step_colon_def(struct FMState *state) {
    if (!state->next_instruction.entry) {
        return 0;
    }
    struct FMEntry *def_entry = state->next_instruction.entry;
    struct FMParameter *cur_instruction = &def_entry->params[state->next_instruction.index];

    if (cur_instruction->type == INT_PARAM ||
        cur_instruction->type == DOUBLE_PARAM) {            // If an int or double,
        fs_push(state, *cur_instruction);                   // just push param onto stack,
        state->next_instruction.index++;                    // and go to next instruction.
    }
    else if (cur_instruction->type == STRING_PARAM) {       // If a string,
        printf("TODO: Handle strings\n");                   // TODO: Make a copy and push that
        state->next_instruction.index++;                    // and go to next instruction.
    }
    else if (cur_instruction->type == ENTRY_PARAM) {        // If an entry,
        state->next_instruction.index++;                    // advance to next instruction,
        return cur_instruction->value.entry_param->
            code(state,
                 cur_instruction->value.entry_param);       // and then execute entry's code.
    }
    else {
        snprintf(M_err_message, ERR_MESSAGE_LEN,
                 "Unknown param type: %s",
                 cur_instruction->type);                    // Construct error message,
        fm_abort(state,
                 M_err_message, __FILE__, __LINE__);        // abort,
        return -1;                                          // and indicate abort
    }

    return 1;                                               // Everything is good.
}


//---------------------------------------------------------------------------
// Creates the builtins for a generic interpreter
//---------------------------------------------------------------------------
static
void add_builtin_words(struct FMState *state) {
    define_word(state, ":", 0, colon_code);
    define_word(state, ";", 0, exit_code);

    /*
    define_word(state, ".\"", 1, dot_quote_code);
    define_word(state, "DROP", 0, drop_code);
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
    if (state->next_instruction.entry) {
        return step_colon_def(state);
    }
    else {
        return interpret_next_word(state);
    }
}
