#include "defines.h"
#include "FMCore.h"


typedef int (compare_fn)(struct FMParameter *l_value, struct FMParameter *r_value);


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
int Minus_code(struct FMState *state, struct FMEntry *entry) {
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


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if l_value <= r_value, 0 otherwise
//
// Stack args (l_value r_value -- int)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
static
int compare_entries(struct FMState *state, struct FMEntry *entry, compare_fn cmp_fn) {
    struct FMParameter *l_value;
    struct FMParameter *r_value;

    if (get_two_stack_args(state,
                           &l_value, &r_value) < 0) {       // Get top two args
        return -1;
    }

    struct FMParameter result;
    if (l_value->type == INT_PARAM ||
        l_value->type == DOUBLE_PARAM) {                    // If int or double
        result.type = INT_PARAM;
        result.value.int_param = cmp_fn(l_value, r_value);
    }
    else {                                                  // Otherwise, abort
        snprintf(FMC_err_message, ERR_MESSAGE_LEN,
                 "Unhandled type: %s", l_value->type);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return -1;
    }

    // Drop l_value and r_value..
    if (FMC_drop(state) < 0) {return -1;}
    if (FMC_drop(state) < 0) {return -1;}

    // ..and then push result onto stack
    if (FMC_push(state, result) < 0) {return -1;}

    return 0;
}


//---------------------------------------------------------------------------
// Returns l_entry > r_entry
//---------------------------------------------------------------------------
int compare_greater(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type == INT_PARAM) {
        result = l_value->value.int_param > r_value->value.int_param;
    }
    else if (l_value->type == DOUBLE_PARAM) {
        result = l_value->value.double_param > r_value->value.double_param;
    }
    else {
        return -1;
    }
    return result;
}


//---------------------------------------------------------------------------
// Returns l_entry >= r_entry
//---------------------------------------------------------------------------
int compare_greater_eq(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type == INT_PARAM) {
        result = l_value->value.int_param >= r_value->value.int_param;
    }
    else if (l_value->type == DOUBLE_PARAM) {
        result = l_value->value.double_param >= r_value->value.double_param;
    }
    else {
        return -1;
    }
    return result;
}


//---------------------------------------------------------------------------
// Returns l_entry < r_entry
//---------------------------------------------------------------------------
int compare_less(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type == INT_PARAM) {
        result = l_value->value.int_param < r_value->value.int_param;
    }
    else if (l_value->type == DOUBLE_PARAM) {
        result = l_value->value.double_param < r_value->value.double_param;
    }
    else {
        return -1;
    }
    return result;
}


//---------------------------------------------------------------------------
// Returns l_entry <= r_entry
//---------------------------------------------------------------------------
int compare_less_eq(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type == INT_PARAM) {
        result = l_value->value.int_param <= r_value->value.int_param;
    }
    else if (l_value->type == DOUBLE_PARAM) {
        result = l_value->value.double_param <= r_value->value.double_param;
    }
    else {
        return -1;
    }
    return result;
}


//---------------------------------------------------------------------------
// Returns l_entry AND r_entry
//---------------------------------------------------------------------------
int compare_AND(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type != INT_PARAM) {
        return -1;
    }
    result = l_value->value.int_param && r_value->value.int_param;
    return result;
}


//---------------------------------------------------------------------------
// Returns l_entry OR r_entry
//---------------------------------------------------------------------------
int compare_OR(struct FMParameter *l_value, struct FMParameter *r_value) {
    int result = 0;

    if (l_value->type != INT_PARAM) {
        return -1;
    }
    result = l_value->value.int_param || r_value->value.int_param;
    return result;
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if l_value > r_value, 0 otherwise
//
// Stack args (l_value r_value -- is_greater)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Greater_than_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_greater);
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if l_value >= r_value, 0 otherwise
//
// Stack args (l_value r_value -- is_greater_eq)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Greater_than_eq_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_greater_eq);
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if l_value < r_value, 0 otherwise
//
// Stack args (l_value r_value -- is_less)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Less_than_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_less);
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if l_value <= r_value, 0 otherwise
//
// Stack args (l_value r_value -- is_less_eq)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Less_than_eq_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_less_eq);
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns l_value AND r_value
//
// Stack args (l_value r_value -- res)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int AND_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_AND);
}

//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns l_value OR r_value
//
// Stack args (l_value r_value -- res)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int OR_code(struct FMState *state, struct FMEntry *entry) {
    return compare_entries(state, entry, compare_AND);
}


//---------------------------------------------------------------------------
// Compares top 2 stack elements and returns 1 if values are identical; 0 otherwise
//
// Stack args (l_value r_value -- is_identical)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int Identical_code(struct FMState *state, struct FMEntry *entry) {
    struct FMParameter *l_value;
    struct FMParameter *r_value;

    if (get_two_stack_args(state,
                           &l_value, &r_value) < 0) {       // Get top two args
        return -1;
    }

    struct FMParameter result;
    result.type = INT_PARAM;
    result.value.int_param =  (l_value->value.int_param == r_value->value.int_param);

    // Drop l_value and r_value..
    if (FMC_drop(state) < 0) {return -1;}
    if (FMC_drop(state) < 0) {return -1;}

    // ..and then push result onto stack
    if (FMC_push(state, result) < 0) {return -1;}

    return 0;
}
