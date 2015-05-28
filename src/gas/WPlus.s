#===============================================================================
# WPlus.s
#
# Defines word to add two numbers from the forth stack.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_overflow:
	.asciz "ERROR: Overflow when doing PLUS"

#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# WPlus - Adds top two values from the forth stack
#-------------------------------------------------------------------------------
	.globl WPlus
	.type WPlus, @function

WPlus:
	pushq %rbx                      # Save caller's registers
	pushq %rcx                      # .
	
	MPop %rbx                       # Get second arg
	MPop %rcx                       # Get first arg
	addq %rbx, %rcx                 # first + second
	jno .done                       # If no overflow, we're good
	MAbort $.err_overflow           # Otherwise, abort
	jmp 0f

.done:
	MPush %rcx                      # Return value on forth stack
0:
	popq %rcx                       # Restore caller's registers
	popq %rbx                       # .
	ret
