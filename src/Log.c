#include "defines.h"
#include "FMCore.h"

//---------------------------------------------------------------------------
// Logs top of stack
//
// Stack args (message -- )
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int LOG_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter *message;
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }

    if (NULL == (message = FMC_stack_arg(state, 0))) {     // message is on top
        return -1;
    }

    if (message->type != STRING_PARAM) {                   // Ensure message is a string
        FMC_abort(state, "LOG requires a string",
                  __FILE__, __LINE__);
        return -1;
    }

    // TODO: Do something more interesting than just printing
    printf("LOG: %s\n", message->value.string_param);

    // Drop message
    if (FMC_drop(state) < 0) {return -1;}

    return 0;
}
