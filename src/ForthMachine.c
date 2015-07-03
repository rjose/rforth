#include "ForthMachine.h"

#include "defines.h"

#include <string.h>
#include <stdio.h>
#include <stdlib.h>

//=======================================================
// Internal functions
//=======================================================
#define M_is_dictionary_full(state)   ((state)->last_entry_index >= MAX_ENTRIES - 1)
#define M_cur_entry(state)   (&((state)->dictionary[(state)->last_entry_index]))

//---------------------------------------------------------------------------
// String constants
//---------------------------------------------------------------------------
static char *TYPE_GENERIC = "GENERIC";

static char *INT_TYPE = "int";
static char *DOUBLE_TYPE = "double";
static char *STRING_TYPE = "string";
static char *ENTRY_TYPE = "entry";

#define ERR_MESSAGE_LEN  256
static char M_err_message[ERR_MESSAGE_LEN];

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
    state->i_pointer = NULL;                           // No instruction to execute next
}


//---------------------------------------------------------------------------
// Prints message to STDOUT and resets forth machine state
//---------------------------------------------------------------------------
static
void fm_abort(struct FMState *state, const char *message, const char *file, int line) {
    printf("ABORT: %s (at %s:%d)\n", message, file, line);

    // Free all strings on stack
    for (int i=0; i <= state->stack_top; i++) {
        struct FMParameter *item = &state->stack[i];
        if (item->type == STRING_TYPE) {
            free(item->value.string_param);
            item->value.string_param = NULL;
        }
    }

    clear_state(state);
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
    while (cur_index >= 0) {                           // Start from last entry and go backwards
        if (strncmp(state->dictionary[cur_index].name,
                    name, NAME_LEN) == 0) {            // If names match...
            result = &(state->dictionary[cur_index]);  // result is address of matching entry...
            break;                                     // and we're done with this loop.
        }
        cur_index--;
    }
    return result;
}


//---------------------------------------------------------------------------
// Creates an FMParameter of "entry" type (pointer to a dictionary entry)
//---------------------------------------------------------------------------
struct FMParameter make_entry_param(struct FMEntry *entry) {
    struct FMParameter result;
    result.type = ENTRY_TYPE;
    result.value.entry_param = entry;
    return result;
}

//---------------------------------------------------------------------------
// Creates an FMParameter of "string" type
//---------------------------------------------------------------------------
struct FMParameter make_string_param(char *string) {
    struct FMParameter result;
    result.type = STRING_TYPE;
    result.value.string_param = string;
    return result;
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
    
    state->word_len = 0;                               // Reset word

    if (state->input_string == NULL) {                 // If no input string, no word
        return -1;
    }
    while (M_cur_char() != NUL &&                      // Skip whitespace
           is_whitespace(M_cur_char())) {
        state->input_index++;
    }
    if (M_cur_char() == NUL) {                         // If at end of string, no word
        return -1;
    }

    // Copy word into buffer
    while(state->word_len < MAX_WORD_LEN) {
        if (is_whitespace(M_cur_char())) {             // Stop when hit whitespace...
            state->input_index++;                      // ...but advance past whitespace char first
            break;
        }

        if (M_cur_char() == NUL) {                     // Stop when hit EOS
            break;
        }

        if (state->word_len == MAX_WORD_LEN) {         // If we'll exceed word_buffer...
            state->word_len = 0;                       // reset word and
            return -2;                                 // indicate error
        }

        state->word_buffer[state->word_len++] =        // Store next character
            M_cur_char();

        state->input_index++;                          // Go to next char in input
    }

    state->word_buffer[state->word_len] = NUL;         // NUL terminate word
    return 0;                                          // Everything is good
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
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int fs_drop(struct FMState *state) {
#define M_top(state)   &((state)->stack[(state)->stack_top])
    
    if (state->stack_top == -1) {                      // Abort if stack is empty
        fm_abort(state, "Stack underflow", __FILE__, __LINE__);
        return -1;
    }

    // If top of stack is a string, then free it
    struct FMParameter *top = M_top(state);
    if (top->type == STRING_TYPE) {
        free(top->value.string_param);                 // Free the string memory
        top->value.string_param = NULL;                // NULL out pointer
    }

    state->stack_top--;                                // Drop the item
    return 0;
}


//---------------------------------------------------------------------------
// Loads a param with an entry value
//---------------------------------------------------------------------------
static
void load_entry_param(struct FMEntry *entry_val, struct FMParameter *param) {
    param->type = ENTRY_TYPE;
    param->value.entry_param = entry_val;
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
            param->type = INT_TYPE;                    // store value as int
            param->value.int_param = int_val;
        }
        else {
            param->type = DOUBLE_TYPE;                 // Otherwise, store value as double
            param->value.double_param = double_val;
        }
        result = 0;
    }
    return result;
}


