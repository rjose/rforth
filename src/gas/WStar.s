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
# WStar - Multiplies top two numbers on stack
#-------------------------------------------------------------------------------
	.globl WStar
	.type WStar, @function

WStar:
	MPop %rbx
	MPop %rax
	xor %rdx, %rdx
	imul %rbx, %rax

	# Realign decimal points
	movq $FIXED_POINT_UNITS, %rbx
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
