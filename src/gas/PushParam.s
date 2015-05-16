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
# Stack Args:
#   * Arg 1: value to push onto stack
#
# If the stack size exceeds the max param stack size, this aborts.
#-------------------------------------------------------------------------------
	.globl PushParam
	.type PushParam, @function

PushParam:
	MPrologue

	# Check param stack size
	movq G_psp, %rax
	subq $G_param_stack, %rax
	cmp $PARAM_STACK_SIZE, %rax
	jl .push_arg

	# Otherwise, abort
	pushq $2
	call Exit

.push_arg:
	movq STACK_ARG_1(%rbp), %rbx
	movq G_psp, %rax
	movq %rbx, (%rax)

	# Advance psp pointer
	addq $WORD_SIZE, %rax
	movq %rax, G_psp

0:
	MEpilogue
	ret
