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
#
# This reads the next word in the input stream and uses that as the name
# of the entry. On successful execution, a new entry will be added to the
# dictionary, |dp| will point to this latest entry, and |pfa| will point
# to that entries first parameter cell.
#
# If the dictionary entry extends past the dictionary limit, this exits.
#-------------------------------------------------------------------------------
	.globl Create
	.type Create, @function
Create:
	call ReadWord

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

	# Check that we haven't exceeded the dictionary size
	movq pfa, %rax
	cmp dict_size, %rax
	jle 0f

	# Otherwise, abort
	pushq $1
	call Exit

0:	# Return
	ret
