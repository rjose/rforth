#===============================================================================
# Tick.s
#
# This defines searching for words in the dictionary. It is named after
# forth's "`" word.
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
	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .

	call ReadWord                   # Read word to search for

	movq G_dp, %rax                 # Start search at most recent entry
.loop:
	cmp $0, %rax                    # If it's
	jne .check_entry                # not zero, check for a match.
	jmp 0f                          # Otherwise, we didn't find it (0 is
	                                # the start of the dictionary).

.check_entry:
	movb  RW_tib_count, %bl         # Put the length of the word in bl
	cmp %bl, ENTRY_COUNT(%rax)      # If the length of the entry word
	jne .try_previous_entry         # doesn't match, try previous entry.

	movl RW_tib, %ebx               # Otherwise, get the first 4 chars of word
	cmp %ebx, ENTRY_NAME(%rax)      # If the chars in the entry word
	jne .try_previous_entry         # don't match, try previous entry.

	jmp 0f                          # Otherwise, we have a match!

.try_previous_entry:
	movq ENTRY_LINK(%rax), %rbx     # Put the link of the prev entry in rbx
	movq %rbx, %rax                 # Copy to rax
	jmp .loop                       # and try again
	
0:
	pushq %rax                      # rax has the entry's address
	call PushParam                  # Return it via the forth stack
	MClearStackArgs 1               # Remove stack arg

	popq %rbx                       # Restore caller's registers
	popq %rax                       # .
	ret
