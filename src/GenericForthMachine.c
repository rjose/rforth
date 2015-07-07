#include "GenericForthMachine.h"

#include "Drop.h"

extern void define_word(struct FMState *state, const char* name, int immediate, code_p code);

//---------------------------------------------------------------------------
// Creates a generic forth machine
//---------------------------------------------------------------------------
struct FMState CreateGenericFM() {
    struct FMState result = FM_CreateState();               // Create base state

    define_word(&result, "DROP", 0, Drop_code);             // Define generically useful words
    return result;
}
