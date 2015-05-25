#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAX_LINE, 32		# Really only need 20 digits
	.equ	 MAX_NUM_DIGITS, 31	# Save 1 spot for a potential "-"
	.equ	 BASE, 10

.err_buffer_full:
	.asciz "ERROR: WriteNumber buffer full"

	#----------------------------------------------------------------------
	# Globals
	#
	# WN_start: pointer to start of the last number written
	# WN_len: length of last number written
	#----------------------------------------------------------------------
	.globl WN_start, WN_len
WN_start:
	.quad	0

WN_len:
	.int 0

	#----------------------------------------------------------------------
	# Locals
	#
	# .is_negative:		1 if number is negative; 0 otherwise
	#----------------------------------------------------------------------
.is_negative:
	.byte 0


#===============================================================================
# BSS section
#===============================================================================
	.section .bss

	.lcomm .buffer, MAX_LINE


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# WriteNumber - Writes a number in decimal characters
#
# The resulting string is stored in .buffer, and a pointer to the first character
# is WN_start. The length of the string is WN_len.
#
# The following registers are used throughout:
#    * %rax:	dividend
#    * %rcx:    divisor
#    * %rdx:    remainder
#    * %rdi:	destination for character
#-------------------------------------------------------------------------------
	.globl WriteNumber
	.type WriteNumber, @function

WriteNumber:
	# Initialize variables
	movb $0, .is_negative
	movb $0, WN_len

	movq $.buffer, %rdi
	addq $MAX_NUM_DIGITS, %rdi	# A little hacky, but we want MAX_LINE-1
	movq $BASE, %rcx

	# If number >= 0, write the next char; otherwise, note that number is negative first.
	cmp $0, %rax
	jge .write_char
	
	movb $1, .is_negative
	neg %rax

.write_char:
	xor %rdx, %rdx
	idiv %rcx
	addq $ASCII_0, %rdx	# Convert remainder to an ASCII digit
	movb %dl, (%rdi)

	# Advance indexes
	dec %rdi
	incb WN_len

	# If still space, check the dividend; otherwise, error.
	cmp $MAX_NUM_DIGITS, WN_len
	jl .check_dividend
	MAbort $.err_buffer_full
	jmp 0f

.check_dividend:
	cmp $0, %rax
	je .done
	jmp .write_char

.done:
	# If negative, then write out a "-"
	cmpb $0, .is_negative
	je 0f

.write_minus:
	movb $ASCII_MINUS, (%rdi)
	dec %rdi
	incb WN_len

0:
	inc %rdi		# Move start pointer back to start of string
	movq %rdi, WN_start
	ret
