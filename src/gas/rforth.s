#===============================================================================
# DATA section
#===============================================================================
	.section .data

	# Assuming 200 words with an avg of 10 params each
	.equ DICT_SIZE, 24576

	# Parameter stack size (256 8-byte words)
	.equ PARAM_STACK_SIZE, 2048


#-------------------------------------------------------------------------------
# Dictionary pointers
#
# These are initialized to point to the first dictionary entry.
#-------------------------------------------------------------------------------
	.globl dp, pfa, dict_size

dp:	# Pointer to last dictionary entry
	.quad 0

pfa:	# "Parameter field address". Also the next available dictionary cell.
	.quad dictionary

dict_size:
	.int DICT_SIZE

#-------------------------------------------------------------------------------
# Parameter Stack Pointers
#-------------------------------------------------------------------------------
	.globl psp, ps_size

psp:	# Parameter stack pointer (points to next available stack element)
	.quad param_stack

ps_size:      # Max size of parameter stack
	.int PARAM_STACK_SIZE



#===============================================================================
# BSS section
#===============================================================================
	.section .bss
	.comm dictionary, DICT_SIZE
	.comm param_stack, PARAM_STACK_SIZE

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

	# Create a new constant entry
	call Interpret

0:	# Exit
	pushq 	$0		# Exit code
	call Exit
	addq $8*1, %rsp		# Don't need to remove stack arg, but still :-)
