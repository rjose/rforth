#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"


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


#========================================
# BSS section
#========================================
	.section .bss
	.comm G_dictionary, DICT_SIZE
	.comm G_param_stack, PARAM_STACK_SIZE

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

.loop:                                  # Continuously interpret words
	call Interpret
	jmp .loop

done:
	pushq 	$0                      # Normal exit code is 0
	call Exit
