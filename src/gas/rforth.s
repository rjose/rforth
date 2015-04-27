#===============================================================================
# DATA section
#===============================================================================
	.section .data

	# Assuming 200 words with an avg of 10 params each
	.equ DICT_SIZE, 24000

#-------------------------------------------------------------------------------
# Dictionary pointer
#
# These are initialized to point to the first dictionary entry.
#-------------------------------------------------------------------------------
dp:	# Pointer to last dictionary entry
	.quad 0

pfa:	# "Parameter field address", also the next available dictionary cell
	.quad dictionary


#===============================================================================
# BSS section
#===============================================================================
	.section .bss
	.comm dictionary, DICT_SIZE

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
	call read_word
	call read_word

0:	# Exit
	pushq 	$0		# Exit code
	call exit
	addq $8*1, %rsp		# Don't need to remove stack arg, but still :-)
