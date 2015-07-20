#ifndef FORTH_SERVER_H
#define FORTH_SERVER_H

#include "GenericForthMachine.h"

//---------------------------------------------------------------------------
// Creates an http socket leaving its file descriptor on the stack
//
// Stack args (http_port -- http_fd)
//   * top: http_port
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
//---------------------------------------------------------------------------
struct FMState CreateForthServer();

#endif
