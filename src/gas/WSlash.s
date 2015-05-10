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

#-------------------------------------------------------------------------------
# WSlash - Multiplies top two numbers on stack
#-------------------------------------------------------------------------------
	.globl WSlash
	.type WSlash, @function

WSlash:
	MPop %rbx
	MPop %rax
	xor %rdx, %rdx

	# Align decimal points and divide
	imul $FIXED_POINT_UNITS, %rax
	idiv %rbx

	# Check for overflow
	jno 0f
	pushq $8
	call Exit

0:
	# Return value
	pushq %rax
	call PushParam
	MClearStackArgs 1

	ret
