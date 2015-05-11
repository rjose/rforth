#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256
	.equ	 STDOUT, 1

# Index of the next open slot in tob
.buf_index:
	.quad	0

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	# "text output buffer" to hold characters buffer flushing them out
	.lcomm tob, MAXLINE


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Flushes tob
#-------------------------------------------------------------------------------
	.globl Flush
	.type Flush, @function

Flush:
	movq $SYSCALL_WRITE, %rax
	MSyscall $STDOUT, $tob, .buf_index

	# Reset the index
	movq $0, .buf_index
	ret


#-------------------------------------------------------------------------------
# Writes char to output buffer
#
# Args:
#   * %al: char to write
#-------------------------------------------------------------------------------
	.globl Putc
	.type Putc, @function

Putc:
	# If |tob| has space, add char to buffer
	movq .buf_index, %rbx
	cmp $MAXLINE, %rbx
	jl .add_char_to_tob

	# Otherwise, flush first.
	call Flush

.add_char_to_tob:
	movq .buf_index, %rdi
	movb %al, tob(%rdi)
	incq .buf_index

0:
	ret
