#===============================================================================
# WSlash.s
#
# This defines division for fixed point numbers.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_overflow:
	.asciz "ERROR: Overflow when doing SLASH"

#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# WSlash - Divides top two numbers on stack
#
# TODO: Have this handle large numbers properly
#-------------------------------------------------------------------------------
	.globl WSlash
	.type WSlash, @function

WSlash:
	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .
	pushq %rdx                      # .

	MPop %rbx                       # Get second arg
	MPop %rax                       # Get first arg
	xor %rdx, %rdx                  # Zero out upper bytes

	imul $FIXED_POINT_UNITS, %rax   # Align decimal points (fixed point)

	cmp $0, %rax                    # If dividend
	jge .divide                     # is greater than 0, proceed to divide
	mov $-1, %rdx                   # otherwise, need to pad rdx with 1s

.divide:
	idiv %rbx                       # divide first by second

	jno .done                       # If no overflow, we're good
	MAbort $.err_overflow
	jmp 0f

.done:
	MPush %rax                      # Return result on forth stack

0:
	popq %rdx                       # Restore caller's registers
	popq %rbx                       # .
	popq %rax                       # .
	ret
