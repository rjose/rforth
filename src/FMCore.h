#ifndef FM_CORE_H
#define FM_CORE_H

#include <stdio.h>

//=================================================
// Defines and Declarations
//=================================================
#define TYPE_LEN              64                            // Max len of forth machine type
#define MAX_ENTRIES           4096                          // Max dictionary size
#define MAX_STACK             128                           // Max stack depth
#define MAX_RETURN_STACK      128                           // Max stack depth
#define MAX_WORD_LEN          128                           // Max word length
#define NAME_LEN              64                            // Max entry name length
#define ERR_MESSAGE_LEN       256                           // Error message length

extern char FMC_err_message[ERR_MESSAGE_LEN];               // Buffer of length ERR_MESSAGE_LEN

// FMParameter types
extern char *INT_PARAM;
extern char *DOUBLE_PARAM;
extern char *STRING_PARAM;
extern char *ENTRY_PARAM;
extern char *PSEUDO_ENTRY_PARAM;

struct FMState;
struct FMEntry;

typedef int (*code_p)(struct FMState *state,
                      struct FMEntry *entry);               // Function pointer for dict entry

//---------------------------------------------------------------------------
// A parameter in a dictionary entry
//---------------------------------------------------------------------------
struct FMParameter {
    char *type;                                             // "int", "double", "string", "entry"
    union {
        long int_param;
        double double_param;
        char *string_param;
        struct FMEntry *entry_param;
    } value;                                                // Param value
};


//---------------------------------------------------------------------------
// Dictionary entry
//---------------------------------------------------------------------------
struct FMEntry {
    char name[NAME_LEN];                                    // Name of entry (like "SWAP")
    code_p code;                                            // Pointer to associated code to execute
    struct FMParameter *params;                             // Param array for entry
    int num_params;                                         // Number of parameters in params
    int immediate;                                          // non-zero if "immediate" word
    int pseudo_entry;                                       // non-zero if a pseudo_entry
};


//---------------------------------------------------------------------------
// Instruction context
//
// The next instruction is entry->params[index]
//---------------------------------------------------------------------------
struct FMInstruction {
    struct FMEntry *entry;                                  // Entry that owns instruction
    int index;                                              // Index of instruction
};

//---------------------------------------------------------------------------
// FMState holds the state of a forth machine
//---------------------------------------------------------------------------
struct FMState {
    char type[TYPE_LEN];                                    // Type of forth machine (i.e., vocabulary)

    int compile;                                            // 1 if compiling a definition

    const char *input_string;                               // Current input string
    int input_index;                                        // Cur position in input_string

    char word_buffer[MAX_WORD_LEN+1];                       // Buffer to hold word read from input
    int word_len;                                           // Length of last word read

    struct FMEntry dictionary[MAX_ENTRIES];                 // Forth dictionary
    int last_entry_index;                                   // Index of most recently created entry

    struct FMParameter stack[MAX_STACK];                    // Forth value stack
    int stack_top;                                          // Index of top of value stack (-1 if empty)

    struct FMInstruction rstack[MAX_RETURN_STACK];          // Forth return stack
    int rstack_top;                                         // Index of top of return stack (-1 if empty)
    struct FMInstruction next_instruction;                  // Address of next instruction to execute
};


//================================================
// Public Functions
//================================================

//---------------------------------------------------------------------------
// Prints message to STDERR and resets forth machine state
//---------------------------------------------------------------------------
void FMC_abort(struct FMState *state, const char *message, const char *file, int line);


//---------------------------------------------------------------------------
// Reads next word from input string
//
// Word is stored in state.word_buffer and its length in state.word_len
//
// Return value:
//   *  0: Success
//   * -1: No word
//   * -2: Word is longer than MAX_WORD_LEN
//---------------------------------------------------------------------------
int FMC_read_word(struct FMState *state);


//---------------------------------------------------------------------------
// Looks up name in dictionary
//
// Returns pointer to entry or NULL if not found.
//---------------------------------------------------------------------------
struct FMEntry *FMC_find_entry(struct FMState *state, const char *name);


//---------------------------------------------------------------------------
// Pushes value onto forth stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: If stack is full, this aborts
//---------------------------------------------------------------------------
int FMC_push(struct FMState *state, struct FMParameter value);


//---------------------------------------------------------------------------
// Drops top of stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: Other forth machines use this
//---------------------------------------------------------------------------
int FMC_drop(struct FMState *state);


//---------------------------------------------------------------------------
// Pushes value onto forth return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: If return stack is full, this aborts
//---------------------------------------------------------------------------
int FMC_rpush(struct FMState *state, struct FMInstruction value);


//---------------------------------------------------------------------------
// Pops value from return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// The previous top of stack is returned via |res|.
//---------------------------------------------------------------------------
int FMC_rpop(struct FMState *state, struct FMInstruction *res);


//---------------------------------------------------------------------------
// Drops top of return stack
//
// Return value:
//   *  0: Success
//   * -1: Abort
//
// NOTE: Whatever's on the return stack is owned by someone, so no memory
//       should be freed here.
//---------------------------------------------------------------------------
int FMC_rdrop(struct FMState *state);


//---------------------------------------------------------------------------
// Creates new entry
//
// Return value:
//   *  0: Success
//   * -2: Dictionary full
//---------------------------------------------------------------------------
int FMC_create_entry(struct FMState *state, const char *name);


//---------------------------------------------------------------------------
// Frees all memory in param
//
// NOTE: Only strings are allocated
//---------------------------------------------------------------------------
void FMC_delete_param(struct FMParameter *param);

//---------------------------------------------------------------------------
// Sets value to NULL if memory for it was allocated
//---------------------------------------------------------------------------
void FMC_null_param(struct FMParameter *param);

//---------------------------------------------------------------------------
// Creates a copy of a parameter, allocating memory if needed
//
// Return value:
//   *  0: Success
//   * -1: Abort
//---------------------------------------------------------------------------
int FMC_copy_param(struct FMState *state, struct FMParameter *param, struct FMParameter *dest);


//---------------------------------------------------------------------------
// Frees all memory in entry
//---------------------------------------------------------------------------
void FMC_delete_entry(struct FMEntry *entry);


//---------------------------------------------------------------------------
// Creates an FMParameter of "string" type
//---------------------------------------------------------------------------
struct FMParameter FMC_make_string_param(char *string);


//---------------------------------------------------------------------------
// Clears stack states, word state, and instruction pointer
//
// NOTE: This does *not* clear the dictionary
//---------------------------------------------------------------------------
void FMC_clear_state(struct FMState *state);


//---------------------------------------------------------------------------
// Defines a new word in the dictionary
//
// NOTE: Other forth machines use this function, too.
//---------------------------------------------------------------------------
void FMC_define_word(struct FMState *state, const char* name, int immediate, code_p code);



//================================================
// Macros
//================================================

#define M_is_dictionary_full(state)   ((state)->last_entry_index >= MAX_ENTRIES - 1)
#define M_last_entry(state)   (&((state)->dictionary[(state)->last_entry_index]))



#endif
