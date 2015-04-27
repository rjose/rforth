#===============================================================================
# DATA section
#
# |tib_count| is a global variable with the size of the current word
#===============================================================================
	.section .data

	.equ	 MAXLINE, 256

	# Chars to look for
	.equ     NEWLINE, 10
	.equ	 EOF, 0
	.equ     SPACE, 32

# Current word size
  	  .globl tib_count
tib_count:
	.int	0

#===============================================================================
# BSS section
#
# |tib| is a global buffer containing the current word
#===============================================================================
	.section .bss

	# Text input buffer
	.comm tib, MAXLINE


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# read_word - Reads word via Getc and stores in tib buffer
#
#
# Reads characters into start of tib buffer.  If the word fits in tib,
# the number of characters read is tib_count. Otherwise, it exits with
# a code of 1.
#
#-------------------------------------------------------------------------------
	.globl read_word
	.type read_word, @function
read_word:
	# Start at the beginning of the buffer
	movl $0, tib_count
	movq $tib, %rdi
	movl $0, (%rdi)		# Zero out first 4 bytes of tib

1:	# Skip spaces and newlines
	call Getc
	cmp $SPACE, (%rdi)
	je 1b
	cmp $NEWLINE, (%rdi)
	je 1b

2:	# Get next char
	# NOTE: At this point a non-space char has just been read into the
	#       current tib slot.
	incl tib_count
	addq $1, %rdi		# Move destination to next byte
	cmpl $MAXLINE, tib_count
	jle 3f			# Continue getting char

	# Abort since buffer will overflow
	pushq $1
	call Exit

3:	# Continue getting char
	call Getc

	# If we get a space, newline, or EOF, we're done
	cmp $SPACE, (%rdi)
	je 0f
	cmp $NEWLINE, (%rdi)
	je 0f
	cmp $EOF, (%rdi)
	je 0f

	# Otherwise, loop
	jmp 2b			# Get next char

0:	# Return
	ret
