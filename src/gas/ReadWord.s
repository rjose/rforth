#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256

#-------------------------------------------------------------------------------
# Global variables
#-------------------------------------------------------------------------------
  	  .globl RW_tib_count

# Size of the last read word
RW_tib_count:
	.int	0

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	# "Text input buffer" containing last read word
	.comm RW_tib, MAXLINE

#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# ReadWord - Reads word via Getc and stores in RW_tib buffer
#
# Reads characters into start of Tib buffer.  If the word fits in RW_tib,
# the number of characters read is TibCount. Otherwise, it exits with
# a code of 1.
#-------------------------------------------------------------------------------
	.globl ReadWord
	.type ReadWord, @function

ReadWord:
	# Start at the beginning of the buffer
	movl $0, RW_tib_count
	movq $RW_tib, %rdi
	movl $0, (%rdi)		# Zero out first 4 bytes of Tib

.skip_whitespace:
	call Getc
	cmp $ASCII_SPACE, (%rdi)
	je .skip_whitespace
	cmp $ASCII_NEWLINE, (%rdi)
	je .skip_whitespace

.loop:
	# NOTE: At this point a non-space char is in the current RW_tib slot.
	incl RW_tib_count
	addq $1, %rdi		# Move destination to next byte
	cmpl $MAXLINE, RW_tib_count
	jle .get_next_char

	# Abort since buffer will overflow
	pushq $1
	call Exit

.get_next_char:
	call Getc

	# If we get a space, newline, or EOF, we're done
	cmpb $ASCII_SPACE, (%rdi)
	je .null_out_cur_byte
	cmpb $ASCII_NEWLINE, (%rdi)
	je .null_out_cur_byte
	cmpb $ASCII_EOF, (%rdi)
	je .null_out_cur_byte

	# Otherwise, loop
	jmp .loop

.null_out_cur_byte:
	movb $0, (%rdi)

0:	# Return
	ret
