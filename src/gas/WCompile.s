#===============================================================================
# WCompile.s
#
# During the compilation of a colon definition, this function does the
# work of getting the next word and compiling it into the next parameter
# slot of the current definition.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.err_nested_definition:
	.asciz "ERROR: Nested definitions aren't allowed"

.err_invalid_word:
	.asciz "ERROR: Trying to compile invalid word"

#-------------------------------------------------------------------------------
# Global variables
#-------------------------------------------------------------------------------
  	  .globl WC_macro_mode

# If macro_mode, this is 1. Otherwise, it is 0.
WC_macro_mode:
	.byte	0


#========================================
# BSS section
#========================================
	.section .bss


#========================================
# TEXT section
#========================================
	.section .text

#-------------------------------------------------------------------------------
# Pushes a literal value onto the forth stack
#
# Args:
#   * Stack arg 1: current parameter index
#   * Stack arg 2: address of the associated colon definition
#
# NOTE: Every "special function" *must* update the param index to point to
#       the next colon definition parameter to execute. This is done directly
#       to STACK_ARG_1(%rbp).
#
# Throughout this function:
#   * rbx holds the parameter index
#   * rcx holds the address of the colon definition
#-------------------------------------------------------------------------------
	.globl Literal_rt
	.type Literal_rt, @function

Literal_rt:
	MPrologue

	pushq %rax                      # Save caller's registers
	pushq %rbx                      # .
	pushq %rcx                      # .

	movq STACK_ARG_1(%rbp), %rbx    # Get the current parameter index
	addq $1, %rbx                   # The next cell holds the literal's value

	movq STACK_ARG_2(%rbp), %rcx    # rcx has address of colon definition

	movq ENTRY_PFA(%rcx, %rbx, WORD_SIZE), %rax  # Get the literal value...
	MPush %rax                                   # ...and push it onto the forth stack

	# NOTE: We update the param index directly so it points
	#       to the next instruction in the colon definition.
	addq $2, STACK_ARG_1(%rbp)      # Next instr is after value cell

	popq %rcx                       # Restore caller's registers
	popq %rbx                       # .
	popq %rax                       # .

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
	pushq %rbx                      # Save caller's registers
	pushq %rcx                      # .

	cmpb $1, WC_macro_mode
	je .macro_mode

	#----------------------------------------------------------------------
	# Normal Compile Mode
	#----------------------------------------------------------------------
	call Tick                       # Get address of next word
	MPop %rbx                       # and store in rbx

	cmp $0, %rbx                    # If the word address is 0,
	je .check_number                # check if we have a number

	lea WColon, %rcx                # Else make sure
	cmp %rcx, %rbx                  # the word
	jne .check_immediate_byte       # isn't a ":"
	MAbort $.err_nested_definition  # because we can't have nested definitions


.check_immediate_byte:
	cmpb $1, ENTRY_IMMEDIATE(%rbx)  # If the word is IMMEDIATE, then
	je .execute_immediately         # execute it right now

	MAddParameter %rbx              # Otherwise, add word to definition
	jmp .done                       # and return


	#----------------------------------------------------------------------
	# Check Number Mode
	#----------------------------------------------------------------------
.check_number:
	call ReadNumber                 # Try reading word as a number

	cmpb $0, RN_status              # If number, then
	jge .add_literal_rt             # use Literal_rt as the word for it
	MAbort $.err_invalid_word       # Otherwise, abort since this is invalid

.add_literal_rt:
	lea Literal_rt, %rcx            # We use Literal_rt
	MAddParameter %rcx              # in the colon definition
	movq RN_value, %rcx             # to push the number of the value
	MAddParameter %rcx              # onto the forth stack

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
	popq %rcx                       # Restore caller's registers
	popq %rbx                       # .
	ret

