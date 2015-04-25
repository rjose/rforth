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
	jne 0f
	movb $SPACE, %bl
	movb %bl, buffer(%eax)

0:	# Return from readline
	ret


	#-------------------------------------------------------------------------------
	# Stores next word from |buffer| into |cur_word|
	#
	# EAX is 0 if there is no word, index of end of word in |buffer| otherwise.
	#-------------------------------------------------------------------------------
	.type next_word, @function
next_word:
	cld                             # Clear direction flag (increment after scan)
	leal buffer, %edi               # buffer to scan
	movb $SPACE, %al
	movl input_length, %ecx         # Max num chars to scan
	repe scasb                      # Scan for non-space
	movl $0, %eax                   # Indicate no word found
	je 0f

	# Compute start of word
	addl $1, %ecx                   # Advance count to get to first non-space char
	subl input_length, %ecx
	negl %ecx                       # ECX contains index of start of word

	# Copy word
	leal buffer, %esi               # Source is |buffer|...
	addl  %ecx, %esi                # ...but offset by the index
	
	leal cur_word, %edi             # Destination is |cur_word|
	movl $MAX_CUR_WORD_LEN, %ecx    # Count down from MAX_CUR_WORD_LEN

1:	# Loop, copying characters
	movb (%esi), %bl
	cmp $SPACE, %bl
	je 2f
	
	cmp $0, %ecx
	je 2f

	movsb
	subl $1, %ecx
	jmp 1b                          # Loop

2:	# Note start index of next word
	movl %esi, %edx
	subl $buffer, %edx
	
	# Fill rest of cur word with spaces
	movb $SPACE, %al
	rep stosb

	# Return start index of next word
	movl %edx, %eax

0:	# Return from next_word
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

