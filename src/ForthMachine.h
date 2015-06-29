#ifndef FORTH_MACHINE_H
#define FORTH_MACHINE_H


//===============================================
// Forth Machine defines
//===============================================
#define TYPE_LEN              64                  // Max len of string describing type of forth machine
#define MAX_ENTRIES           4096                // Max dictionary size for a forth machine
#define MAX_STACK             128                 // Max forth stack depth
#define MAX_RETURN_STACK      128                 // Max return stack depth
#define MAX_WORD_LEN          128                 // Max forth word length
#define NAME_LEN              64                  // Max length of an entry name


//===============================================
// Forth Machine structs
//===============================================

//---------------------------------------------------------------------------
// A parameter in a dictionary entry
//---------------------------------------------------------------------------
struct FMParameter {
    char *type;                                   // "int", "double", "string", "pointer"
    union {                                       // Param value
        long int_param;
        double double_param;
        char *string_param;
        void *pointer_param;
    } value;
};

    
//---------------------------------------------------------------------------
// Dictionary entry
//---------------------------------------------------------------------------
struct FMState;                                   // Predeclare
struct FMEntry;                                   // Predeclare

typedef void (*code_p)(struct FMState *state,
                       struct FMEntry *entry);    // Function pointer for entry

struct FMEntry {
    char name[NAME_LEN];                          // Name of entry (like "SWAP")
    code_p code;                                  // Pointer to associated code to execute
    struct FMParameter *params;                   // Param array for entry
    int immediate;                                // non-zero if "immediate" word
};

//---------------------------------------------------------------------------
// FMState holds the state of a forth machine
//
// This is what lets forth machines run concurrently in one process
//---------------------------------------------------------------------------
typedef struct FMParameter *instruction_p;        // Instruction pointer points to FMParameters
typedef struct FMParameter stack_val;             // Stack values are the same as FMParameters

struct FMState {
    char type[TYPE_LEN];                          // Type of forth machine (i.e., vocabulary)

    struct FMEntry dictionary[MAX_ENTRIES];       // Forth dictionary
    int last_entry_index;                         // Index of most recently created entry

    stack_val stack[MAX_STACK];                   // Forth value stack
    int stack_top;                                // Index of top of value stack (-1 if empty)

    stack_val return_stack[MAX_RETURN_STACK];     // Forth return stack
    int return_stack_top;                         // Index of top of return stack (-1 if empty)

    char word_buffer[MAX_WORD_LEN+1];             // Buffer to hold word read from input
    int word_len;

    const char *input_string;                     // Current input string
    int input_index;                              // Cur position in input_string

    instruction_p i_pointer;                      // Address of next instruction to execute
};


//===============================================
// ForthMachine Functions
//===============================================

//---------------------------------------------------------------------------
// Creates an empty FMState object
//---------------------------------------------------------------------------
struct FMState FMCreateState();

//---------------------------------------------------------------------------
// Sets the current input string for a forth machine
//---------------------------------------------------------------------------
void FMSetInput(struct FMState *state, const char *string);


//---------------------------------------------------------------------------
// Creates new entry using next word in input as a name
//
// Return value:
//   *  0: Success
//   * -1: No next word from input
//   * -2: Dictionary full
//---------------------------------------------------------------------------
int FMCreateEntry(struct FMState *state);


//---------------------------------------------------------------------------
// Gets next word, looks it up in the dictionary, and puts its address on the stack
//
// If can't find word, puts a 0 on the stack
//---------------------------------------------------------------------------
void FMTick(struct FMState *state);


//---------------------------------------------------------------------------
// Interprets each word in a string
//---------------------------------------------------------------------------
void FMInterpretString(struct FMState *state, const char *string);


#endif
