#===============================================================================
# WriteNumber.s
#
# This is used to format a number in a decimal representation. Currently,
# the numbers are rendered literally so no attempt is made to format the
# fixed point representation.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAX_LINE, 32		# Really only need 20 digits
	.equ	 MAX_NUM_DIGITS, 31	# Save 1 spot for a potential "-"
	.equ	 BASE, 10

.err_buffer_full:
	.asciz "ERROR: WriteNumber buffer full"

	#--------------------------------
	# Globals
	#--------------------------------
	.globl WN_start, WN_len
WN_start:                               # pointer to start of the last number written
	.quad	0

WN_len:                                 # length of last number written
	.int 0

	#--------------------------------
	# Locals
	#--------------------------------
.is_negative:                           # 1 if number is negative; 0 otherwise
	.byte 0


#========================================
# BSS section
#========================================
	.section .bss

	.lcomm .buffer, MAX_LINE        # Buffer to write digits into


#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# WriteNumber - Writes a number in decimal characters
#
# Register args:
#   * rax: number to format
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
	pushq %rax                      # Save caller's registers
	pushq %rcx                      # .
	pushq %rdx                      # .
	pushq %rdi                      # .
	
	movb $0, .is_negative           # Initialize .is_negative to 0
	movb $0, WN_len                 # Initialize WN_len to 0

	movq $.buffer, %rdi             # Put address of .buffer in rdi
	addq $MAX_NUM_DIGITS, %rdi	# Advance pointer to rightmost slot
	movq $BASE, %rcx                # Put BASE in rcx

	cmp $0, %rax                    # If number
	jge .write_char                 # is >= 0, then start writing.

	movb $1, .is_negative           # Otherwise, note it being negative and
	neg %rax                        # negate so we have a postive number.

.write_char:
	xor %rdx, %rdx                  # Zero out rdx
	idiv %rcx                       # Right shift using BASE
	addq $ASCII_0, %rdx	        # Convert remainder to an ASCII digit and
	movb %dl, (%rdi)                # write to buffer

	dec %rdi                        # Move one position to left in buffer
	incb WN_len                     # Increment the char count

	cmp $MAX_NUM_DIGITS, WN_len     # If num chars is
	jl .check_dividend              # less than max digits, check dividend.
	MAbort $.err_buffer_full        # Otherwise, abort
	jmp 0f                          # and return

.check_dividend:
	cmp $0, %rax                    # If the dividend is zero then
	je .check_minus                 # we're done.
	jmp .write_char                 # Otherwise, write next char

.check_minus:
	cmpb $0, .is_negative           # If the number wasn't negative
	je 0f                           # then, we're done

	movb $ASCII_MINUS, (%rdi)       # Otherwise, write a "-" char out
	dec %rdi                        # and update the pointers
	incb WN_len                     # .

0:
	inc %rdi		        # Move start pointer back to start of string
	movq %rdi, WN_start             # and store in WN_start

	popq %rdi                       # Restore caller's registers
	popq %rdx                       # .
	popq %rcx                       # .
	popq %rax                       # .

	ret
