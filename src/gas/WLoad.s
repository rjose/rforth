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
# WLoad - Loads and interprets an rforth file.
#
# This assumes there's a pointer to a filename string on the forth stack.
#-------------------------------------------------------------------------------
	.globl WLoad
	.type WLoad, @function

WLoad:
	# Open the file on the stack
	MPop %rdi                       # Pop filename into rdi
	movq $SYSCALL_OPEN, %rax        # Indicate that we'll do an "open" syscall
	MSyscall %rdi, $O_RDONLY, $0    # Open the file read only
	cmp $0, %rax                    # Check the return value
	jge .set_fd                     # If > 0, we have a file descriptor

	pushq $19                       # Otherwise, abort
	call Exit

.set_fd:
	# Save fd
	xor %rbx, %rbx                  # Zero out rbx
	movl G_input_fd, %ebx           # Put fd in 32 bit portion
	pushq %rbx                      # Push current G_input_fd onto stack

	movl %eax, G_input_fd           # Set fd to opened file

.interpret:
	call Interpret                  # Interpret next word
	cmpl $0, RW_is_eof              # If not at the EOF...
	je .interpret                   # ...loop

	# Close file
	movq $SYSCALL_CLOSE, %rax       # Indicate that we'll do an "close" syscall
	MSyscall G_input_fd             # Close the current fd
	cmp $0, %rax                    # Check the return value
	jge .restore_fd                 # If > 0, we're good

	pushq $20                       # Otherwise, abort
	call Exit

.restore_fd:
	popq %rbx                       # Get previous G_input_fd from stack
	movl %ebx, G_input_fd           # and restore value.
	ret
