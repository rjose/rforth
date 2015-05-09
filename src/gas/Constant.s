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
# Constant_rt - Runtime code for Constant
#
# Stack Args:
#   * Arg 1: Address of dictionary entry
#
# This pushes the parameter value of the dictionary entry onto the forth stack.
#-------------------------------------------------------------------------------
	.globl Constant_rt
	.type Constant_rt, @function

Constant_rt:
	movq STACK_ARG_1(%rsp), %rbx		# First arg is dictionary entry
	movq ENTRY_PFA_OFFSET(%rbx), %rax	# Parameter value
	MPush %rax
	ret


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

	# Point the code for this entry to Constant_rt
	lea Constant_rt, %rbx
	movq G_dp, %rax
	movq %rbx, ENTRY_CODE_OFFSET(%rax)

	# Pop a value off the forth stack and put it into the next parameter field slot
	MPop %rbx
	MAddParameter %rbx
	ret
