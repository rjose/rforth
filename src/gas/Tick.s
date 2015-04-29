#===============================================================================
# DATA section
#===============================================================================
	.section .data

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
#-------------------------------------------------------------------------------
	.globl Tick
	.type Tick, @function
Tick:
	# Get word to search for
	call ReadWord

	# Start at first entry
	movq dp, %rax

1:	# Loop
	cmp $0, %rax
	jne 2f		# Search for word

	# Otherwise, return 0
	pushq $0
	jmp 0f		# Return value

2:	# Search for word

	# Compare tib_count with entry
	movb  tib_count, %bl
	cmp %bl, (%rax)
	jne 3f		# Check earlier entry

	# Compare first 4 chars with entry
	movl tib, %ebx
	cmp %ebx, 4(%rax)
	jne 3f		# Check earlier entry

	# Otherwise, we have a match!
	pushq %rax
	jmp 0f

3:	# Check earlier entry
	movq 8(%rax), %rbx	# Previous link
	movq %rbx, %rax
	jmp 1b
	

0:	# Return address of entry on param stack
	call PushParam
	addq $8, %rsp	# Remove stack arg
	ret
