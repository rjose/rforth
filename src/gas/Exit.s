#===============================================================================
# Exit.s
#
# Defines a function to exit with a status code
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
# Exits program
#
# Stack Args:
#   * Arg 1: exit code
#
# NOTE: Not gonna worry about registers, since this is the end
#-------------------------------------------------------------------------------
	.globl Exit
	.type Exit, @function

Exit:
	MPrologue

	movq $SYSCALL_EXIT, %rax
	movq STACK_ARG_1(%rbp), %rdi
	syscall

	MEpilogue
	ret
