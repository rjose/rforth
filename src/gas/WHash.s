#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.tmp:
	.byte 0

#========================================
# BSS section
#========================================
	.section .bss

	

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# WHash - Scans and discards characters up to and including a NEWLINE
#
# The following registers are used throughout:
#   * rdi: Next place to put a character
#-------------------------------------------------------------------------------
	.globl WHash
	.type WHash, @function

WHash:
	pushq %rdi                      # Save caller's registers

.get_char:
	movq $.tmp, %rdi
	call Getc                       # Get next character
	cmpb $ASCII_NEWLINE, (%rdi)     # If it's a NEWLINE...
	je .done                        # ...we're done
	jmp .get_char

.done:
	popq %rdi                       # Restore caller's registers
	ret
