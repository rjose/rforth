#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Prints string whose address is at the top of the forth stack
#
# Forth stack:
#   * string address
#-------------------------------------------------------------------------------
	.globl Print
	.type Print, @function

Print:
	MPop %r11                       # Get char* from the forth stack

.loop:
	cmp $ASCII_NUL, (%r11)          # If it's NUL, then
	je 0f                           # we're done

	MPutc (%r11)                    # Otherwise, write the character
	inc %r11                        # Go to the next char...
	jmp .loop                       # and repeat

0:
	MPutc $ASCII_NEWLINE            # Add a newline
	call Flush                      # Flush the buffer
	ret
