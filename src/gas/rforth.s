#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#-------------------------------------------------------------------------------
# I/O
#-------------------------------------------------------------------------------
	.globl G_input_fd

G_input_fd:                             # Current input file descriptor
	.int STDIN                      # Default to STDIN

#-------------------------------------------------------------------------------
# Dictionary pointers
#-------------------------------------------------------------------------------
	.globl G_dp, G_pfa, G_param_index


G_dp:                                   # Pointer to most recently created
	.quad 0                         # dictionary entry


G_pfa:                                  # "Parameter field address". Also the next
	.quad G_dictionary              # available cell in the Dictionary


G_param_index:                          # Index into the current parameter for a
	.quad 0                         # dictionary entry. This is reset to 0
	                                # when a new entry is Create'd and
					# incremented by MAddParameter.

#-------------------------------------------------------------------------------
# Parameter Stack Pointers
#-------------------------------------------------------------------------------
	.globl G_psp

G_psp:                                  # "Parameter stack pointer" (points to
	.quad G_param_stack             # next available stack element)



#-------------------------------------------------------------------------------
# Misc
#-------------------------------------------------------------------------------
	.globl G_abort, G_err_dictionary_exceeded

G_abort:                                # 0 if OK; not 0 if cur colon def should stop
	.int 0

G_err_dictionary_exceeded:              # Out of space error used in a macro
	.asciz "ERROR: Dictionary out of space"

.main_fth:                              # Filename to LOAD when we start
	.asciz "main.fth"


.run_word:                              # Address of word to run (will be last entry in main.fth)
	.quad 0

#========================================
# BSS section
#========================================
	.section .bss
	.comm G_dictionary, DICT_SIZE   # Holds all words the rforth interpreter knows about
	.comm G_param_stack, PARAM_STACK_SIZE
	                                # Interpreter value stack
	.comm G_short_strings, SHORT_STR_LEN*MAX_SHORT_STRINGS
	                                # Memory location of short strings


#========================================
# TEXT section
#========================================
	.section .text
	.globl main

#-------------------------------------------------------------------------------
# main
#-------------------------------------------------------------------------------
main:
	call DefineBuiltinWords         # Define builtin rforth words

	MPush $.main_fth                # ." main.fth" LOAD
	call WLoad

	movq G_dp, %rbx                 # Store last entry of main.fth as our run word
	movq %rbx, .run_word            # . 

	#----------------------------------------------------------------------
	# The run word in main.fth should be a loop that runs whatever the
	# rforth application is. We have a containing loop here that resets
	# the forth interpreter and re-executes the run loop in case one of
	# the instructions ran into an abort.
	#----------------------------------------------------------------------
.loop:
	call Reset                      # Reset the forth interpreter state
	pushq .run_word                 # Execute run word
	call ExecuteColonDefinition     # .
	MClearStackArgs 1               # .
	jmp .loop                       # Repeat

done:
	pushq 	$0                      # Normal exit code is 0
	call Exit
