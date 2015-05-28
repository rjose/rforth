#===============================================================================
# WIf.s
#
# This defines the IF word as well as the |Jmp_false_rt| function that gets
# compiled into a definition because of it.
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
# Jmp_false_rt
#
# Pops a value off the forth stack. If it's 0, then it sets the param index
# to take a FALSE branch. Otherwise, this sets the param index to take the
# TRUE branch.
#
# The index of the FALSE branch is in the cell after the current param index.
# The index of the TRUE branch is 2 after the current param index.
#
# Args:
#   * Stack arg 1: current parameter index
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
	.globl Jmp_false_rt
	.type Jmp_false_rt, @function
Jmp_false_rt:
	MPrologue
	
	pushq %rax                     # Save caller's registers
	pushq %rbx                     # .
	pushq %rcx                     # .
	pushq %rdx                     # .
	
	movq STACK_ARG_1(%rbp), %rbx    # Get the current parameter index
	movq STACK_ARG_2(%rbp), %rcx    # rcx has address of colon definition

	# Check boolean value
	MPop %rdx                       # Get the boolean value to check
	cmp $0, %rdx                    # If false...
	je .false_branch                # ...take the false branch

	addq $2, STACK_ARG_1(%rbp)      # Set param index to TRUE branch
	jmp 0f

.false_branch:
	inc %rbx                        # Next parameter holds jump index

	movq ENTRY_PFA(%rcx, %rbx, WORD_SIZE), %rax
	                                # get the jump index value
	movq %rax, STACK_ARG_1(%rbp)    # and update next param index

0:
	popq %rdx                       # Restore caller's registers
	popq %rcx                       # .
	popq %rbx                       # .
	popq %rax                       # .
	
	MEpilogue
	ret

#-------------------------------------------------------------------------------
# Compiles first part of a condition into a colon definition.
#
# This is an immediate word that sets up a jump index for a conditional.
#
# Spec: https://docs.google.com/document/d/1AXHA4-Bf8tWSeP_3dzgZy5ZHuLQbiQnGWITbi9xSvHs
#
# NOTE: We're using the forth stack to push and pop indexes of parameters to
#       fill out later when we know what they should be. Other immediate words
#       should be careful about how they use the forth stack to ensure it is
#       consistent across IF, ELSE, and THEN.
#-------------------------------------------------------------------------------
	.globl WIf
	.type WIf, @function

WIf:
	pushq %rbx                              # Save caller's registers
	
	lea Jmp_false_rt, %rbx                  # Get a pointer to Jmp_false_rt,
	MAddParameter %rbx                      # and add it as the next colon def param

	MPush G_param_index                     # Note cur param index to fill out later...
	MAddParameter $0                        # ...and hold a placeholder for it

.done:
	popq %rbx                               # Restore caller's registers
	ret

