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
	movl %eax, %ecx                 # Store opened fd in ecx so PushBufferSet
	call PushBufferSet              # can use it with a fresh buffer set.

.interpret:
	call Interpret                  # Interpret next word in opened file
	cmpl $0, RW_is_eof              # If not at the EOF...
	je .interpret                   # ...loop

	call PopBufferSet               # Restore prev buffer set (rcx will hold popped fd)

	movq $SYSCALL_CLOSE, %rax       # Close file we opened
	MSyscall %rcx                   # using fd from popped buffer set
	cmp $0, %rax                    # Check the return value
	jge 0f                          # If > 0, we're good

	MPrint $.err_cant_close         # Otherwise, print message
	pushq $ERRC_CANT_CLOSE          # and exit
	call Exit                       # .

0:
	movl $0, RW_is_eof              # Clear the EOF flag before we return
	ret
