#===============================================================================
# DATA section
#===============================================================================
	.section .data

	.equ	 MAXLINE, 256
	.equ	 READ, 0
	.equ	 STDIN, 0
	.equ	 EOF, 0

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
	.globl getc

#-------------------------------------------------------------------------------
# getc - Returns char read from STDIN and puts it in %rdi
#
# Args:
#   * %rdi: destination for char
#
# NOTE: Characters are loaded into |buffer| and returned from there.
#-------------------------------------------------------------------------------
	.globl getc
	.type getc, @function
getc:
	# If there are stil chars in the buffer, return the next one
	movl .buf_index, %eax
	cmp .num_chars_read, %eax
	jl 1f	# Next char

	# Otherwise, we need to read in another line
	pushq %rdi   # Save rdi since we're gonna stomp on it
	movq $READ, %rax
	movq $STDIN, %rdi
	movq $buffer, %rsi
	movq $MAXLINE, %rdx
	syscall

	movl $0, .buf_index
	movl %eax, .num_chars_read
	popq %rdi   # Restore rdi

	# If have input, return the next char
	cmp $0, .num_chars_read
	jg 1f	# Next char

	# If no input, return EOF
	movb $0, (%rdi)
	jmp 0f	 # Return

1:	# Next char
	movl .buf_index, %esi
	movb buffer(%esi), %al
	movb %al, (%rdi)
	incl .buf_index

0:	# Return
	ret
