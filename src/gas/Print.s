#===============================================================================
# Print.s
#
# This defines functions for printing things to the console.
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
# Prints string whose address is at the top of the stack
#
# Stack Args:
#   * Arg 1: String to print
#-------------------------------------------------------------------------------
	.globl Print
	.type Print, @function

Print:
	MPrologue
	pushq %r11                      # Save caller's registers

	movq STACK_ARG_1(%rbp), %r11    # Store address of string in r11

.loop:
	cmpb $ASCII_NUL, (%r11)         # If it's NUL, then
	je 0f                           # we're done

	MPutc (%r11)                    # Otherwise, write the character
	inc %r11                        # Go to the next char...
	jmp .loop                       # and repeat

0:
	MPutc $ASCII_NEWLINE            # Add a newline
	call Flush                      # Flush the buffer

	popq %r11                       # Restore caller's registers
	MEpilogue
	ret

#-------------------------------------------------------------------------------
# Prints string whose address is at the top of the forth stack
#
# Forth stack:
#   * string address
#-------------------------------------------------------------------------------
	.globl ForthPrint
	.type Print, @function

ForthPrint:
	pushq %r11                      # Save caller's registers
	
	MPop %r11                       # Get char* from the forth stack
	MPrint %r11                     # and print it
	
	popq %r11                       # Restore caller's registers
	ret
