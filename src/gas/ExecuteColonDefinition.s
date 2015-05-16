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
# Executes a colon definition
#-------------------------------------------------------------------------------
	.globl ExecuteColonDefinition
	.type ExecuteColonDefinition, @function

ExecuteColonDefinition:

	# Push first parameter index (i.e., 0) onto the program stack
	pushq $0

.execute_current_instruction:
	# The top of the stack will be the parameter index
	movq (%rsp), %rcx

.done:
	ret
