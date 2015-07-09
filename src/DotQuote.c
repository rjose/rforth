#include "FMCore.h"
#include "defines.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

//---------------------------------------------------------------------------
// Create a string and put it on the stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int dot_quote_code(struct FMState *state, struct FMEntry *entry) {
    int start_index = state->input_index;                   // Start of string
    int cur_index = start_index;                            // Index of char we're looking at
    char cur_char;                                          // Holds char we're looking at
    size_t string_len;                                      // Size of string to allocate
    char *new_string;                                       // Points to newly allocated string

    // Search for ending '"'
    while(1) {
        cur_char = state->input_string[cur_index];          // Look at current char
        if (cur_char == '"') {                              // If it's a '"',
            state->input_index = cur_index+1;               // advance input_index past it
            break;                                          // and break out of loop
        }
        if (cur_char == NUL) {                              // If reached end of string,
            FMC_abort(state, "Couldn't find end '\"'",       // abort,
                     __FILE__, __LINE__);
            return -1;                                      // and indicate abort.
        }
        cur_index++;                                        // Otherwise, go to next char
    }

    // Copy string to a freshly allocated string
    string_len = cur_index - start_index;                   // Figure out length of string,
    if ((new_string = malloc(string_len+1)) == NULL) {      // allocate some memory for it...
        FMC_abort(state, "malloc failure",
                 __FILE__, __LINE__);                       // (on failure, abort
        return -1;                                          // and indicate it)
    }
    strncpy(new_string, state->input_string + start_index,
            string_len);                                    // Copy string to new string,
    new_string[string_len] = NUL;                           // and NUL terminate

    struct FMParameter string_param =
        FMC_make_string_param(new_string);                      // Package string into a param

    int result = 0;
    if (state->compile == 1) {                              // If in compile mode,
        entry->params[entry->num_params] = string_param;    // copy string param to entry
        entry->num_params++;                                // and advance param count
        result = 0;
    }
    else {
        result = FMC_push(state,
                         FMC_make_string_param(new_string));    // Otherwise, push param onto stack
    }
    return result;
}
