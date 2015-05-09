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

	# Check top of stack
	movq G_psp, %rax
	movq -8(%rax), %rbx	# %rbx points to entry
	cmp $0, %rbx
	je .number_runner

	# Otherwise, we have the address of a dictionary entry
	call DropParam		# Pop param stack

	# Add 16 to the entry to get to the code for the entry
	movq %rbx, %rax
	addq $16, %rax

	# Execute the code for the entry passing the entry address via the stack.
	# This lets the entry's code access the parameters of the entry.
	pushq %rbx
	call *(%rax)
	addq $8, %rsp
	jmp 0f		# Return


	#------------------------------------------------------------
	# At this point, the last read word is still in the tib
	# buffer, and we need to see if this is a number. If so, then
	# we push the value onto the param stack. If not, then we
	# need to abort (at some point, print a message and clear
	# the param stack).
	#------------------------------------------------------------
.number_runner:
	call DropParam		# Pop the 0 off the stack
	call ReadNumber
	cmp $0, RN_status
	jg .push_number

	# If not a number, we abort
	pushq 5
	call Exit
	addq $8, %rsp
	jmp 0f

.push_number:
	pushq RN_value
	call PushParam
	addq $8, %rsp

0:	# Return
	ret
