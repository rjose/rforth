#===============================================================================
# PushParam.s
#
# This defines functions for adding values to the forth stack
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_out_of_space:
	.asciz "ERROR: Forth stack out of space"

#========================================
# TEXT section
#========================================
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

	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .

	# Check param stack size
	movq G_psp, %rax                # Put top of forth stack address in rax
	subq $G_param_stack, %rax       # Subtract from start to get size
	cmp $PARAM_STACK_SIZE, %rax     # If there's room on the forth stack
	jl .push_arg                    # push the new value.

	MAbort $.err_out_of_space       # Otherwise, abort
	jmp 0f                          # and exit

.push_arg:
	movq STACK_ARG_1(%rbp), %rbx    # Put the value to push in rbx
	movq G_psp, %rax                # Put top of forth stack address in rax
	movq %rbx, (%rax)               # and write value into it

	addq $WORD_SIZE, %rax           # Advance the stack pointer
	movq %rax, G_psp                # and update G_psp

0:
	popq %rbx                       # Restore caller's registers
	popq %rax                       # .

	MEpilogue
	ret
