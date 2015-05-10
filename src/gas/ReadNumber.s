#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"


	#----------------------------------------------------------------------
	# Status codes
	#----------------------------------------------------------------------
	.equ	 STATUS_OK, 1
	.equ	 STATUS_LOST_PRECISION, 2
	.equ	 STATUS_TOO_BIG, -1
	.equ	 STATUS_INVALID, -2

	#----------------------------------------------------------------------
	# Globals
	#
	# RN_value: value of number read
	# RN_status: status of algorithm
	#   STATUS_OK:			Number was read successfully
	#   STATUS_LOST_PRECISION:	Number was read but some precision was lost
	#   STATUS_TOO_BIG:		Number was too big to fit into fixed point representation
	#   STATUS_INVALID:		Invalid number
	#----------------------------------------------------------------------
	.globl RN_value, RN_status
RN_value:
	.quad	0

RN_status:
	.int STATUS_OK

	#----------------------------------------------------------------------
	# Locals
	#
	# .is_negative:		counts the number of "-" in word (at most 2)
	# .have_decimal:	counts the number of "." in word (at most 2)
	# .num_digits_left:	Max num digits left in number. This starts as
	#                       NUM_DIGITS but then is set to NUM_FRAC_DIGITS
	#                       once we hit a ".".
	#----------------------------------------------------------------------
.is_negative:
	.int 0

.have_decimal:
	.int 0

.num_digits_left:
	.int NUM_DIGITS

#===============================================================================
# BSS section
#===============================================================================
	.section .bss


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# ReadNumber - This parses the tib buffer as a number
#
# The resulting value is stored in RN_value. The status of the read is stored
# in RN_status (see above for codes).
#
# The following registers are used throughout:
#    * %eax:	index of cur char in RW_tib buffer
#    * %rsi:    Address of cur char
#-------------------------------------------------------------------------------
	.globl ReadNumber
	.type ReadNumber, @function

ReadNumber:
	# Initialize variables
	movl $0, .is_negative
	movl $0, .have_decimal
	movq $0, RN_value
	movl $STATUS_OK, RN_status
	movl $0, %eax		# %eax holds the index of the current char
	movq $RW_tib, %rsi	# %rsi holds a pointer to the cur char
	movl $NUM_DIGITS, .num_digits_left


	#------------------------------------------------------------
	# The first part of this is looping through the characters
	# in the RW_tib buffer.
	#------------------------------------------------------------
.loop:
	# If at end of RW_tib buffer, we're done
	cmp RW_tib_count, %eax
	jge .negate_if_needed

	# Check for "-"
	cmpb $ASCII_MINUS, (%rsi)
	jne .check_for_dot

	incl .is_negative
	jmp .check_flags

.check_for_dot:
	# If char isn't a dot, check for digit...
	cmpb $ASCII_DOT, (%rsi)
	jne .check_for_digit

	# ...otherwise, only look for at most NUM_FRAC_DIGITS
	movq $NUM_FRAC_DIGITS, .num_digits_left
	incl .have_decimal
	jmp .check_flags

.check_for_digit:
	cmpb $ASCII_0, (%rsi)
	jl .invalid_number
	cmpb $ASCII_9, (%rsi)
	jg .invalid_number

	jmp .add_number

.invalid_number:
	movl $STATUS_INVALID, RN_status
	jmp 0f

.add_number:
	# If there are more digits to check, add next digit...
	decl .num_digits_left
	cmpl $0, .num_digits_left
	jge .add_next_digit

	# ...otherwise, the number may be too big...
	cmpl $0, .have_decimal
	je .number_too_big

	# ...or we're just losing precision.
	movl $STATUS_LOST_PRECISION, RN_status
	jmp .negate_if_needed

.number_too_big:
	movl $STATUS_TOO_BIG, RN_status
	jmp 0f	  # Return

.add_next_digit:
	# Left shift (base 10)
	movq  RN_value, %rcx
	imul $BASE, %rcx, %rdx

	# Add value of next digit
	xor %rbx, %rbx
	movb (%rsi), %bl
	sub $ASCII_0, %bl
	addq %rbx, %rdx
	movq %rdx, RN_value
	jmp .next_char
	
.check_flags:
	cmpl $1, .is_negative
	jg .invalid_number

	cmpl $1, .have_decimal
	jg .invalid_number

.next_char:
	# Go to next character and loop
	inc %eax
	inc %rsi
	jmp .loop


	#------------------------------------------------------------
	# At this point, we're just wrapping up to return the value.
	# We need to negate the value if we have a minus sign. We
	# also need to scale the value to the fixed point.
	#
	# The result will be in %rdx before writing to RN_value.
	#------------------------------------------------------------
.negate_if_needed:
	movq RN_value, %rcx
	cmpl $0, .is_negative
	je .scale_value
	neg %rcx
	movq %rcx, %rdx		# Load %rdx with result in case nothing else will be done

.scale_value:
	cmpl $0, .have_decimal
	je .scale_whole_number

.scale_frac:
	cmpl $0, .num_digits_left
	jle .return_value
	imul $BASE, %rcx, %rdx
	movq %rdx, %rcx
	decl .num_digits_left
	jmp .scale_frac

.scale_whole_number:
	imul $FIXED_POINT_UNITS, %rcx, %rdx

.return_value:
	movq %rdx, RN_value

0:	# Return
	ret
