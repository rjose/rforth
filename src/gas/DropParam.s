#===============================================================================
# DATA section
#===============================================================================
	.section .data

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
#-------------------------------------------------------------------------------
	.globl DropParam
	.type DropParam, @function
DropParam:
	# Move stack pointer back an element
	subq $8, psp

	# Check for underflow
	movq psp, %rax
	subq $param_stack, %rax
	cmp $0, %rax
	jge 0f

	pushq $4
	call Exit

0:	# Return
	ret
