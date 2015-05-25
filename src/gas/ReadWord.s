#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256           # Buffer size

.err_buffer_full:                      # Error string
	.asciz "ERROR: Read word buffer full"

#-------------------------------------------------------------------------------
# Global variables
#-------------------------------------------------------------------------------
  	  .globl RW_tib_count, RW_is_eof


RW_tib_count:                           # Size of the last word read
	.int  0

RW_is_eof:                              # 1 if at EOF
	.int  0

#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	.comm RW_tib, MAXLINE           # "Text input buffer" holding last read

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
	movl $0, RW_tib_count           # Reset num chars read
	movq $RW_tib, %rdi              # Set rdi to start of buffer for Getc
	movl $0, (%rdi)		        # Zero first 4 chars to pad short words with \0
	movl $0, RW_is_eof              # Assume we're not at the EOF

.skip_whitespace:
	call Getc                       # Get the next character from input
	cmp $ASCII_SPACE, (%rdi)        # If it's a space...
	je .skip_whitespace             # ...check for more whitespace
	cmp $ASCII_NEWLINE, (%rdi)      # If it's a newline...
	je .skip_whitespace             # ...check for more whitespace

	# NOTE: At this point, we have our first char

.loop:
	incl RW_tib_count               # Increment char count
	inc %rdi                        # Advance destination pointer
	cmpl $MAXLINE, RW_tib_count     # Check char count against buffer size
	jle .get_next_char              # If we have room, get another char

	MPrint $.err_buffer_full        # Otherwise, print message
	pushq $ERRC_WORD_BUFFER_FULL    # and exit
	call Exit                       # .

.get_next_char:
	call Getc                       # Get next char from input

	cmpb $ASCII_SPACE, (%rdi)       # If it's a space...
	je .null_out_cur_byte           # ...wrap up
	cmpb $ASCII_NEWLINE, (%rdi)     # If it's a newline...
	je .null_out_cur_byte           # ...wrap up
	cmpb $ASCII_EOF, (%rdi)         # If it's an EOF...
	je .got_eof                     # ...wrap up EOF
	jmp .loop                       # Otherwise, loop

.got_eof:
	movl $1, RW_is_eof              # Set EOF flag

.null_out_cur_byte:
	movb $0, (%rdi)

0:	# Return
	ret
