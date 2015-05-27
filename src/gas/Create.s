#===============================================================================
# Create.s
#
# This defines functions for the creation of rforth dictionary words. The
# |Create| function reads the next word from input and creates a new
# dictionary entry with that name. The nominal code pointer is set to
# |Nop| which does nothing.
#
# The |CreateAfterReadWord| does all of the work. It's factored out
# this way to allow the creation of dictionary entries where the entry
# name is known up front and shouldn't be read from input.
#===============================================================================


#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# Nop - No op
#-------------------------------------------------------------------------------
	.globl Nop
	.type Nop, @function
Nop:
	nop
	ret

#-------------------------------------------------------------------------------
# CreateAfterReadWord - Creates a dictionary entry assuming ReadWord was called
#
# Assumptions:
#   * RW_tib: Should have the name of the entry to create
#   * RW_tib_count: Should have the length of name
#
# On successful execution, a new entry will be added to the
# dictionary, |G_dp| will point to this latest entry, and |pfa| will
# point to that entries first parameter cell.
#
# If the dictionary entry extends past the dictionary limit, this
# exits.
#
# Modifies:
#   * G_param_index, G_pfa
#-------------------------------------------------------------------------------
	.globl CreateAfterReadWord
	.type CreateAfterReadWord, @function

CreateAfterReadWord:
	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .

	movq $0, G_param_index          # Reset param index for this definition

	movb RW_tib_count, %bl          # Put the word size in bl
	movq G_pfa, %rax                # and write it to the next entry's
	movb %bl, (%rax)                # COUNT cell (pointed to by G_pfa)

	movl RW_tib, %ebx               # Grab the first 4 chars of the word
	movl %ebx, ENTRY_NAME(%rax)     # and write to the next entry's NAME cell

	movq G_dp, %rbx                 # Put the current entry's address in rbx
	movq %rbx, ENTRY_LINK(%rax)     # and write to the next entry's LINK cell

	# Store Nop in code pointer
	lea Nop, %rbx                   # Put Nop in rbx
	movq %rbx, ENTRY_CODE(%rax)     # and write to the next entry's CODE cell

	# Increment dictionary pointers
	movq G_pfa, %rbx                # Put the next entry's address in rbx
	movq %rbx, G_dp                 # and make it the current entry
	addq $ENTRY_PFA, %rbx           # Point rbx to the new entry's first param cell
	movq %rbx, G_pfa                # and write to G_pfa

	# Check that we haven't exceeded the dictionary size
	subq $G_dictionary, %rbx        # Compute dictionary size
	cmp $DICT_SIZE, %rbx            # If it's within bounds then
	jle 0f                          # we're good

	MPrint $G_err_dictionary_exceeded  # Otherwise, print error message
	pushq $ERRC_OUT_OF_DICTIONARY      # and
	call Exit                          # exit

0:
	popq %rbx                       # Restore caller's registers
	popq %rax                       # .
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
	call ReadWord                   # The next word is the entry's name
	call CreateAfterReadWord        # Create an entry with that name
	ret
