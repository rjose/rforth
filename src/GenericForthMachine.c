#include "GenericForthMachine.h"

// Declare code for words
extern int DROP_code(struct FMState *state, struct FMEntry *entry);
extern int VARIABLE_code(struct FMState *state, struct FMEntry *entry);
extern int dot_quote_code(struct FMState *state, struct FMEntry *entry);
extern int bang_code(struct FMState *state, struct FMEntry *entry);
extern int at_code(struct FMState *state, struct FMEntry *entry);

//---------------------------------------------------------------------------
// Creates a generic forth machine
//---------------------------------------------------------------------------
struct FMState CreateGenericFM() {
    // Create base state
    struct FMState result = FM_CreateState();

    // Define generically useful words
    FMC_define_word(&result, ".\"", 1, dot_quote_code);
    FMC_define_word(&result, "DROP", 0, DROP_code);
    FMC_define_word(&result, "VARIABLE", 0, VARIABLE_code);
    FMC_define_word(&result, "!", 0, bang_code);
    FMC_define_word(&result, "@", 0, at_code);

    return result;
}
