#===============================================================================
# Putc.s
#
# This defines buffered writes to STDOUT.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

	.equ	 MAXLINE, 256           # Buffer size
	.equ	 STDOUT, 1

# Index of the next open slot in tob
.buf_index:
	.quad	0

#========================================
# BSS section
#========================================
	.section .bss

	.lcomm tob, MAXLINE             # "text output buffer"


#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# Flushes tob
#-------------------------------------------------------------------------------
	.globl Flush
	.type Flush, @function

Flush:
	pushq %rax                      # Save caller's registers
	
	movq $SYSCALL_WRITE, %rax       # Write our buffer to STDOUT
	MSyscall $STDOUT, $tob, .buf_index

	movq $0, .buf_index             # Reset our buffer index

	popq %rax                       # Restore caller's registers
	ret


#-------------------------------------------------------------------------------
# Writes char to output buffer
#
# Register args:
#   * %al: char to write
#-------------------------------------------------------------------------------
	.globl Putc
	.type Putc, @function

Putc:
	pushq %rdi                      # Save caller's registers

	movq .buf_index, %rdi           # Put buf index into rdi
	cmp $MAXLINE, %rdi              # and compare it to MAXLINE
	jl .add_char_to_tob             # if there's room, add a char to the buffer.
	call Flush                      # Otherwise, flush the buffer first.

.add_char_to_tob:
	movb %al, tob(%rdi)             # Put char into next buffer slot
	incq .buf_index                 # and advance buf index

0:
	popq %rdi                       # Restore caller's registers
	ret
