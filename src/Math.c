#include "defines.h"
#include "FMCore.h"


//---------------------------------------------------------------------------
// Stores top two value of stack (l_value r_value)
//---------------------------------------------------------------------------
static
int get_two_stack_args(struct FMState *state,
                 struct FMParameter **l_value, struct FMParameter **r_value) {
    if (FMC_check_stack_args(state, 2) < 0) {               // Check that stack has at least 2 elems
        return -1;
    }

    if (NULL == (*r_value = FMC_stack_arg(state, 0))) {     // r_value is on top
        return -1;
    }
    if (NULL == (*l_value = FMC_stack_arg(state, 1))) {     // l_value is one below top
        return -1;
    }

    if ((*r_value)->type != (*l_value)->type) {                  // Ensure types match
        FMC_abort(state, "l_value and r_value must be of same type",
                  __FILE__, __LINE__);
        return -1;
    }
    return 0;
}


//---------------------------------------------------------------------------
// Subtracts top two stack args and puts difference onto stack
//
// Stack args (l_value r_value -- diff_value)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int minus_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter *l_value;
    struct FMParameter *r_value;

    if (get_two_stack_args(state,
                           &l_value, &r_value) < 0) {       // Get top two args
        return -1;
    }


    struct FMParameter result;
    if (l_value->type == INT_PARAM) {                       // If INT_PARAM..
        result.type = INT_PARAM;
        result.value.int_param =
            l_value->value.int_param -
            r_value->value.int_param;                       // ..compute int difference
    }
    else if (l_value->type == DOUBLE_PARAM) {               // If DOUBLE_PARAM..
        result.type = DOUBLE_PARAM;
        result.value.double_param =
            l_value->value.double_param -
            r_value->value.double_param;                    // Compute double difference
    }
    else {                                                  // Otherwise, abort
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Unhandled type for minus_code: %s",
                 l_value->type);
        FMC_abort(state, FMC_err_message,
                  __FILE__, __LINE__);
        return -1;
    }

    // Drop l_value and r_value..
    if (FMC_drop(state) < 0) {return -1;}
    if (FMC_drop(state) < 0) {return -1;}

    // ..and then push result onto stack
    if (FMC_push(state, result) < 0) {return -1;}

    return 0;
}
