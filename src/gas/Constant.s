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
# Constant - Creates a constant entry in the dictionary.
#
# Args:
#   * (value) : Constant value
#   * next word: Name of the entry
#
# This consumes the first element of the forth stack.
#-------------------------------------------------------------------------------
	.globl Constant
	.type Constant, @function

Constant:
	# Create new dictionary entry
	call Create

	# A constant entry just pushes its value onto the forth stack
	lea PushEntryParam1, %rbx
	movq G_dp, %rax
	movq %rbx, ENTRY_CODE_OFFSET(%rax)

	# Pop a value off the forth stack and put it into the next parameter field slot
	MPop %rbx
	MAddParameter %rbx
	ret
