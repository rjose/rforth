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
# Aborts current colon definition
#
# Forth stack:
#   * address of string to print
#
# NOTE: This is safe to call from forth code
#-------------------------------------------------------------------------------
	.globl WAbort
	.type WAbort, @function

WAbort:
	call Print
	movl $1, G_abort
	ret
