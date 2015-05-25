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
# WStar - Multiplies top two numbers on stack
#
# TODO: Have this handle large numbers properly
#-------------------------------------------------------------------------------
	.globl WStar
	.type WStar, @function

WStar:
	MPop %rbx                       # Get second arg
	MPop %rax                       # Get first arg
	xor %rdx, %rdx                  # Zero out result register
	imul %rbx, %rax                 # first * second

	cmp $0, %rax                    # If product is positive, then
	jge .realign_decimal            # realign decimal
	mov $-1, %rdx                   # Otherwise, need to pad rdx with 1s

.realign_decimal:
	movq $FIXED_POINT_UNITS, %rbx   # Realign decimal points (fixed point)
	idiv %rbx                       # .

	jno .done                       # If no overflow, we're good
	MAbort $.err_overflow
	jmp 0f

.done:
	MPush %rax                      # Return value on forth stack
0:
	ret
