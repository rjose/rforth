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
# WPlus - Adds top two values from the forth stack
#-------------------------------------------------------------------------------
	.globl WPlus
	.type WPlus, @function

WPlus:
	MPop %rbx
	MPop %rcx
	addq %rbx, %rcx

	# Check for overflow
	jno 0f
	pushq $8
	call Exit

0:
	# Return value
	pushq %rcx
	call PushParam
	MClearStackArgs 1

	ret
