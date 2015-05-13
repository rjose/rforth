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
# Exit_rt
#
# This really acts as a marker to end a colon definition. When the definition
# is being executed, this is also used to stop the execution.
#-------------------------------------------------------------------------------
	.globl Exit_rt
	.type Exit_rt, @function
Exit_rt:
	nop
	ret

#-------------------------------------------------------------------------------
# An immediate word that adds the address of Exit_rt as the next parameter
#-------------------------------------------------------------------------------
	.globl WSemicolon
	.type WSemicolon, @function

WSemicolon:
	lea Exit_rt, %rbx
	MAddParameter %rbx
0:
	ret

