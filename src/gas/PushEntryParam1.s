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
# PushEntryParam1 - Pushes first parameter of an entry onto forth stack
#
# Stack Args:
#   * Arg 1: Address of dictionary entry
#-------------------------------------------------------------------------------
	.globl PushEntryParam1
	.type PushEntryParam1, @function

PushEntryParam1:
	MPrologue

	movq STACK_ARG_1(%rbp), %rbx            # Dictionary entry
	movq ENTRY_PFA(%rbx), %rax              # Param1 value
	MPush %rax

	MEpilogue
	ret
