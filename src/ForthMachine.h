#ifndef FORTH_MACHINE_H
#define FORTH_MACHINE_H

#include "FMCore.h"

//---------------------------------------------------------------------------
// Creates an empty forth machine
//---------------------------------------------------------------------------
struct FMState FM_CreateState();


//---------------------------------------------------------------------------
// Sets the current input string for a forth machine
//---------------------------------------------------------------------------
void FM_SetInput(struct FMState *state, const char *string);


//---------------------------------------------------------------------------
// Executes next word/instruction in forth machine
//
// Return value:
//   * 1: Executed word/instruction
//   * 0: Nothing more to execute
//---------------------------------------------------------------------------
int FM_Step(struct FMState *state);


//------------------------------------------------------------------------------
// Runs a string using forth machine
//------------------------------------------------------------------------------
void FM_run_string(struct FMState *machine, const char *input);


//------------------------------------------------------------------------------
// Loads a file and runs it
//------------------------------------------------------------------------------
void FM_run_file(struct FMState *machine, const char *filename);


#endif
