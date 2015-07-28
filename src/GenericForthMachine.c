#include "GenericForthMachine.h"

#define M_define_word(name, immediate, code)  FMC_define_word(&result, name, immediate, code);
#define M_func(name)   extern int name(struct FMState *state, struct FMEntry *entry)

// Declare code for words
M_func(NOP_code);
M_func(DUP_code);
M_func(DROP_code);
M_func(dot_quote_code);
M_func(VARIABLE_code);
M_func(bang_code);
M_func(at_code);
M_func(CONSTANT_code);
M_func(IF_code);
M_func(THEN_code);
M_func(ELSE_code);
M_func(WHILE_code);
M_func(REPEAT_code);
M_func(Comment_code);
M_func(Minus_code);
M_func(Less_than_code);
M_func(Less_than_eq_code);
M_func(Greater_than_code);
M_func(Greater_than_eq_code);
M_func(AND_code);
M_func(OR_code);
M_func(Identical_code);
M_func(LOG_code);

//---------------------------------------------------------------------------
// Creates a generic forth machine
//---------------------------------------------------------------------------
struct FMState CreateGenericFM() {
    // Create base state
    struct FMState result = FM_CreateState();

    // Define generically useful words
    M_define_word(".\"", 1, dot_quote_code);
    M_define_word("NOP", 0, NOP_code);
    M_define_word("DUP", 0, DUP_code);
    M_define_word("DROP", 0, DROP_code);
    M_define_word("VARIABLE", 0, VARIABLE_code);
    M_define_word("!", 0, bang_code);
    M_define_word("@", 0, at_code);
    M_define_word("CONSTANT", 0, CONSTANT_code);
    M_define_word("IF", 1, IF_code);
    M_define_word("THEN", 1, THEN_code);
    M_define_word("ELSE", 1, ELSE_code);
    M_define_word("WHILE", 1, WHILE_code);
    M_define_word("REPEAT", 1, REPEAT_code);
    M_define_word("#", 1, Comment_code);
    M_define_word("-", 0, Minus_code);
    M_define_word("<", 0, Less_than_code);
    M_define_word(">", 0, Greater_than_code);
    M_define_word("===", 0, Identical_code);
    M_define_word("<=", 0, Less_than_eq_code);
    M_define_word(">=", 0, Greater_than_eq_code);
    M_define_word("AND", 0, AND_code);
    M_define_word("OR", 0, OR_code);
    M_define_word("LOG", 0, LOG_code);

    return result;
}
