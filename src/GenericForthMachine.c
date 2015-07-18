#include "GenericForthMachine.h"

// Declare code for words
extern int DROP_code(struct FMState *state, struct FMEntry *entry);
extern int VARIABLE_code(struct FMState *state, struct FMEntry *entry);
extern int dot_quote_code(struct FMState *state, struct FMEntry *entry);
extern int bang_code(struct FMState *state, struct FMEntry *entry);
extern int at_code(struct FMState *state, struct FMEntry *entry);
extern int CONSTANT_code(struct FMState *state, struct FMEntry *entry);
extern int IF_code(struct FMState *state, struct FMEntry *entry);
extern int THEN_code(struct FMState *state, struct FMEntry *entry);
extern int ELSE_code(struct FMState *state, struct FMEntry *entry);

#define M_define_word(name, immediate, code)  FMC_define_word(&result, name, immediate, code);

//---------------------------------------------------------------------------
// Creates a generic forth machine
//---------------------------------------------------------------------------
struct FMState CreateGenericFM() {
    // Create base state
    struct FMState result = FM_CreateState();

    // Define generically useful words
    M_define_word(".\"", 1, dot_quote_code);
    M_define_word("DROP", 0, DROP_code);
    M_define_word("VARIABLE", 0, VARIABLE_code);
    M_define_word("!", 0, bang_code);
    M_define_word("@", 0, at_code);
    M_define_word("CONSTANT", 0, CONSTANT_code);
    M_define_word("IF", 1, IF_code);
    M_define_word("THEN", 1, THEN_code);
    M_define_word("ELSE", 1, ELSE_code);

    return result;
}
