#===============================================================================
# Interpret.s
#
# This defines a function that interprets words from an input stream.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_invalid_word:
	.asciz "ERROR: Invalid word"

#========================================
# BSS section
#========================================
	.section .bss

#========================================
# TEXT section
#========================================
	.section .text


#-------------------------------------------------------------------------------
# Interpret - Gets next word and interprets it
#-------------------------------------------------------------------------------
	.globl Interpret
	.type Interpret, @function

Interpret:
	pushq %rbx                      # Save caller's registers

	call Tick                       # Read word and search for entry in dictionary
	MPop %rbx                       # Get entry address
	cmp $0, %rbx                    # If the address is 0...
	je .number_runner               # ...see if the word is a number

	MExecuteEntry %rbx              # Otherwise, execute it
	jmp 0f                          # and then return


.number_runner:
	# NOTE: At this point, the last read word is still in the tib

	call ReadNumber                 # Try reading a number
	cmp $0, RN_status               # Check the read status
	jg .push_number                 # If OK, push number

	cmpl $1, RW_is_eof              # If not OK, see if we're at EOF...
	je 0f                           # ...and just exit if we are
	MAbort $.err_invalid_word       # Otherwise, abort

.push_number:
	MPush RN_value                  # Put the parsed number onto the stack

0:
	popq %rbx                       # Restore caller's registers
	ret
