#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_underflow:
	.asciz "ERROR: Forth stack underflow"

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
	subq $WORD_SIZE, G_psp

	# Check for underflow
	movq G_psp, %rax
	subq $G_param_stack, %rax
	cmp $0, %rax
	jge 0f

	# Need to do a custom print since we're manipulating the forth stack
	MPrint $.err_underflow
	movq $1, G_abort

0:	# Return
	ret
