#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_overflow:
	.asciz "ERROR: Overflow when doing STAR"

#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Dup - Duplicates top element of forth stack
#-------------------------------------------------------------------------------
	.globl Dup
	.type Dup, @function

Dup:
	MPop %r14                       # Get top of stack
	MPush %r14                      # and push it
	MPush %r14                      # twice
	ret

#-------------------------------------------------------------------------------
# Swap - Swaps top two elements of forth stack
#-------------------------------------------------------------------------------
	.globl Swap
	.type Swap, @function

Swap:
	MPop %r14                       # Get top element
	MPop %r15                       # and next element down
	MPush %r14                      # Push old top element
	MPush %r15                      # Push old next element
	ret



#-------------------------------------------------------------------------------
# Over - Copies second element and adds to top of stack
#-------------------------------------------------------------------------------
	.globl Over
	.type Over, @function

Over:
	MPop %r14                       # Get top element
	MPop %r15                       # and next element down
	MPush %r15                      # Push old next element
	MPush %r14                      # Push old top element
	MPush %r15                      # Push old next element again
	ret
