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
# Assumptions:
#   * RW_tib: Should have the name of the entry to create
#   * RW_tib_count: Should have length of name
#
# On successful execution, a new entry will be added to the
# dictionary, |G_dp| will point to this latest entry, and |pfa| will point
# to that entries first parameter cell.
#
# If the dictionary entry extends past the dictionary limit, this exits.
#-------------------------------------------------------------------------------
	.globl CreateAfterReadWord
	.type CreateAfterReadWord, @function

CreateAfterReadWord:
	movq $0, G_param_index          # Reset param index for this definition

	# Put count in current count cell (pointed to by G_pfa)
	movb RW_tib_count, %bl
	movq G_pfa, %rax
	movb %bl, (%rax)

	# Copy first 4 chars from tib to name cells
	movl RW_tib, %ebx
	movl %ebx, ENTRY_NAME(%rax)

	# Store link to previous dictionary entry
	movq G_dp, %rbx
	movq %rbx, ENTRY_LINK(%rax)

	# Store Create_rt in code pointer
	lea Create_rt, %rbx
	movq %rbx, ENTRY_CODE(%rax)

	# Increment dictionary pointers
	
	# Make G_dp point to the new entry (currently G_pfa)
	movq G_pfa, %rbx
	movq $G_dp, %rax
	movq %rbx, (%rax)

	# Make G_pfa point to the first parameter field of the new entry
	movq G_dp, %rbx
	addq $ENTRY_PFA, %rbx
	movq $G_pfa, %rax
	movq %rbx, (%rax)

	# Check that we haven't exceeded the dictionary size
	movq G_pfa, %rax
	subq $G_dictionary, %rax
	cmp $DICT_SIZE, %rax
	jle 0f

	# Otherwise, abort
	MPrint $G_err_dictionary_exceeded  # Print error message
	pushq $1                        # And exit with a code of 1
	call Exit                       # .

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
