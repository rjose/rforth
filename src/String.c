#include <string.h>
#include <stdlib.h>

#include "defines.h"
#include "macros.h"
#include "FMCore.h"

//---------------------------------------------------------------------------
// Converts top of stack to a string
//
// Stack args:
//   * 0: value
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int TO_STR_code(struct FMState *state, struct FMEntry *entry) {
#define TO_STR_LEN 128
    char result_str[TO_STR_LEN];                            // Where dest string goes

    // Get value
    if (FMC_check_stack_args(state, 1) < 0) {               // Check that stack has at least 1 elem
        return -1;
    }
    struct FMParameter *value;
    M_get_stack_arg(value, 0);

    // Format value as string
    if (value->type == STRING_PARAM) {                       // If already a string, do nothing
        return 0;
    }
    else if (value->type == INT_PARAM) {                     // If an int, format as int
        if (snprintf(result_str, TO_STR_LEN, "%d", value->value.int_param) < 0) {
            FMC_abort(state, "snprintf failure", __FILE__, __LINE__);
            return -1;
        }
    }
    else if (value->type == DOUBLE_PARAM) {                 // If a double, format as double
        if (snprintf(result_str, TO_STR_LEN, "%f", value->value.double_param) < 0) {
            FMC_abort(state, "snprintf failure", __FILE__, __LINE__);
            return -1;
        }
    }
    else {                                                  // Otherwise, abort
        snprintf(FMC_err_message, ERR_MESSAGE_LEN, "Unhandled type: %s", value->type);
        FMC_abort(state, FMC_err_message, __FILE__, __LINE__);
        return -1;
    }

    // Push result onto stack
    if (FMC_drop(state) < 0) {return -1;}                   // Drop old value
    
    struct FMParameter result;
    struct FMParameter tmp =
        FMC_make_string_param(result_str);                  // Create tmp result using result_str (local var)
    if (-1 == FMC_copy_param(state, &tmp, &result)) {       // Copy tmp param so we get an allocated string
        return -1;
    }
    
    if (FMC_push(state, result) < 0) {                      // push it onto stack
        return -1;
    }
    return 0;
}


//---------------------------------------------------------------------------
// Concatenates top two strings and replaces with result
//
// Stack effect: (s1 s2 -- s1s2)
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int CONCAT_code(struct FMState *state, struct FMEntry *entry) {
    // Get values
    if (FMC_check_stack_args(state, 2) < 0) {               // Check that stack has at least 2 elems
        return -1;
    }
    struct FMParameter *s1;
    struct FMParameter *s2;
    M_get_stack_arg(s2, 0);                                 // s2 is at top of stack
    M_get_stack_arg(s1, 1);                                 // s1 is one below top

    // Check that both are strings
    if (s1->type != STRING_PARAM ||
        s2->type != STRING_PARAM) {
        FMC_abort(state, "s1 and s2 must be strings",
                  __FILE__, __LINE__);
        return -1;
    }

    // Size of result is len(s1) + len(s2) + 1
    size_t s1_len = strlen(s1->value.string_param);
    size_t s2_len = strlen(s2->value.string_param);
    size_t res_len = s1_len + s2_len + 1;

    // Allocate space for string
    char *res_string;
    if (NULL == (res_string = malloc(res_len))) {
        FMC_abort(state, "malloc failed", __FILE__, __LINE__);
        return -1;
    }

    // res_string = s1 + s2
    strcpy(res_string, s1->value.string_param);
    strcat(res_string, s2->value.string_param);

    struct FMParameter result;
    result.type = STRING_PARAM;
    result.value.string_param = res_string;

    // Push value onto stack
    if (FMC_drop(state) < 0) {return -1;}                   // Drop s2,
    if (FMC_drop(state) < 0) {return -1;}                   // Drop s1,
    if (FMC_push(state, result) < 0) {return -1;}           // and then push result onto stack

    return 0;
}
