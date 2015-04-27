#===============================================================================
# TEXT section
#===============================================================================
	.section .text
	.globl Exit

#-------------------------------------------------------------------------------
# exits program
#
# Args:
#   * 1: exit code
#-------------------------------------------------------------------------------
	.type Exit, @function
Exit:
	movq $60, %rax
	movq 8(%rsp), %rdi		# Exit code
	syscall
	ret
