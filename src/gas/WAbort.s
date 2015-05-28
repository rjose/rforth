#===============================================================================
# WAbort.s
#
# This aborts the execution of a colon definition by setting a global
# G_abort flag to 1. This unwinds nested execution. The G_abort flag
# stays set until the |Reset| is called, typically in the top level
# loop running in assembly.
#
# This also prints a message describing the reason for an abort. The
# address of this string is on the forth stack.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#========================================
# TEXT section
#========================================
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
	call Print                      # Prints message on the forth stack
	movl $1, G_abort                # And set the abort flag.
	ret