//---------------------------------------------------------------------------
// Interprets specified word
//
// Return value:
//   *  0: Success
//   * -1: ...
//---------------------------------------------------------------------------
static
int interpret_word(struct FMState *state, const char *word) {
    int result = 0;

    struct FMEntry *entry = find_entry(state, word);

    // Handle an entry
    if (entry != NULL) {                               // If entry in dictionary...
        (entry->code)(state, entry);                   // execute its code
        return 0;
    }

    // Handle a number
    struct FMParameter value;
    if (load_number_param(word, &value) == 0) {
        fs_push(state, value);                         // Push number onto stack
        result = 0;
    }
    else {
        // TODO: Finish this
        result = -1;                                   // Invalid
    }

    return result;
}


//---------------------------------------------------------------------------
// Reads next word and interprets it
//
// Return value:
//   *  0: Success
//   * -1: No more words
//---------------------------------------------------------------------------
static
int interpret_next_word(struct FMState *state) {
    if (read_word(state) < 0) {
        return -1;
    }

    return interpret_word(state, state->word_buffer);
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
// Create a string and put it on the stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int dot_quote_code(struct FMState *state, struct FMEntry *entry) {
    int start_index = state->input_index;              // Start of string
    int cur_index = start_index;                       // Index of char we're looking at
    char cur_char;                                     // Holds char we're looking at
    size_t string_len;                                 // Size of string to allocate
    char *new_string;                                  // Points to newly allocated string

    // Search for ending '"'
    while(1) {
        cur_char = state->input_string[cur_index];     // Look at current char
        if (cur_char == '"') {                         // If it's a '"',
            state->input_index = cur_index+1;          // go to next char,
            break;                                     // and break out of loop
        }
        if (cur_char == NUL) {                         // If reached end of string,
            fm_abort(state, "Couldn't find end '\"'",  // abort,
                     __FILE__, __LINE__);
            return -1;                                 // and indicate abort.
        }
        cur_index++;                                   // Go to next char
    }

    // Copy string and push onto stack
    string_len = cur_index - start_index;              // Figure out length of string,
    if ((new_string=malloc(string_len+1)) == NULL) {   // allocate some memory for it...
        fm_abort(state, "malloc failure",
                 __FILE__, __LINE__);                  // (on failure, abort
        return -1;                                     // and indicate it)
    }

    strncpy(new_string, state->input_string + start_index,
            string_len);                               // Copy string to new string,
    new_string[string_len] = NUL;                      // and NUL terminate

    
    return fs_push(state,
                   make_string_param(new_string));     // Put string in a param and push onto stack
}



//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int drop_code(struct FMState *state, struct FMEntry *entry) {
    return fs_drop(state);
}


//---------------------------------------------------------------------------
// Executes a colon definition
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int execute_definition_code(struct FMState *state, struct FMEntry *entry) {
    printf("TODO: Implement execute_colon_definition\n");
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
    // TODO: This should pop an address off the return stack
    printf("TODO: Implement exit code\n");
    return 0;
}


