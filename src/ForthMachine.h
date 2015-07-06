#ifndef FORTH_MACHINE_H
#define FORTH_MACHINE_H

//=================================================
// Defines and Declarations
//=================================================
#define TYPE_LEN              64                            // Max len of forth machine type
#define MAX_ENTRIES           4096                          // Max dictionary size
#define MAX_STACK             128                           // Max stack depth
#define MAX_RETURN_STACK      128                           // Max stack depth
#define MAX_WORD_LEN          128                           // Max word length
#define NAME_LEN              64                            // Max entry name length

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

    struct FMInstruction return_stack[MAX_RETURN_STACK];    // Forth return stack
    int return_stack_top;                                   // Index of top of return stack (-1 if empty)
    struct FMInstruction next_instruction;                  // Address of next instruction to execute
};



//=================================================
// Functions
//=================================================

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

#endif
