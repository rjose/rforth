#===============================================================================
# DATA section
#===============================================================================
	.section .data

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# Create_rt - Runtime code for Create
#-------------------------------------------------------------------------------
	.globl Create_rt
	.type Create_rt, @function
Create_rt:
	# TODO: Implement this
	nop
	ret



#-------------------------------------------------------------------------------
# Create - Creates a new dictionary entry and advances dictionary pointers
#-------------------------------------------------------------------------------
	.globl Create
	.type Create, @function
Create:
	call read_word

	# Put count in current count cell (pointed to by pfa)
	movb tib_count, %bl
	movq pfa, %rax
	movb %bl, (%rax)

	# Copy first 4 chars from tib to name cells (offset by 4 bytes)
	movq tib, %rbx
	movq %rbx, 4(%rax)

	# Store link to previous dictionary entry
	movq dp, %rbx
	movq %rbx, 8(%rax)

	# Store Create_rt in code pointer
	lea Create_rt, %rbx
	movq %rbx, 16(%rax)

	# Increment dictionary pointers
	# dp = pfa
	movq pfa, %rbx
	movq $dp, %rax
	movq %rbx, (%rax)

	# pfa = dp + 24
	movq dp, %rbx
	addq $24, %rbx
	movq $pfa, %rax
	movq %rbx, (%rax)

	ret
