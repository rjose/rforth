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
# WMinus - Adds top two values from the forth stack
#-------------------------------------------------------------------------------
	.globl WMinus
	.type WMinus, @function

WMinus:
	MPop %rbx
	MPop %rcx
	subq %rbx, %rcx

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
