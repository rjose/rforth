#===============================================================================
# WThen.s
#
# Defines the immediate THEN word which figures out where the last
# conditional jump should go to (right after the THEN).
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#========================================
# TEXT section
#========================================
	.section .text


#-------------------------------------------------------------------------------
# Fills out last conditional jump index
#
# Forth Stack:
#   Top: index of param to fill out
#
# Spec: https://docs.google.com/document/d/1AXHA4-Bf8tWSeP_3dzgZy5ZHuLQbiQnGWITbi9xSvHs
#-------------------------------------------------------------------------------
	.globl WThen
	.type WThen, @function

WThen:
	pushq %rax                      # Store caller's registers
	pushq %rbx                      # .
	pushq %rcx                      # .

	MPop %rbx                       # Index of the param to fill out
	movq G_dp, %rax                 # G_dp is the colon def we're currently in

	movq G_param_index, %rcx        # Fill out dangling Jmp_false slot
	movq %rcx, ENTRY_PFA(%rax, %rbx, WORD_SIZE)

	popq %rcx                       # Restore caller's registers
	popq %rbx                       # .
	popq %rax                       # .

.done:
	ret

