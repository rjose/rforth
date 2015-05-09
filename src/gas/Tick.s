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
# Tick - Looks up a dictionary entry for a word
#
# This reads the next word in the input stream and searches for it in the
# dictionary. If found, it puts the address of the entry on the forth stack.
# If not found, it puts 0 on the forth stack.
#
# Throughout this function %rax holds a pointer to the current entry
#-------------------------------------------------------------------------------
	.globl Tick
	.type Tick, @function
Tick:
	# Get word to search for
	call ReadWord

	# Start at most recent dictionary entry
	movq G_dp, %rax

.loop:
	# If entry isn't zero, check it; otherwise, it's not there.
	cmp $0, %rax
	jne .check_entry
	jmp 0f

.check_entry:
	# Compare RW_tib_count with count in entry
	movb  RW_tib_count, %bl
	cmp %bl, ENTRY_COUNT_OFFSET(%rax)
	jne .try_previous_entry

	# Compare first 4 chars with entry
	movl RW_tib, %ebx
	cmp %ebx, ENTRY_NAME_OFFSET(%rax)
	jne .try_previous_entry

	# Otherwise, we have a match!
	jmp 0f

.try_previous_entry:
	movq ENTRY_LINK_OFFSET(%rax), %rbx
	movq %rbx, %rax
	jmp .loop
	
0:	# Return the entry's address
	pushq %rax
	call PushParam
	MClearStackArgs 1
	ret
