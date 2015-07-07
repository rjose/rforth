#ifndef DROP_H
#define DROP_H

#include "ForthMachine.h"

//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Drop_code(struct FMState *state, struct FMEntry *entry);

#endif