//---------------------------------------------------------------------------
// Frees all memory in param
//
// NOTE: Only strings are allocated
//---------------------------------------------------------------------------
static
void delete_param(struct FMParameter *param) {
    if (param->type == STRING_TYPE) {
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
    if (read_word(state) != 0) {                      // If no next word, return -1
        fm_abort(state, "Incomplete definition",
                 __FILE__, __LINE__);
        return -1;
    }

    struct FMParameter *param_p =
        entry->params + entry->num_params;            // Compiled word goes here

    struct FMEntry *word_entry =
        find_entry(state, state->word_buffer);        // Look up word entry

    int result = 0;

    if (word_entry && word_entry->immediate) {        // If an immediate word, execute it
        return word_entry->code(state, word_entry);
    }
    else if (word_entry) {                             // If it's just a word,
        load_entry_param(word_entry, param_p);         // store it in the next parameter,
        entry->num_params++;                           // increment the param count,
        result = 0;                                    // and indicate successful compile
        
        if (word_entry->code == exit_code) {           // If the entry is a "exit" (i.e., ";"),
            result = 1;                                // indicate definition is complete
        }
    }
    else {                                             // If not an entry,
        if (load_number_param(state->word_buffer, param_p) == 0) {
                                                       // try word as a number.
            entry->num_params++;                       // On success, increment param count
            result = 0;                                // and indicate that word was compiled.
        }
        else {                                         // Otherwise, abort compilation
            snprintf(M_err_message, ERR_MESSAGE_LEN,
                     "%s '%s'", "Unable to compile:",state->word_buffer);
            fm_abort(state, M_err_message, __FILE__, __LINE__);
            return -1;
        }
    }

    return result;
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
#define M_delete_entry()   delete_entry(cur_entry); \
                           state->last_entry_index--;

#define NUM_ALLOCATED_PARAMS   10
    
    if (FMCreateEntry(state) != 0) {
        fm_abort(state, "Unable to create entry for colon definition", __FILE__, __LINE__);
        return -1;
    }
    struct FMEntry *cur_entry = M_cur_entry(state);    // Get a pointer to newly created entry
    cur_entry->code = execute_definition_code;

    // Compile each word of the definition
    int params_left = 0;
    size_t param_size = sizeof(struct FMParameter);

    while(1) {
        if (params_left == 0) {                        // If no more space for parameters...
            cur_entry->params = realloc(cur_entry->params,
                                        param_size * (cur_entry->num_params + NUM_ALLOCATED_PARAMS));
                                                       // ...allocate space for more parameters

            if (cur_entry->params == NULL) {           // If something went wrong with alloc,
                fm_abort(state, "Unable to realloc",
                         __FILE__, __LINE__);          // abort,
                M_delete_entry();                      // delete the entry we're working on,
                return -1;                             // and indicate abort
            }
            params_left = NUM_ALLOCATED_PARAMS;
        }

        // Have space to add another parameter
        int status = compile_word(state, cur_entry);   // Compile next word into entry's params

        if (status == 1) {                             // If last compiled word was an exit, we're done.
            break;
        }
        if (status == -1) {                            // If something went wrong with compile,
            M_delete_entry();                          // delete the entry we're working on,
            return -1;                                 // and indicate an abort
        }

        params_left--;                                 // Otherwise, we've just used a parameter slot
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
// Defines a new word in the dictionary
//---------------------------------------------------------------------------
static
void define_word(struct FMState *state, const char* name, int immediate, code_p code) {
    if (M_is_dictionary_full(state)) {
        fm_abort(state, "Dictionary full", __FILE__, __LINE__);
        return;
    }
    state->last_entry_index++;                         // Claim next empty entry
    struct FMEntry *cur_entry = M_cur_entry(state);
    strncpy(cur_entry->name, name, NAME_LEN);
    cur_entry->immediate = immediate;
    cur_entry->code = code;
}


//---------------------------------------------------------------------------
// Creates the builtins for a generic interpreter
//---------------------------------------------------------------------------
static
void add_builtin_words(struct FMState *state) {
    define_word(state, ".\"", 1, dot_quote_code);
    define_word(state, "DROP", 0, drop_code);
    define_word(state, ":", 0, colon_code);
    define_word(state, ";", 0, exit_code);
}


//=======================================================
// Public functions
//=======================================================


//---------------------------------------------------------------------------
// Creates an empty FMState object
//
// Also initializes data structures where appropriate
//---------------------------------------------------------------------------
struct FMState FMCreateState() {
    struct FMState result;

    strncpy(result.type, TYPE_GENERIC, TYPE_LEN);      // GENERIC type
    result.last_entry_index = -1;                      // No entries
    clear_state(&result);

    // Add builtin words
    add_builtin_words(&result);

    return result;
}

//---------------------------------------------------------------------------
// Sets input string of an FMState
//---------------------------------------------------------------------------
void FMSetInput(struct FMState *state, const char *string) {
    state->input_string = string;                      // Set input string
    state->input_index = 0;                            // Start at beginning of input
}


//---------------------------------------------------------------------------
// Creates new entry using next word in input as a name
//
// Return value:
//   *  0: Success
//   * -1: No next word from input
//   * -2: Dictionary full
//---------------------------------------------------------------------------
int FMCreateEntry(struct FMState *state) {
    if (read_word(state) != 0) {                      // If no next word, return -1
        return -1;
    }

    if (M_is_dictionary_full(state)) {                // If dictonary full, return -2
        return -2;
    }

    state->last_entry_index++;                         // Go to next empty entry
    struct FMEntry *cur_entry = M_cur_entry(state);

    strncpy(cur_entry->name,
            state->word_buffer, state->word_len);      // Entry name is last word read
    cur_entry->immediate = 0;                          // Default to not "immediate"
    cur_entry->code = nop_code;                        // Default code to do nothing

    cur_entry->params = NULL;
    cur_entry->num_params = 0;                         // Start with no params

    return 0;
}


//---------------------------------------------------------------------------
// Gets next word, looks it up in the dictionary, and puts its address on the stack
//
// If can't find word, puts a 0 on the stack
//---------------------------------------------------------------------------
void FMTick(struct FMState *state) {
    if (read_word(state) != 0) {
        fm_abort(state, "read_word in FMTick failed", __FILE__, __LINE__);
        return;
    }

    struct FMEntry *entry = find_entry(state, state->word_buffer);
    struct FMParameter result = make_entry_param(entry);
    fs_push(state, result);
}


//---------------------------------------------------------------------------
// Interprets each word in a string
//---------------------------------------------------------------------------
void FMInterpretString(struct FMState *state, const char *string) {
    FMSetInput(state, string);
    while (interpret_next_word(state) == 0) {};
}
