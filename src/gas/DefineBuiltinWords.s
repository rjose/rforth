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

	#------------------------------------------------------------
	# Word names
	#------------------------------------------------------------
.name_plus:
	.ascii "+\0\0\0"
.name_minus:
	.ascii "-\0\0\0"
.name_CONSTANT:
	.ascii "CONS"

#-------------------------------------------------------------------------------
# plus_rt - Runtime code for "+" word
#-------------------------------------------------------------------------------
	.type plus_rt, @function

plus_rt:
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
# minus_rt - Runtime code for "-" word
#-------------------------------------------------------------------------------
	.type minus_rt, @function

minus_rt:
	MPop %rbx
	MPop %rcx
	subq %rcx, %rbx

	# Return value
	pushq %rbx
	call PushParam
	MClearStackArgs 1

	ret

#-------------------------------------------------------------------------------
# DefineBuiltinWords - Defines words for math functions
#-------------------------------------------------------------------------------
	.globl DefineBuiltinWords
	.type DefineBuiltinWords, @function

DefineBuiltinWords:
	# Define "+", "-"
	MDefineWord .name_plus, $1, plus_rt
	MDefineWord .name_minus, $1, minus_rt

	# Define "CONSTANT"
	MDefineWord .name_CONSTANT, $8, Constant

	ret
