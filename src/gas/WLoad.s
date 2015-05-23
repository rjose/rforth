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
	MPop %rdi                       # Pop filename into rdi...
	movq $SYSCALL_OPEN, %rax        # and open it read-only
	MSyscall %rdi, $O_RDONLY, $0    # 
	cmp $0, %rax                    # Check the return value
	jge .set_fd                     # If > 0, we have a file descriptor

	pushq $19                       # Otherwise, abort
	call Exit

.set_fd:
	# Save fd
	xor %rbx, %rbx                  # Put current G_input_fd in rbx...
	movl G_input_fd, %ebx           # 
	pushq %rbx                      # ...and push it onto the stack

	movl %eax, G_input_fd           # Set G_input_fd to newly opened fd

.interpret:
	call Interpret                  # Interpret next word in opened file
	cmpl $0, RW_is_eof              # If not at the EOF...
	je .interpret                   # ...loop

	movq $SYSCALL_CLOSE, %rax       # Close file we opened
	MSyscall G_input_fd             # 
	cmp $0, %rax                    # Check the return value
	jge .restore_fd                 # If > 0, we're good

	pushq $20                       # Otherwise, abort
	call Exit

.restore_fd:
	popq %rbx                       # Get previous G_input_fd from stack
	movl %ebx, G_input_fd           # and restore value.
	ret
