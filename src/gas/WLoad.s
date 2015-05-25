#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_invalid_file:
	.asciz "ERROR: Cannot LOAD specified file"

.err_cant_close:
	.asciz "ERROR: Can't close file"

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
	MAbort $.err_invalid_file       # Otherwise, abort
	jmp 0f

.set_fd:
	# Save fd
	xor %rbx, %rbx                  # Put current G_input_fd in rbx...
	movl G_input_fd, %ebx           # 
	pushq %rbx                      # ...and push it onto the stack

	movl %eax, G_input_fd           # Set G_input_fd to newly opened fd

	call PushBufferSet              # Store previous "buffer set" state

.interpret:
	call Interpret                  # Interpret next word in opened file
	cmpl $0, RW_is_eof              # If not at the EOF...
	je .interpret                   # ...loop

	movq $SYSCALL_CLOSE, %rax       # Close file we opened
	MSyscall G_input_fd             # 
	cmp $0, %rax                    # Check the return value
	jge .restore_fd                 # If > 0, we're good

	MPrint $.err_cant_close         # Otherwise, print message
	pushq $ERRC_CANT_CLOSE          # and exit
	call Exit                       # .

.restore_fd:
	popq %rbx                       # Get previous G_input_fd from stack
	movl %ebx, G_input_fd           # and restore value.
	call PopBufferSet               # Restore previous "buffer set" state

0:
	movl $0, RW_is_eof              # Clear the EOF flag before we return
	ret
