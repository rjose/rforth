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

	movq STACK_ARG_1(%rbp), %rbx                             # Get the current parameter index
	addq $1, %rbx                                            # The next cell holds the literal's value

	movq STACK_ARG_2(%rbp), %rcx                             # rcx has address of colon definition

	movq ENTRY_PFA(%rcx, %rbx, WORD_SIZE), %rax              # Get the literal value...
	MPush %rax                                               # ...and push it onto the forth stack

	# NOTE: We update the param index directly so it points
	#       to the next instruction in the colon definition.
	addq $2, STACK_ARG_1(%rbp)                               # Next instr is after value cell

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
	cmpb $1, ENTRY_IMMEDIATE(%rbx)
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

