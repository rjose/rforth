#include "ForthMachine.h"

#include "defines.h"

#include <string.h>

static char *TYPE_GENERIC = "GENERIC";

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
// Do nothing
//---------------------------------------------------------------------------
void nop() {
}


//---------------------------------------------------------------------------
// Creates an empty FMState object
//
// Also initializes data structures where appropriate
//---------------------------------------------------------------------------
struct FMState FMCreateState() {
    struct FMState result;

    strncpy(result.type, TYPE_GENERIC, TYPE_LEN);      // GENERIC type
    result.last_entry_index = -1;                      // No entries
    result.stack_top = -1;                             // Nothing in stack
    result.return_stack_top = -1;                      // Nothing in return stack
    result.word_len = 0;                               // No word has been read
    result.input_string = NULL;                        // No input has been set
    result.input_index = 0;                            // Input index is at the beginning
    result.i_pointer = NULL;                           // No instruction to execute next
    
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
// Reads next word from input string
//
// Word is stored in state.word_buffer and its length in state.word_len
//
// Return value:
//   *  0: Success
//   * -1: No word
//   * -2: Word is longer than MAX_WORD_LEN
//---------------------------------------------------------------------------
#define M_cur_char(state)    ((state)->input_string[(state)->input_index])

int FMReadWord(struct FMState *state) {
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
// Creates new entry using next word in input as a name
//
// Return value:
//   *  0: Success
//   * -1: No next word from input
//   * -2: Dictionary full
//---------------------------------------------------------------------------
int FMCreateEntry(struct FMState *state) {
    if (FMReadWord(state) != 0) {                      // If no next word, return -1
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