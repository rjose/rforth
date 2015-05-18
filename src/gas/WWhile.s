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
# Compiles a WHILE word
#
# This sets up a Jmp_false_rt instruction similar to an IF.
#
# NOTE: We're using the forth stack to push and pop indexes of parameters to
#       fill out later when we know what they should be. Other immediate words
#       should be careful about how they use the forth stack to ensure it is
#       consistent across WHILE and REPEAT.
#-------------------------------------------------------------------------------
	.globl WWhile
	.type WWhile, @function

WWhile:
	lea Jmp_false_rt, %rbx                  # Get a pointer to Jmp_false_rt,
	MAddParameter %rbx                      # and add it as the next colon def param

	MPush G_param_index                     # Note cur param index to fill out later...
	MAddParameter $0                        # ...and hold a placeholder for it
.done:
	ret

