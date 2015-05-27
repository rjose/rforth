#===============================================================================
# WLoad.s
#
# This opens a file and interprets its contents.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_invalid_file:
	.asciz "ERROR: Cannot LOAD specified file"

.err_cant_close:
	.asciz "ERROR: Can't close file"

#========================================
# TEXT section
#========================================
	.section .text


#-------------------------------------------------------------------------------
# Loads and interprets an rforth file
#
# Forth stack:
#   * pointer to filename
#-------------------------------------------------------------------------------
	.globl WLoad
	.type WLoad, @function

WLoad:
	pushq %rdi                      # Save caller's registers
        pushq %rax                      # .
	pushq %rcx                      # .
	
	# Open the file on the stack
	MPop %rdi                       # Pop filename into rdi...
	movq $SYSCALL_OPEN, %rax        # and
	MSyscall %rdi, $O_RDONLY, $0    # open it read-only
	cmp $0, %rax                    # If the return value
	jge .push_buffer_set            # is > 0, we have a valid fd.
	MAbort $.err_invalid_file       # Otherwise, abort
	jmp 0f                          # and return

.push_buffer_set:
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

	popq %rcx                       # Restore caller's registers
	popq %rax                       # .
	popq %rdi                       # .
	ret
