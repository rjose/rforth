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
	movq 16(%rbx), %rax	# %rax points to code for entry
	call %rax


1:	# TODO: Implement number runner

0:	# Return
	ret
