
#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#===============================================================================
# TEXT section
#===============================================================================
	.section .text

	# Word names
._plus_name:
	.ascii "+\0\0\0"
._minus_name:
	.ascii "-\0\0\0"

#-------------------------------------------------------------------------------
# _plus_rt - Runtime code for "+" word
#-------------------------------------------------------------------------------
	.type _plus_rt, @function
_plus_rt:
	MPop %rbx
	MPop %rcx
	addq %rbx, %rcx
	# TODO: Check for overflow

	# Return value
	pushq %rcx
	call PushParam
	MClearStackArgs 1

	ret

#-------------------------------------------------------------------------------
# _minus_rt - Runtime code for "-" word
#-------------------------------------------------------------------------------
	.type _minus_rt, @function
_minus_rt:
	MPop %rbx
	MPop %rcx
	subq %rcx, %rbx

	# Return value
	pushq %rbx
	call PushParam
	MClearStackArgs 1

	ret

#-------------------------------------------------------------------------------
# DefineMathWords - Defines words for math functions
#-------------------------------------------------------------------------------
	.globl DefineMathWords
	.type DefineMathWords, @function
DefineMathWords:
	# Define "+"
	MDefineWord ._plus_name, $1, _plus_rt
	MDefineWord ._minus_name, $1, _minus_rt

	ret
