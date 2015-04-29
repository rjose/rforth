#===============================================================================
# DATA section
#===============================================================================
	.section .data

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# PushParam - Pushes a value onto the parameter stack
#
# If the stack size exceeds the max param stack size, this aborts.
#-------------------------------------------------------------------------------
	.globl PushParam
	.type PushParam, @function
PushParam:
	# Check param stack size
	movq psp, %rax
	subq $param_stack, %rax
	cmp ps_size, %rax
	jl 1f	     # Push onto stack

	# Otherwise, abort
	pushq $2
	call Exit

1:	# Push first arg onto param stack
	movq 8(%rsp), %rbx
	movq psp, %rax
	movq %rbx, (%rax)

	# Advance psp pointer
	addq $8, %rax
	movq %rax, psp

0:	# Return
	ret
