#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# Putc's all the characters from a WriteNumber
#
# The following registers are used:
#   * %rcx: To count the number of characters to write
#   * %rdx: To hold the address to read from
#-------------------------------------------------------------------------------
	.type put_number, @function

put_number:
	movl WN_len, %ecx
	movq WN_start, %rdx

.loop:
	cmp $0, %ecx
	jle 0f

	MPutc (%rdx)

	# Update the indexes
	dec %ecx
	inc %rdx
	jmp .loop

0:
	ret
	

#-------------------------------------------------------------------------------
# WDotS - Prints stack from top to bottom
#
# The following registers are used throughout:
#   * %rsi:   Points to current stack element to print
#-------------------------------------------------------------------------------
	.globl WDotS
	.type WDotS, @function

WDotS:
	# Start off with a newline
	MPutc $ASCII_NEWLINE

	# If stack is empty, we're done
	movq G_psp, %rsi
	cmp $G_param_stack, %rsi
	je .done

	# Otherwise, point %rsi to the top of the stack
	subq $WORD_SIZE, %rsi

	# Check bounds (just in case)
	movq %rsi, %rax
	subq $G_param_stack, %rax
	cmp $PARAM_STACK_SIZE, %rax
	jl .print_element

	pushq $12	# TODO: Come up with a better exit
	call Exit

.print_element:
	# If we get to the end of the stack, we're done
	cmp $G_param_stack, %rsi
	jl .done

	# Otherwise, print the number (and then a newline)
	movq (%rsi), %rax
	call WriteNumber
	call put_number
	MPutc $ASCII_NEWLINE

	# Go to next element on the stack
	subq $WORD_SIZE, %rsi
	jmp .print_element

.done:
	MPutc $ASCII_MINUS
	MPutc $ASCII_MINUS
	MPutc $ASCII_NEWLINE
	call Flush
0:
	ret
