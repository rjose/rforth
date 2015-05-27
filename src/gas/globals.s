#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"

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

G_err_dictionary_exceeded:
	.asciz "ERROR: Dictionary out of space"

#========================================
# BSS section
#========================================
	.section .bss

	.comm G_dictionary, DICT_SIZE   # Holds all words the rforth interpreter knows about
	.comm G_param_stack, PARAM_STACK_SIZE
	                                # Interpreter value stack
	.comm G_short_strings, SHORT_STR_LEN*MAX_SHORT_STRINGS
	                                # Memory location of short strings
