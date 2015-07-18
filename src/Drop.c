#include "FMCore.h"

//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int DROP_code(struct FMState *state, struct FMEntry *entry) {
    printf("DROP\n");
    return FMC_drop(state);
}
