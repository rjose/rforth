#===============================================================================
# WSemicolon.s
#
# This defines a word that marks the end of a colon definition. It compiles
# and Exit_rt function into the current definition. This function doesn't
# really do anything. It acts as a marker to finish executing a
# colon definition.
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
	pushq %rbx                      # Save caller's registers
	
	lea Exit_rt, %rbx
	MAddParameter %rbx

0:
	popq %rbx                       # Restore caller's registers
	ret

