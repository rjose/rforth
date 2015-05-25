#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_invalid_word:
	.asciz "ERROR: Invalid word"

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# Interpret - Gets next word and interprets it
#-------------------------------------------------------------------------------
	.globl Interpret
	.type Interpret, @function

Interpret:
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

	MPush $.err_invalid_word        # Otherwise, abort
	call Abort

.push_number:
	MPush RN_value                  # Put the parsed number onto the stack

0:	# Return
	ret
