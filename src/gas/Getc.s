#===============================================================================
# Getc.s
#
# This defines buffered reads from an input fd. To allow for nested
# reads (as when a file that is LOADed contains LOAD instructions), we
# must allow for multiple open file descriptors *and* multiple input
# buffers.  We use the concept of a "buffer set" to represent a
# particular input buffer and its state.
#
# On start, the current buffer set is 0, and this corresponds to an fd
# of STDIN. When a new file is opened as an input stream, the caller
# uses |PushBufferSet| to push a new buffer set onto the stack. When
# done, it calls |PopBufferSet| to restore the previous buffer.
#
# The |Getc| function returns the next character from the current
# buffer set.  When the buffer is empty, it reads another line from
# the current buffer set's fd.
#===============================================================================


#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ  MAXLINE, 256              # Length of each buffer
	.equ  NUM_BUFFER_SETS, 16       # Number of each buffer set

#---------------------------------------
# Error strings
#---------------------------------------
.err_out_of_buffer_sets:
	.asciz "ERROR: Ran out of buffer sets"

.err_buffer_set_underflow:
	.asciz "ERROR: Buffer set underflow"

#---------------------------------------
# Buffer set state
#---------------------------------------
.buffer_set_index:                      # Index of current buffer set
	.int  0

.num_chars_read:                        # Number of chars currently loaded into each buffer set
	.int	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.buf_index:                             # Index of the next char in each buffer set to return
	.int	MAXLINE, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

.input_fd:                              # Index of the next char in each buffer set to return
	.int	STDIN, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

#---------------------------------------
# Pointers
#---------------------------------------
.num_chars_read_p:                      # Pointer to num chars read for current buffer set
	.quad .num_chars_read

.buf_index_p:                           # Pointer to index of next char in current buffer set
	.quad .buf_index

.input_fd_p:                            # Pointer to current buffer set's input fd
	.quad .input_fd

.buffer_p:                              # Pointer to buffer in buffer set
	.quad buffer

#========================================
# BSS section
#========================================
	.section .bss

	.lcomm buffer, NUM_BUFFER_SETS*MAXLINE   # Buffers for our buffer sets


#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# Sets next buffer set as current buffer set
#
# Register Args:
#   ecx: file descriptor of buffer set to push
#-------------------------------------------------------------------------------
	.globl PushBufferSet
	.type PushBufferSet, @function

PushBufferSet:
	pushq %rax                      # Save caller's rax

	incl .buffer_set_index          # Advance buffer set index
	cmp $NUM_BUFFER_SETS, .buffer_set_index
	jl .increment_pointers          # If index is still valid, set up new buffer set.
	MPrint $.err_out_of_buffer_sets # Otherwise, print a message
	pushq $ERRC_OUT_OF_BUFFER_SETS  # and exit
	call Exit                       # .

.increment_pointers:
	addq $INT_SIZE, .num_chars_read_p  # Go to next element
	addq $INT_SIZE, .buf_index_p    # Go to next element
	addq $INT_SIZE, .input_fd_p     # Go to next element
	addq $MAXLINE, .buffer_p        # Go to next element

	movq .num_chars_read_p, %rax    # Set current num chars read
	movl $0, (%rax)                 # to 0

	movq .buf_index_p, %rax         # Set current buf index
	movl $MAXLINE, (%rax)           # to MAXLINE

	movq .input_fd_p, %rax          # Set current input fd
	movl %ecx, (%rax)               # to what's in ecx

	popq %rax                       # Restore caller's rax
	ret

#-------------------------------------------------------------------------------
# Sets previous buffer set as current buffer set
#
# Returns popped fd in rcx
#
# Modifies:
#   * Registers: rcx
#-------------------------------------------------------------------------------
	.globl PopBufferSet
	.type PopBufferSet, @function

PopBufferSet:
	pushq %rax                      # Save caller's rax

	decl .buffer_set_index          # Go to previous buffer set
	cmp $0, .buffer_set_index       # Check buffer set index
	jge .decrement_pointers         # If valid, decrement pointers
	MPrint .err_buffer_set_underflow # Otherwise, print message
	pushq $ERRC_BUFFER_SET_UNDERFLOW # and exit
	call Exit                        # .

.decrement_pointers:
	movq .input_fd_p, %rax          # Dereference .input_fd_p
	xor %rcx, %rcx                  # so we can
	movl (%rax), %ecx               # write it to rcx

	subq $INT_SIZE, .num_chars_read_p  # Go to previous element
	subq $INT_SIZE, .buf_index_p    # Go to previous element
	subq $INT_SIZE, .input_fd_p     # Go to previous element
	subq $MAXLINE, .buffer_p        # Go to previous element

	popq %rax                       # Restore caller's rax
	ret



#-------------------------------------------------------------------------------
# Returns char read from the current file descriptor and puts it in (%rdi)
#
# Args:
#   * %rdi: destination for char
#
# NOTE: Characters are loaded into a buffer and returned from there. Also, all
#       indexes and buffers can be swapped in/out to allow "nested" file reads.
#-------------------------------------------------------------------------------
	.globl Getc
	.type Getc, @function

Getc:
	pushq %r11                      # Save caller's registers
	pushq %rax                      # .
	pushq %rbx                      # .
	pushq %rsi                      # .
	
	# If there are stil chars in the buffer, return the next one...
	movq .buf_index_p, %r11         # Dereference .buf_index_p
	movl (%r11), %eax               # to get index of next char in buffer to return

	movq .num_chars_read_p, %r11    # Dereference .num_chars_read_p
	cmp (%r11), %eax                # and compare it to index of next char in buffer
	jl .store_next_char             # If there are still characters to return, do so

	movq .input_fd_p, %r11          # Dereference .input_fd_p
	xor %rbx, %rbx                  # Zero out rbx and
	movl (%r11), %ebx               # put our input file descriptor into it

	movq $SYSCALL_READ, %rax        # Otherwise, we need to read more into our buffer
	MSyscall %rbx, .buffer_p, $MAXLINE

	# Reset buf_index and num_chars_read
	movq .buf_index_p, %r11         # Dereference .buf_index_p so we can...
	movl $0, (%r11)                 # ...set it to 0

	movq .num_chars_read_p, %r11    # Derefernce .num_chars_read_p so we can...
	movl %eax, (%r11)               # ...set it to the num chars we just read

	cmpl $0, (%r11)                 # If we read anything,
	jg .store_next_char             # then we can return the next char
	movb $ASCII_EOF, (%rdi)         # Otherwise, store an EOF
	jmp 0f                          # and return

.store_next_char:
	movq .buf_index_p, %r11         # Dereference .buf_index_p
	xor %rsi, %rsi                  # Clear rsi so we can...
	movl (%r11), %esi               # ...put the current buf index into rsi.
	movq .buffer_p, %rbx            # Get address of the current buffer
	movb (%rbx, %rsi, 1), %al       # Get char at buf_index
	movb %al, (%rdi)                # and then write it to our destination
	incl (%r11)                     # Advance the buf index

0:
	popq %rsi                       # Restore caller's registers
	popq %rbx                       # .
	popq %rax                       # .
	popq %r11                       # .
	ret
