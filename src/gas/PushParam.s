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
# PushParam - Pushes a value onto the parameter stack
#
# Args:
#   * Arg1: value to push onto stack
#
# If the stack size exceeds the max param stack size, this aborts.
#-------------------------------------------------------------------------------
	.globl PushParam
	.type PushParam, @function
PushParam:
	# Check param stack size
	movq G_psp, %rax
	subq $G_param_stack, %rax
	cmp $PARAM_STACK_SIZE, %rax
	jl 1f	     # Push onto stack

	# Otherwise, abort
	pushq $2
	call Exit

1:	# Push first arg onto param stack
	movq 8(%rsp), %rbx
	movq G_psp, %rax
	movq %rbx, (%rax)

	# Advance psp pointer
	addq $8, %rax
	movq %rax, G_psp

0:	# Return
	ret
