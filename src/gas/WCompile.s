#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#-------------------------------------------------------------------------------
# Global variables
#-------------------------------------------------------------------------------
  	  .globl WC_macro_mode

# If macro_mode, this is 1. Otherwise, it is 0.
WC_macro_mode:
	.byte	0


#===============================================================================
# BSS section
#===============================================================================
	.section .bss


#===============================================================================
# TEXT section
#===============================================================================
	.section .text

#-------------------------------------------------------------------------------
# Pushes the next parameter's value onto the forth stack
#
# Args:
#   * Stack arg 1: current parameter index
#   * Stack arg 2: address of the associated colon definition
#
# NOTE: Every "special function" *must* push the next value of the
#       parameter index onto the program stack before returning. This is
#       used during the execution of the colon definition.
#
# Throughout this function:
#   * rbx holds the parameter index
#   * rcx holds the address of the colon definition
#-------------------------------------------------------------------------------
	.globl Literal_rt
	.type Literal_rt, @function

Literal_rt:
	MPrologue

	# Figure out address of the next parameter
	movq STACK_ARG_1(%rbp), %rbx
	movq STACK_ARG_2(%rbp), %rcx

	# Advance parameter index to next entry (where the literal value is) and
	# then grab the value and push it onto the forth stack.
	addq $1, %rbx
	movq ENTRY_PFA_OFFSET(%rcx, %rbx, WORD_SIZE), %rax
	MPush %rax

	# Advance parameter index to next parameter and return this
	addq $1, %rbx
	pushq %rbx
	
	MEpilogue
	ret

#-------------------------------------------------------------------------------
# Compiles the next word into the next parameter slot
#
# If WC_macro_mode is 0, then we compile words normally. If 1, then the code
# that executes can manipulate the parameters using all that rforth can do.
#-------------------------------------------------------------------------------
	.globl WCompile
	.type WCompile, @function

WCompile:
	cmpb $1, WC_macro_mode
	je .macro_mode

	#----------------------------------------------------------------------
	# Normal Compile Mode
	#
	# If we couldn't find an entry, see if we have a number.
	#----------------------------------------------------------------------
	# Get address of next word
	call Tick
	MPop %rbx

	# If it's not an entry, check if it's a number
	cmp $0, %rbx
	je .check_number

	# If it's not ":", we continue. Otherwise, abort.
	lea WColon, %rcx
	cmp %rcx, %rbx
	jne .check_immediate_byte

	# Abort
	pushq $13
	call Exit

	# If it's an immediate word, execute it now...
.check_immediate_byte:
	cmpb $1, ENTRY_IMMEDIATE_OFFSET(%rbx)
	je .execute_immediately

	# ...otherwise add the entry's address as the next parameter
	MAddParameter %rbx
	jmp .done
	

	#----------------------------------------------------------------------
	# Check Number Mode
	#
	# If we couldn't find an entry, see if we have a number.
	#----------------------------------------------------------------------
.check_number:
	call ReadNumber

	# If we have a number, add Literal_rt and the number's value. Otherwise, abort.
	cmpb $0, RN_status
	jge .add_literal_rt

	# Abort
	pushq $14
	call Exit

.add_literal_rt:
	lea Literal_rt, %rcx
	MAddParameter %rcx
	
	movq RN_value, %rcx
	MAddParameter %rcx

	jmp .done

	#----------------------------------------------------------------------
	# Macro Mode
	#
	# Here, we just execute the entry whose address is in %rbx
	#----------------------------------------------------------------------
.execute_immediately:
.macro_mode:
	MExecuteEntry %rbx

.done:
	ret

