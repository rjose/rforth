	.equ BUFFER_LEN, 0x100
	.equ MAX_CUR_WORD_LEN, 27        # 28 - 1 for the \0
	.equ NEWLINE, 10
	.equ SPACE, 32

	#===============================================================================
	# DATA section
	#===============================================================================
	.section .data
	
input_length:
	.int 0

cur_word:
	.ascii "123456789012345678901234567\0"

space:
	.ascii " "



	
	#===============================================================================
	# BSS section
	#===============================================================================
	.section .bss
	
	.comm buffer, BUFFER_LEN

	
	#===============================================================================
	# TEXT section
	#===============================================================================
	.section .text
	.globl main

	#-------------------------------------------------------------------------------
	# Read line
	#
	# Reads BUFFER_LEN-1 characters from keyboard into buffer. The number of
	# charcters read is left in eax.
	#
	# NOTE: This clobbers eax, ebx, ecx.
	# NOTE: This also updates input length with the length of the input string.
	#-------------------------------------------------------------------------------
	.type read_line, @function
read_line:
	movl $3, %eax                    # read is 3
	movl $0, %ebx       		 # stdin is 0
	movl $buffer, %ecx  		 # destination
	movl $(BUFFER_LEN-1), %edx       # num chars
	int $0x80

	# Get index of last character
	subl $1, %eax                    
	movl %eax, input_length

	# If last character is a newline, replace it with a space
	movb buffer(%eax), %bl
	cmp $NEWLINE, %bl
	jne return
	movb $SPACE, %bl
	movb %bl, buffer(%eax)
return:
	ret


	#-------------------------------------------------------------------------------
	# Stores next word from |buffer| into |cur_word|
	#
	# The size of the word is returned in EAX
	#-------------------------------------------------------------------------------
	.type next_word, @function
next_word:
	leal buffer, %edi               # buffer to scan
	leal space, %esi                # Char to compare
	movl input_length, %ecx         # Max num chars to scan
	lodsb                           # Loads "space" byte into AL register
	cld                             # Clear direction flag (increment after scan)
	repe scasb                      # Scan for non-space
	je non_space_not_found

	# Compute start of word
	addl $1, %ecx
	subl input_length, %ecx
	negl %ecx                       # ECX contains index of start of word

	# Copy word
	leal buffer, %esi               # Source is |buffer|...
	addl  %ecx, %esi                # ...but offset by the index
	
	leal cur_word, %edi             # Destination is |cur_word|
	movl $MAX_CUR_WORD_LEN, %ecx    # Count down from MAX_CUR_WORD_LEN

1:	# Loop, copying characters
	cmp $SPACE, (%esi)
	je 2f                           # Return
	cmp $0, %ecx
	je 2f                           # Return

	movsb
	subl $1, %ecx
	jmp 1b                          # Loop

2:	# Fill rest of cur word with spaces
	rep stosb
	ret

non_space_not_found:
	movl $0, %eax
	ret
	


	#-------------------------------------------------------------------------------
	# main
	#-------------------------------------------------------------------------------
main:
	nop
	call read_line
	call next_word

	# Exit
	movl $1, %eax
	movl $0, %ebx
	int $0x80

