#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ  MAXLINE, 256              # Length of each buffer
	.equ  NUM_BUFFER_SETS, 16       # Number of each buffer set

.err_out_of_buffer_sets:                # Error string
	.asciz "ERROR: Ran out of buffer sets"

.err_buffer_set_underflow:              # Error string
	.asciz "ERROR: Buffer set underflow"

buffer_set_index:
.buffer_set_index:                      # Index of current buffer set
	.int  0

num_chars_read:
.num_chars_read:                        # Number of chars currently loaded into each buffer set
	.int	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

buf_index:
.buf_index:                             # Index of the next char in each buffer set to return
	.int	MAXLINE, 7, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0

#---------------------------------------
# Pointers
#---------------------------------------
num_chars_read_p:
.num_chars_read_p:                      # Pointer to num chars read for current buffer set
	.quad .num_chars_read

buf_index_p:
.buf_index_p:                           # Pointer to index of next char in current buffer set
	.quad .buf_index

buffer_p:
.buffer_p:                              # Pointer to buffer in buffer set
	.quad buffer

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	# Buffer to load chars into and read chars from
	.comm buffer, NUM_BUFFER_SETS*MAXLINE


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Sets next buffer set as current buffer set
#-------------------------------------------------------------------------------
	.globl PushBufferSet
	.type PushBufferSet, @function

PushBufferSet:
	incl .buffer_set_index          # Advance buffer set index
	cmp $NUM_BUFFER_SETS, .buffer_set_index
	jl .increment_pointers          # If index is still valid, set up new buffer set
	MPrint $.err_out_of_buffer_sets # Otherwise, print a message
	pushq $ERRC_OUT_OF_BUFFER_SETS  # and exit
	call Exit                       # .

.increment_pointers:
	addq $INT_SIZE, .num_chars_read_p  # Go to next element
	addq $INT_SIZE, .buf_index_p    # Go to next element
	addq $MAXLINE, .buffer_p        # Go to next element

	movq .num_chars_read_p, %rax    # Set current num chars read to 0
	movl $0, (%rax)

	movq .buf_index_p, %rax         # Set current buf index to MAXLINE
	movl $MAXLINE, (%rax)
	ret

#-------------------------------------------------------------------------------
# Sets previous buffer set as current buffer set
#-------------------------------------------------------------------------------
	.globl PopBufferSet
	.type PopBufferSet, @function

PopBufferSet:
	decl .buffer_set_index          # Go to previous buffer set
	cmp $0, .buffer_set_index       # Check buffer set index
	jge .decrement_pointers         # If valid, decrement pointers
	MPrint .err_buffer_set_underflow # Otherwise, print message
	pushq $ERRC_BUFFER_SET_UNDERFLOW # and exit
	call Exit                        # .

.decrement_pointers:
	subq $INT_SIZE, .num_chars_read_p  # Go to previous element
	subq $INT_SIZE, .buf_index_p    # Go to previous element
	subq $MAXLINE, .buffer_p        # Go to previous element
	ret



#-------------------------------------------------------------------------------
# Returns char read from G_input_fd and puts it in %rdi
#
# Args:
#   * %rdi: destination for char
#
# NOTE: Characters are loaded into a buffer and returned from there. Also, all
#       indexes and buffers can be swapped in/out to allow "nested" file reads.
#
# Registers:
#   * r11: Used to dereference pointers
#-------------------------------------------------------------------------------
	.globl Getc
	.type Getc, @function

Getc:
	# If there are stil chars in the buffer, return the next one...
	movq .buf_index_p, %r11         # Dereference .buf_index_p
	movl (%r11), %eax               # to get index of next char in buffer to return

	movq .num_chars_read_p, %r11    # Dereference .num_chars_read_p
	cmp (%r11), %eax                # and compare it to index of next char in buffer
	jl .store_next_char             # If there are still characters to return, do so

	movq $SYSCALL_READ, %rax        # Otherwise, we need to read more into our buffer
	MSyscall G_input_fd, .buffer_p, $MAXLINE

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
	movq .buffer_p, %rdx            # Get address of the current buffer
	movb (%rdx, %rsi, 1), %al       # Get char at buf_index
	movb %al, (%rdi)                # and then write it to our destination
	incl (%r11)                     # Advance the buf index

0:	# Return
	ret
