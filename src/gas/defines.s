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
	# Fixed point constants
	#-----------------------------------------------------------------------
	# The total num digits is 19 (this is the number of decimal digits
	# in the largest signed 64 bit number).
	#
	# We're using fixed point representation for our numbers with
	# NUM_FRAC_DIGITS to the right of the decimal point.
	.equ	 NUM_FRAC_DIGITS, 3
	.equ     NUM_DIGITS, 16
	.equ	 BASE, 10
	.equ	 FIXED_POINT_UNITS, 1000	# BASE^NUM_FRAC_DIGITS


	#-----------------------------------------------------------------------
	# Stack Args
	#
	# These are offsets from %rbp for arguments passed on the stack. This
	# assumes that we've pushed the old value of %rbp and then stored
	# %rsp in %rbp.
	#
	# The stack looks like: Old EBP, Return Address, Arg1, Arg2, ...
	#                       0      , +8            , +16 , +24 , ...
	#-----------------------------------------------------------------------
	.equ	STACK_ARG_1, 16
	.equ	STACK_ARG_2, 24
	.equ	STACK_ARG_3, 32
	.equ	STACK_ARG_4, 40
	.equ	STACK_ARG_5, 48

	#-----------------------------------------------------------------------
	# Dictionary entry defines
	#-----------------------------------------------------------------------
	.equ	 ENTRY_COUNT, 0
	.equ	 ENTRY_IMMEDIATE, 1
	.equ	 ENTRY_NAME, 4
	.equ	 ENTRY_LINK, 8
	.equ	 ENTRY_CODE, 16
	.equ	 ENTRY_PFA, 24

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
	.equ	SYSCALL_WRITE, 1
	.equ	SYSCALL_EXIT, 60
