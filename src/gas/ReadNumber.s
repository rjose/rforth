#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#----------------------------------------
# Globals
#----------------------------------------
	.globl RN_value, RN_status

	.equ  STATUS_OK, 1              # Number read successfully
	.equ  STATUS_LOST_PRECISION, 2  # Number read but some precision was lost
	.equ  STATUS_TOO_BIG, -1        # Number too big for fixed point representation
	.equ  STATUS_INVALID, -2        # Invalid number

RN_value:                               # Value of number read
	.quad	0

RN_status:                              # Read status (one of Status codes)
	.int STATUS_OK

#----------------------------------------
# Locals
#----------------------------------------
.is_negative:                           # Count of number of "-" in word
	.int 0

.have_decimal:                          # Count of number of "." in word
	.int 0

.num_digits_left:                       # Max num digits left in number
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
# The resulting value is stored in RN_value in a fixed point
# representation. The status of the read is stored in RN_status (see
# above for codes).
#
# The following registers are used throughout:
#    * %eax:	index of cur char in RW_tib buffer
#    * %rsi:    Address of cur char
#-------------------------------------------------------------------------------
	.globl ReadNumber
	.type ReadNumber, @function

ReadNumber:
	# Initialize variables
	movl $0, .is_negative           # Start with no "-"
	movl $0, .have_decimal          # Start with no "."
	movq $0, RN_value               # Initialize value to 0
	movl $STATUS_OK, RN_status      # Assume everything will be OK
	movl $0, %eax		        # %eax holds the index of the current char
	movq $RW_tib, %rsi	        # %rsi holds a pointer to the cur char
	movl $NUM_DIGITS, .num_digits_left  # We start with NUM_DIGITS left for our number


.loop:
	cmp RW_tib_count, %eax          # Check cur index against num chars in number
	jge .finish_up                  # If we're at the end, then finish up

	cmpb $ASCII_MINUS, (%rsi)       # If we don't have a "-"
	jne .check_for_dot              # then check for "."
	incl .is_negative               # Otherwise, increment our negative count...
	jmp .check_flags                # ...and see if number is still valid.

.check_for_dot:
	cmpb $ASCII_DOT, (%rsi)         # If we don't have a "."
	jne .check_for_digit            # see if we have a digit

	movq $NUM_FRAC_DIGITS, .num_digits_left
	                                # If we do have a ".", then we're in the decimal part
					# of the number and we now have NUM_FRAC_DIGITS left

					# NOTE: We really should check to see that .num_digits_left
					#       is bigger than NUM_FRAC_DIGITS

	incl .have_decimal              # Increment our decimal count...
	jmp .check_flags                # ...and see if the number is still valid

.check_for_digit:
	cmpb $ASCII_0, (%rsi)           # If char < 0
	jl .invalid_number              # then number is invalid
	cmpb $ASCII_9, (%rsi)           # If char > 9
	jg .invalid_number              # then number is invalid

	decl .num_digits_left           # Decrement the number of digits left
	cmpl $0, .num_digits_left       # If we still have room
	jge .add_next_digit             # then add this digit to our number

	cmpl $0, .have_decimal          # If we don't have room, and we haven't seen a "."...
	je .number_too_big              # ...then the number is too big to represent.

	movl $STATUS_LOST_PRECISION, RN_status   # Otherwise, we're just dropping precision...
	jmp .finish_up                  # ...so just finish up


	#----------------------------------------
	# Now, we can actually add a digit
	#----------------------------------------
.add_next_digit:
	movq  RN_value, %rcx            # Left shift number...
	imul $BASE, %rcx, %rdx          # ...by multiplying by our BASE

	xor %rbx, %rbx                  # Zero out rbx
	movb (%rsi), %bl                # Store byte in bl
	sub $ASCII_0, %bl               # Subtract off '0' to get digit value
	addq %rbx, %rdx                 # Add this to our current number value
	movq %rdx, RN_value
	jmp .next_char                  # Get another character
	
.check_flags:
	cmpl $1, .is_negative           # If we have more than 1 "-"
	jg .invalid_number              # then we have an invalid number

	cmpl $1, .have_decimal          # If we have more than 1 "."
	jg .invalid_number              # then we have an invalid number

.next_char:
	inc %eax                        # Increment num chars processed
	inc %rsi                        # Go to next char in tib
	jmp .loop


	#------------------------------------------------------------
	# Abnormal cases
	#------------------------------------------------------------
.number_too_big:
	movl $STATUS_TOO_BIG, RN_status # Set status
	jmp 0f	                        # and return

.invalid_number:
	movl $STATUS_INVALID, RN_status # Set status of invalid number
	jmp 0f                          # and return


	#------------------------------------------------------------
	# Normal case
	#
	# At this point, we're just wrapping up to return the value.
	# We need to negate the value if we have a minus sign. We
	# also need to scale the value to the fixed point.
	#
	# The result will be in %rdx before writing to RN_value.
	#------------------------------------------------------------
.finish_up:
	movq RN_value, %rcx             # Copy value to rcx
	cmpl $0, .is_negative           # If not negative
	je .scale_value                 # then just scale value to fixed point
	neg %rcx                        # Otherwise, negate number
	movq %rcx, %rdx                 # Load %rdx with result in case nothing else will be done

.scale_value:
	cmpl $0, .have_decimal          # If we didn't see a "."
	je .scale_whole_number          # then just scale a whole number

.scale_frac:
	cmpl $0, .num_digits_left       # If there are no digits left
	jle .return_value               # the decimal portion is correct
	imul $BASE, %rcx, %rdx          # Otherwise, keep left shifting the number
	movq %rdx, %rcx
	decl .num_digits_left
	jmp .scale_frac

.scale_whole_number:
	imul $FIXED_POINT_UNITS, %rcx, %rdx  # Convert number into units of fixed point

.return_value:
	movq %rdx, RN_value             # Store result in RN_value

0:
	ret
