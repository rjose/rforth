#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256

# Number of chars currently loaded into buffer
.num_chars_read:
	.int	0

# Index of the next char in the buffer to return
.buf_index:
	.int	MAXLINE

#---------------------------------------
# Pointers
#---------------------------------------
.num_chars_read_p:
	.quad .num_chars_read

.buf_index_p:
	.quad .buf_index

.buffer_p:
	.quad buffer

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	# Buffer to load chars into and read chars from
	.lcomm buffer, MAXLINE


#===============================================================================
# TEXT section
#===============================================================================
	.section .text
	.globl Getc

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

	cmpl $0, (%r11)                 # If we read anything
	jg .store_next_char             # then we can return the next char
	movb $ASCII_EOF, (%rdi)         # Otherwise, store an EOF
	jmp 0f                          # and return

.store_next_char:
	movq .buf_index_p, %r11         # Dereference .buf_index_p
	movl (%r11), %esi               # and put the current index into esi.
	movb buffer(%esi), %al          # Store that char in al
	movb %al, (%rdi)                # and then write it to our destination
	incl (%r11)                     # Advance our buf index

0:	# Return
	ret
