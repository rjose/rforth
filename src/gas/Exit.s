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
# exits program
#
# Stack Args:
#   * Arg 1: exit code
#-------------------------------------------------------------------------------
	.globl Exit
	.type Exit, @function

Exit:
	movq $SYSCALL_EXIT, %rax
	movq STACK_ARG_1(%rsp), %rdi
	syscall
	ret
