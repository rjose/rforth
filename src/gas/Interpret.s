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

	# TODO: If get EOF, we should indicate this

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
	# buffer, and we need to see if this is a number. If it is a number,
	# we push that number onto the param stack. If not, then we
	# need to abort (at some point, print a message and clear
	# the param stack).
	#------------------------------------------------------------
	call ReadNumber
	cmp $0, RN_status
	jg .push_number

	pushq $5
	call Exit

.push_number:
	pushq RN_value
	call PushParam
	MClearStackArgs 1

0:	# Return
	ret
