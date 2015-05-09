#===============================================================================
# NOTE: Include in .data section
#===============================================================================

	#--------------------------------------------------
	# Global constants
	#--------------------------------------------------
	# Assuming 200 words with an avg of 10 params each
	.equ DICT_SIZE, 24576

	# Parameter stack size (256 8-byte words)
	.equ PARAM_STACK_SIZE, 2048

	#--------------------------------------------------
	# Dictionary entry defines
	#--------------------------------------------------
	.EQU	 ENTRY_COUNT_OFFSET, 0
	.EQU	 ENTRY_NAME_OFFSET, 4
	.EQU	 ENTRY_LINK_OFFSET, 8
	.EQU	 ENTRY_CODE_OFFSET, 16
	.EQU	 ENTRY_PFA_OFFSET, 24

	#--------------------------------------------------
	# ASCII codes
	#--------------------------------------------------
	.equ     NEWLINE, 10
	.equ	 EOF, 0
	.equ     SPACE, 32
	.equ	 ASCII_MINUS, 45
	.equ     ASCII_DOT, 46
	.equ	 ASCII_0, 48
	.equ	 ASCII_9, 57
