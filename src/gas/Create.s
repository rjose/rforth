#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

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
	nop
	ret


#-------------------------------------------------------------------------------
# CreateAfterReadWord - Creates a dictionary entry assuming ReadWord has was called
#
# Args:
#   * tib: Should have the name of the entry to create
#   * tib_count: Should have length of name
#
# On successful execution, a new entry will be added to the
# dictionary, |dp| will point to this latest entry, and |pfa| will point
# to that entries first parameter cell.
#
# If the dictionary entry extends past the dictionary limit, this exits.
#-------------------------------------------------------------------------------
	.globl CreateAfterReadWord
	.type CreateAfterReadWord, @function
CreateAfterReadWord:
	# Put count in current count cell (pointed to by pfa)
	movb RW_tib_count, %bl
	movq G_pfa, %rax
	movb %bl, (%rax)

	# Copy first 4 chars from tib to name cells (offset by 4 bytes)
	movq RW_tib, %rbx
	movq %rbx, 4(%rax)

	# Store link to previous dictionary entry
	movq G_dp, %rbx
	movq %rbx, 8(%rax)

	# Store Create_rt in code pointer
	lea Create_rt, %rbx
	movq %rbx, 16(%rax)

	# Increment dictionary pointers
	
	# Dp := Pfa
	movq G_pfa, %rbx
	movq $G_dp, %rax
	movq %rbx, (%rax)

	# Pfa := Dp + 24
	movq G_dp, %rbx
	addq $24, %rbx
	movq $G_pfa, %rax
	movq %rbx, (%rax)

	# Check that we haven't exceeded the dictionary size
	movq G_pfa, %rax
	subq $G_dictionary, %rax
	cmp $DICT_SIZE, %rax
	jle 0f

	# Otherwise, abort
	pushq $1
	call Exit

0:	# Return
	ret


#-------------------------------------------------------------------------------
# Create - Creates a new dictionary entry and advances dictionary pointers
#
# This reads the next word in the input stream and then calls CreateAfterReadWord
# to actually create the entry. See the comments for that function above.
#-------------------------------------------------------------------------------
	.globl Create
	.type Create, @function
Create:
	call ReadWord
	call CreateAfterReadWord
	ret
