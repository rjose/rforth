#include "Drop.h"

extern int fs_drop(struct FMState *state);

//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Drop_code(struct FMState *state, struct FMEntry *entry) {
    return fs_drop(state);
}
