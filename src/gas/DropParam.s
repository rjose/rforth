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
# DropParam - Drops a param from the param stack
#
# Args:
#   * (value) : value
#
# This consumes the first element of the forth stack.
#
# NOTE: This modifies %rax
#-------------------------------------------------------------------------------
	.globl DropParam
	.type DropParam, @function
DropParam:
	# Move stack pointer back an element
	subq $8, G_psp

	# Check for underflow
	movq G_psp, %rax
	subq $G_param_stack, %rax
	cmp $0, %rax
	jge 0f

	pushq $4
	call Exit

0:	# Return
	ret
