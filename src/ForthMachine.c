#include "ForthMachine.h"

#include "defines.h"

#include <string.h>
#include <stdio.h>

//=======================================================
// Internal functions
//=======================================================

//---------------------------------------------------------------------------
// String constants
//---------------------------------------------------------------------------
static char *TYPE_GENERIC = "GENERIC";

static char *POINTER_TYPE = "pointer";
static char *INT_TYPE = "int";
static char *DOUBLE_TYPE = "double";


//---------------------------------------------------------------------------
// Returns 1 if c is whitespace; 0 otherwise
//---------------------------------------------------------------------------
static int is_whitespace(char c) {
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
static void clear_state(struct FMState *state) {
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
static void fm_abort(struct FMState *state, const char *message, const char *file, int line) {
    printf("ABORT: %s (at %s:%d)\n", message, file, line);
    clear_state(state);
}


//---------------------------------------------------------------------------
// Looks up name in dictionary
//
// Returns pointer to entry or NULL if not found.
//---------------------------------------------------------------------------
static struct FMEntry *find_entry(struct FMState *state, const char *name) {
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
// Creates an FMParameter of "pointer" type
//---------------------------------------------------------------------------
struct FMParameter make_pointer_param(void * pointer) {
    struct FMParameter result;
    result.type = POINTER_TYPE;
    result.value.pointer_param = pointer;
    return result;
}


//---------------------------------------------------------------------------
// Reads next word from input string
//
// Word is stored in state.word_buffer and its length in state.word_len
//
// Return value:
//   *  0: Success
//   * -1: No wordick
//   * -2: Word is longer than MAX_WORD_LEN
//---------------------------------------------------------------------------
#define M_cur_char(state)    ((state)->input_string[(state)->input_index])

static int read_word(struct FMState *state) {
    state->word_len = 0;                               // Reset word

    if (state->input_string == NULL) {                 // If no input string, no word
        return -1;
    }
    while (M_cur_char(state) != NUL &&                 // Skip whitespace
           is_whitespace(M_cur_char(state))) {
        state->input_index++;
    }
    if (M_cur_char(state) == NUL) {                    // If at end of string, no word
        return -1;
    }

    while(state->word_len < MAX_WORD_LEN) {            // Copy word into buffer
        if (is_whitespace(M_cur_char(state)) ||        // Stop when hit whitespace or EOS
            M_cur_char(state) == NUL) {
            state->word_buffer[state->word_len] = NUL; // Add NUL to end of word
            break;
        }

        if (state->word_len == MAX_WORD_LEN) {         // If we'll exceed word_buffer...
            state->word_len = 0;                       // reset word and
            return -2;                                 // indicate error
        }

        state->word_buffer[state->word_len++] =        // Store next character
            M_cur_char(state);
        state->input_index++;                          // Go to next char in input
    }

    return 0;                                          // Everything is good
}


//---------------------------------------------------------------------------
// Pushes value onto forth stack
//
// NOTE: If stack is full, this aborts
//---------------------------------------------------------------------------
void fs_push(struct FMState *state, struct FMParameter value) {
    if (state->stack_top == MAX_STACK - 1) {           // Abort if stack is full
        fm_abort(state, "Stack overflow", __FILE__, __LINE__);
        return;
    }

    state->stack[++state->stack_top] = value;
}


//---------------------------------------------------------------------------
// Interprets specified word
//
// Return value:
//   *  0: Success
//   * -1: ...
//---------------------------------------------------------------------------
int interpret_word(struct FMState *state, const char *word) {
    int result = 0;
    double double_val;
    int int_val;
    
    struct FMEntry *entry = find_entry(state, word);

    // Handle an entry
    if (entry != NULL) {                               // If entry in dictionary...
        (entry->code)(state, entry);                   // execute its code
        return 0;
    }

    // Handle a number
    struct FMParameter value;
    if (sscanf(word, "%lf", &double_val) == 1) {       // If was a number
        int_val = double_val;                          // Get int truncation
        if (double_val - (double) int_val == 0) {      // If num is int...
            value.type = INT_TYPE;                     // store value as int
            value.value.int_param = int_val;
        }
        else {
            value.type = DOUBLE_TYPE;                  // Otherwise, store value as double
            value.value.double_param = double_val;
        }
        fs_push(state, value);                         // Push number onto stack
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
int interpret_next_word(struct FMState *state) {
    if (read_word(state) < 0) {
        return -1;
    }

    return interpret_word(state, state->word_buffer);
}


//---------------------------------------------------------------------------
// Do nothing
//---------------------------------------------------------------------------
void nop(struct FMState *state, struct FMEntry *entry) {
    printf("NOP\n");
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

    if (state->last_entry_index == MAX_ENTRIES-1) {    // If dictonary full, return -2
        return -2;
    }

    state->last_entry_index++;                         // Go to next empty entry
    struct FMEntry *cur_entry =
        &(state->dictionary[state->last_entry_index]); // Get pointer to new entry

    strncpy(cur_entry->name,
            state->word_buffer, state->word_len);      // Entry name is last word read
    cur_entry->immediate = 0;                          // Default to not "immediate"
    cur_entry->code = nop;                             // Default code to do nothing

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
    struct FMParameter result = make_pointer_param((void *) entry);
    fs_push(state, result);
}


//---------------------------------------------------------------------------
// Interprets each word in a string
//---------------------------------------------------------------------------
void FMInterpretString(struct FMState *state, const char *string) {
    FMSetInput(state, string);
    while (interpret_next_word(state) == 0) {};
}
