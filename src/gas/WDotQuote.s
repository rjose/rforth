#===============================================================================
# OVERVIEW
#
# There are a fixed number of short strings in rforth. Whenever a new short
# string is created, it goes into the next string slot indexed by |.cur_string|.
#
# Every time WDotQuote is called, a new string is written to the current
# string slot. This wraps back to 0 when the maximum number of strings is
# reached. That means that short strings are temporary in nature and shouldn't
# be used to hold long term data.
#
# After a string is created, its address is pushed onto the forth stack.
#===============================================================================

#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.cur_string:                            # Index of the current string
	.int 0
.num_chars_scanned:
	.int 0


#========================================
# BSS section
#========================================
	.section .bss

	

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# WDotQuote - Scans a string up to a " char or some max num chars
#
# NOTE: We assume cur_string is always valid
#
# The following registers are used throughout:
#   * rdi: Next place to put a character
#   * rbx: Start of cur string
#-------------------------------------------------------------------------------
	.globl WDotQuote
	.type WDotQuote, @function

WDotQuote:
	movl $0, .num_chars_scanned     # Reset number of characters scanned
	
	movq .cur_string, %rcx          # Use current string index...
	imul $SHORT_STR_LEN, %rcx, %rdx # to figure out the cur string's offset.
	movq $G_short_strings, %rdi     # Get start of short strings...
	addq %rdx, %rdi                 # and add offset to get start of cur string.
	movq %rdi, %rbx                 # Store start of cur string in rbx for later

.get_char:
	call Getc                       # Get next character
	cmp $ASCII_DQUOTE, (%rdi)       # If it's a double quote...
	je .done                        # ...we're done

	incl .num_chars_scanned         # Increment the char scanned count
	inc %rdi                        # Increment the destination for the next char
	cmpl $MAX_SHORT_STRINGS, .num_chars_scanned
	jl .get_char                    # If we have space in the string, get another char

	pushq $16                       # Otherwise, we've run out of room, so abort
	call Exit

.done:
	movb $0, (%rdi)                 # Null out the last char
	MPush %rbx                      # Push address of string onto forth stack

	incl .cur_string                # Go to the next string slot
	cmpl $MAX_SHORT_STRINGS, .cur_string
	jl 0f                           # If not at the last string, just return

	movl $0, .cur_string            # Otherwise, wrap the cur string back to 0
0:
	ret
