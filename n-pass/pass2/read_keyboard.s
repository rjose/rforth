	.equ BUFFER_LEN, 0x100
	
	#===============================================================================
	# DATA section
	#===============================================================================
	.section .data
	
input_length:
	.int 0

	#===============================================================================
	# BSS section
	#===============================================================================
	.section .bss
	
	.comm buffer, BUFFER_LEN

	#===============================================================================
	# TEXT section
	#===============================================================================
	.section .text
	.globl _start
	.globl main

main:
#_start:
	nop

	# Read characters
	movl $3, %eax
	movl $0, %ebx       # stdin is 0
	movl $buffer, %ecx  # destination
	movl $(BUFFER_LEN-1), %edx       # num chars
	int $0x80

	# Store num chars read
	movl %eax, input_length

	# Echo characters back
	movl $4, %eax
	movl $1, %ebx
	movl $buffer, %ecx
	movl input_length, %edx
	int $0x80

	# Exit
	movl $1, %eax
	movl $0, %ebx
	int $0x80
