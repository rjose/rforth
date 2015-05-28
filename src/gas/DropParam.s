#===============================================================================
# DropParam.s
#
# This "drops" a param from the forth stack by moving the stack
# pointer down an element. Since the stack pointer points to the next
# available stack slot, this is a way to get to the top of the stack
# as well if we're popping a value off.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_underflow:
	.asciz "ERROR: Forth stack underflow"

#========================================
# TEXT section
#========================================
	.section .text


#-------------------------------------------------------------------------------
# DropParam - Drops a param from the param stack
#
# Forth stack args:
#   * value
#
# This consumes the first element of the forth stack.
#-------------------------------------------------------------------------------
	.globl DropParam
	.type DropParam, @function

DropParam:
	pushq %rax                      # Save caller's registers
	
	subq $WORD_SIZE, G_psp          # Move stack pointer down an element

	# Check for underflow
	movq G_psp, %rax                # Put the stack pointer in rax
	subq $G_param_stack, %rax       # Subtract off the start
	cmp $0, %rax                    # If the result
	jge 0f                          # is >= 0, we're good.

	MPrint $.err_underflow          # Otherwise, print an underflow error
	movq $1, G_abort                # and abort.
	                                #
	                                # NOTE: We don't use MAbort, because that
					#       relies on the forth stack which
					#       is messed up at this point.

0:
	popq %rax                       # Restore caller's registers
	ret
