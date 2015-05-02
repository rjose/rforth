#===============================================================================
# DATA section
#===============================================================================
	.section .data

#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Constant_rt - Runtime code for Constant
#
# The entry address is on the return stack. We'll use that to find the
# parameter value.
#-------------------------------------------------------------------------------
	.globl Constant_rt
	.type Constant_rt, @function
Constant_rt:
	movq 8(%rsp), %rbx	# First arg is dictionary entry
	movq 24(%rbx), %rax	# Parameter value

	# Push onto param stack
	pushq %rax
	call PushParam
	addq $8, %rsp		# Drop pushed value from assmebly stack
	ret


#-------------------------------------------------------------------------------
# Constant - Creates a constant entry in the dictionary.
#
# Args:
#   * (value) : Constant value
#   * next word: Name of the entry
#
# This consumes the first element of the forth stack.
#-------------------------------------------------------------------------------
	.globl Constant
	.type Constant, @function
Constant:
	# Create new dictionary entry
	call Create

	# Point the code for this entry to Constant_rt
	lea Constant_rt, %rbx
	movq dp, %rax
	movq %rbx, 16(%rax)

	# Store the value of the constant in pfa
	movq psp, %rax
	movq -8(%rax), %rbx	# Top of stack is one element before psp
	movq pfa, %rax
	movq %rbx, (%rax)
	call DropParam

	# Advance pfa
	addq $8, %rax
	movq %rax, pfa

	ret
