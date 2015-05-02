#===============================================================================
# DATA section
#===============================================================================
	.section .data

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
	movq psp, %rax
	movq -8(%rax), %rbx	# %rbx points to entry
	cmp $0, %rbx
	je 1f			# Number runner

	call DropParam		# Pop param stack
	
	movq %rbx, %rax
	addq $16, %rax		# %rax points to code for entry

	pushq %rbx     		# Push current entry onto stack
	call *(%rax)
	addq $8, %rsp


1:	# TODO: Implement number runner

0:	# Return
	ret
