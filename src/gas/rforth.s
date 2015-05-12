#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"


#-------------------------------------------------------------------------------
# Dictionary pointers
#-------------------------------------------------------------------------------
	.globl G_dp, G_pfa

# Pointer to last dictionary entry
G_dp:
	.quad 0

# "Parameter field address". Also the next available cell in the Dictionary
G_pfa:
	.quad G_dictionary


#-------------------------------------------------------------------------------
# Parameter Stack Pointers
#-------------------------------------------------------------------------------
	.globl G_psp

# Parameter stack pointer (points to next available stack element)
G_psp:
	.quad G_param_stack


#===============================================================================
# BSS section
#===============================================================================
	.section .bss
	.comm G_dictionary, DICT_SIZE
	.comm G_param_stack, PARAM_STACK_SIZE

#===============================================================================
# TEXT section
#===============================================================================
	.section .text
	.globl main

#-------------------------------------------------------------------------------
# main
#-------------------------------------------------------------------------------
main:
	nop

	# Try WriteNumber
	movq $1234, %rax
	call WriteNumber

	# Define builtins
	call DefineBuiltinWords

	call Interpret
	call Interpret
	call Interpret
	call Interpret

0:	# Exit
	pushq 	$0		# Exit code
	call Exit
	MClearStackArgs 1
