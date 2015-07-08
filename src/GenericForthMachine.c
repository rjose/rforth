#include "GenericForthMachine.h"

#include "Drop.h"
#include "Variable.h"

extern void define_word(struct FMState *state, const char* name, int immediate, code_p code);

//---------------------------------------------------------------------------
// Creates a generic forth machine
//---------------------------------------------------------------------------
struct FMState CreateGenericFM() {
    // Create base state
    struct FMState result = FM_CreateState();

    // Define generically useful words
    define_word(&result, "DROP", 0, Drop_code);
    define_word(&result, "VARIABLE", 0, Variable_code);

    return result;
}
