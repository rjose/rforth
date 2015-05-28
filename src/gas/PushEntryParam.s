#===============================================================================
# PushEntryParam.s
#
# This implements functions that push paramters values and addresses onto
# the forth stack.
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
# PushEntryParam1 - Pushes first parameter of an entry onto forth stack
#
# Stack Args:
#   * Arg 1: Address of dictionary entry
#-------------------------------------------------------------------------------
	.globl PushEntryParam1
	.type PushEntryParam1, @function

PushEntryParam1:
	MPrologue
	
	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .

	movq STACK_ARG_1(%rbp), %rbx    # Dictionary entry
	movq ENTRY_PFA(%rbx), %rax      # Param1 value
	MPush %rax

	popq %rbx                       # Restore caller's registers
	popq %rax                       # .

	MEpilogue
	ret

#-------------------------------------------------------------------------------
# PushEntryParam1Addr - Pushes address of first parameter of an entry onto forth stack
#
# Stack Args:
#   * Arg 1: Address of dictionary entry
#-------------------------------------------------------------------------------
	.globl PushEntryParam1Addr
	.type PushEntryParam1Addr, @function

PushEntryParam1Addr:
	MPrologue

	pushq %rbx                      # Save caller's registers

	movq STACK_ARG_1(%rbp), %rbx    # Address of word
	addq $ENTRY_PFA, %rbx           # Address of param1
	MPush %rbx                      # Push address onto stack

	popq %rbx                       # Restore caller's registers

	MEpilogue
	ret
