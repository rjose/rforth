#===============================================================================
# WDotS.s
#
# This prints all the values on the forth stack. The top of stack is
# on top. The bottom of the stack is indicated by "--".
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
# Putc's all the characters from a WriteNumber
#
# The following registers are used throughout:
#   * %rcx: To count the number of characters to write
#   * %rdx: To hold the address to read from
#-------------------------------------------------------------------------------
	.type put_number, @function

put_number:
	pushq %rcx                      # Save caller's registers
	pushq %rdx                      # .
	pushq %rax                      # . (MPutc uses this)

	movl WN_len, %ecx               # Initialize num chars to write
	movq WN_start, %rdx             # Put start of string in rdx

.loop:
	cmp $0, %ecx                    # If there are
	jle 0f                          # no more chars, we're done.

	MPutc (%rdx)                    # Write char out

	dec %ecx                        # Decrement num chars to write
	inc %rdx                        # Advance to next char
	jmp .loop                       # And loop

0:
	popq %rax                       # Restore caller's registers
	popq %rdx                       # .
	popq %rcx                       # .
	ret
	

#-------------------------------------------------------------------------------
# WDotS - Prints stack from top to bottom
#
# The following registers are used throughout:
#   * %rsi:   Points to current stack element to print
#
# NOTE: We don't check the stack bounds because this should have been checked
#       when we pushed items onto the stack.
#-------------------------------------------------------------------------------
	.globl WDotS
	.type WDotS, @function

WDotS:
	pushq %rsi                      # Save caller's registers
	pushq %rax                      # .
	
	MPutc $ASCII_NEWLINE            # Start with a newline

	movq G_psp, %rsi                # Get end of stack (one above top)
	cmp $G_param_stack, %rsi        # and
	je .done                        # if stack is empty, we're done.

	subq $WORD_SIZE, %rsi           # Otherwise, step back to top of stack

.print_element:
	cmp $G_param_stack, %rsi        # If at the bottom of the stack then
	jl .done                        # we're done.

	movq (%rsi), %rax               # Otherwise, put the number in rax and
	call WriteNumber                # format the number,
	call put_number                 # write it out, and
	MPutc $ASCII_NEWLINE            # go to the next line

	subq $WORD_SIZE, %rsi           # Go down one element in the stack
	jmp .print_element              # and repeat

.done:
	MPutc $ASCII_MINUS              # Indicate bottom of stack with a "-"
	MPutc $ASCII_MINUS              # and another "-"
	MPutc $ASCII_NEWLINE            # and a newline
	call Flush                      # Flush everything to the console
0:
	popq %rax                       # Restore caller's registers
	popq %rsi                       # .
	ret
