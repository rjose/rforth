#include <stdio.h>
#include <stdlib.h>

#include "defines.h"
#include "FMCore.h"

//---------------------------------------------------------------------------
// Executes "#" word
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// This skips all chars until the next newline. The behavior is the same
// in compile mode or in normal mode.
//---------------------------------------------------------------------------
int Comment_code(struct FMState *state, struct FMEntry *entry) {
    char cur_char;
    while(NUL !=(cur_char =state->input_string[state->input_index])) {
                                                            // While cur_char isn't NUL,
        state->input_index++;                               // move index to next char,
        if (cur_char == '\n') {                             // and if cur char is a \n
            return 0;                                       // return.
        }
    }
    state->input_index--;                                   // Back the input_index up to sit at EOS
    return 0;
}
