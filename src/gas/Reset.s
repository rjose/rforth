#===============================================================================
# Reset.s
#
# Resets interpreter state after an abort
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
# Resets forth stack and clear G_abort
#-------------------------------------------------------------------------------
	.globl Reset
	.type Reset, @function

Reset:
	movl $0, G_abort                # Clear the abort flag
	movq $G_param_stack, G_psp      # Clear the forth stack
	ret
