#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

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
	# Read next word and look it up in the dictionary
	call Tick

	# Pop the address of the entry Tick found into %rbx
	MPop %rbx

	# If the address is 0, then check for a number
	cmp $0, %rbx
	je .number_runner

	# Otherwise, call the entry's runtime function
	MExecuteEntry %rbx
	jmp 0f


.number_runner:
	#------------------------------------------------------------
	# At this point, the last read word is still in the tib
	# buffer, and we need to see if this is a number.
	#------------------------------------------------------------
	call ReadNumber                 # Try reading a number
	cmp $0, RN_status               # Check the read status
	jg .push_number                 # If OK, push number

	cmpl $1, RW_is_eof              # If not OK, see if we're at EOF...
	je 0f                           # ...and just exit if we are

	pushq $5                        # Otherwise, abort
	call Exit

.push_number:
	pushq RN_value
	call PushParam
	MClearStackArgs 1

0:	# Return
	ret
