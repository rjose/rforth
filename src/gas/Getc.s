#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256
	.equ	 STDIN, 0


# Number of chars currently loaded into buffer
.num_chars_read:
	.int	0

# Index of the next char in the buffer to return
.buf_index:
	.int	MAXLINE

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
# Returns char read from STDIN and puts it in %rdi
#
# Args:
#   * %rdi: destination for char
#
# NOTE: Characters are loaded into |buffer| and returned from there.
#-------------------------------------------------------------------------------
	.globl Getc
	.type Getc, @function

Getc:
	# If there are stil chars in the buffer, return the next one...
	movl .buf_index, %eax
	cmp .num_chars_read, %eax
	jl .store_next_char

	# ...otherwise, we're out of chars and need to read in another line
	pushq %rdi	        # Save rdi since we're gonna need it for this call
	movq $SYSCALL_READ, %rax
	movq $STDIN, %rdi
	movq $buffer, %rsi
	movq $MAXLINE, %rdx
	syscall
	popq %rdi		# Restore rdi

	# Reset buf_index and num_chars_read
	movl $0, .buf_index
	movl %eax, .num_chars_read

	# If have input, store the next char; otherwise store an EOF
	cmp $0, .num_chars_read
	jg .store_next_char
	movb $ASCII_EOF, (%rdi)
	jmp 0f	 # Return

.store_next_char:
	movl .buf_index, %esi
	movb buffer(%esi), %al
	movb %al, (%rdi)
	incl .buf_index

0:	# Return
	ret
