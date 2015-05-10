#===============================================================================
# NOTE: Include in .data section
#===============================================================================

	#-----------------------------------------------------------------------
	# Global constants
	#-----------------------------------------------------------------------
	# Assuming 200 words with an avg of 10 params each
	.equ	DICT_SIZE, 24576

	# Parameter stack size (256 8-byte words)
	.equ	PARAM_STACK_SIZE, 2048

	.equ    WORD_SIZE, 8

	#-----------------------------------------------------------------------
	# Stack Args
	#
	# These are offsets from %rsp for arguments passed on the stack
	#-----------------------------------------------------------------------
	.equ	STACK_ARG_1, 8
	.equ	STACK_ARG_2, 16
	.equ	STACK_ARG_3, 24
	.equ	STACK_ARG_4, 32
	.equ	STACK_ARG_5, 40

	#-----------------------------------------------------------------------
	# Dictionary entry defines
	#-----------------------------------------------------------------------
	.equ	 ENTRY_COUNT_OFFSET, 0
	.equ	 ENTRY_NAME_OFFSET, 4
	.equ	 ENTRY_LINK_OFFSET, 8
	.equ	 ENTRY_CODE_OFFSET, 16
	.equ	 ENTRY_PFA_OFFSET, 24

	#-----------------------------------------------------------------------
	# ASCII codes
	#-----------------------------------------------------------------------
	.equ     ASCII_NEWLINE, 10
	.equ	 ASCII_EOF, 0
	.equ     ASCII_SPACE, 32
	.equ	 ASCII_MINUS, 45
	.equ     ASCII_DOT, 46
	.equ	 ASCII_0, 48
	.equ	 ASCII_9, 57

	#-----------------------------------------------------------------------
	# System calls
	#-----------------------------------------------------------------------
	.equ	SYSCALL_READ, 0
	.equ	SYSCALL_EXIT, 60
