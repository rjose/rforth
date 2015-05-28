#===============================================================================
# WElse.s
#
# This is like a combination of THEN and IF. It ties up the most recent
# dangling address, and then creates another one.
#
# This also defines an unconditional jump to a param index in the cell
# following the jump param.
#
# Please see: https://docs.google.com/document/d/1AXHA4-Bf8tWSeP_3dzgZy5ZHuLQbiQnGWITbi9xSvHs
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
# Jmp_rt
#
# Unconditionally sets the param index to the value of this instruction's
# value cell.
#
# Args:
#   * Stack arg 1: parameter index of this instruction
#   * Stack arg 2: address of the associated colon definition
#
# NOTE: Every "special function" *must* update the param index to point to
#       the next colon definition parameter to execute. This is done directly
#       to STACK_ARG_1(%rbp).
#
# Throughout this function:
#   * rbx holds a parameter index
#   * rcx holds the address of the colon definition
#-------------------------------------------------------------------------------
	.globl Jmp_rt
	.type Jmp_rt, @function
Jmp_rt:
	MPrologue

	pushq %rbx                      # Save caller's registers
	pushq %rcx                      # .
	pushq %rax                      # .
	
	movq STACK_ARG_1(%rbp), %rbx    # Get the instruction's parameter index..
	inc %rbx                        # ..and add 1 to get the jmp index cell

	movq STACK_ARG_2(%rbp), %rcx    # rcx has address of colon definition

	movq ENTRY_PFA(%rcx, %rbx, WORD_SIZE), %rax
	                                # Get the jump index value
	movq %rax, STACK_ARG_1(%rbp)    # and update next param index

	popq %rax                       # Restore caller's registers
	popq %rcx                       # .
	popq %rbx                       # .

	MEpilogue
	ret


#-------------------------------------------------------------------------------
# Compiles an ELSE word.
#
# This fills out the last dangling instruction and creates a jump instruction
# with a new dangling instruction.
#
# Forth Stack:
#   * index of param to fill out
#-------------------------------------------------------------------------------
	.globl WElse
	.type WElse, @function

WElse:
	pushq %rbx                      # Save caller's registers
	pushq %rcx                      # .
	pushq %rax                      # .
	pushq %rdx                      # .

	MPop %rdx                       # Get index of the param to fill out

	# Add Jmp_rt instruction with a placeholder
	lea Jmp_rt, %rbx                # Get a pointer to Jmp_false_rt,
	MAddParameter %rbx              # and add it as the next colon def param
	MPush G_param_index             # Note cur param index to fill out later...
	MAddParameter $0                # ...and add a placeholder for it

	# Fill out most recent dangling slot
	movq G_dp, %rax                 # G_dp is the colon def we're currently in
	movq G_param_index, %rcx        # Cur param index ties up the dangling index
	movq %rcx, ENTRY_PFA(%rax, %rdx, WORD_SIZE)

.done:
	popq %rdx                       # Restore caller's registers
	popq %rax                       # .
	popq %rcx                       # .
	popq %rbx                       # .
	ret

