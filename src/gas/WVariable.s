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
# WVariable - Creates a VARIBLE entry in the dictionary.
#
# Next Word: Name of the entry
#
# A variable entry just pushes the address of its first param onto forth stack
#-------------------------------------------------------------------------------
	.globl WVariable
	.type WVariable, @function

WVariable:
	# Create new dictionary entry
	call Create

	lea PushEntryParam1Addr, %rbx   # Get address of function that pushes param1 address
	movq G_dp, %rax                 # Store this function...
	movq %rbx, ENTRY_CODE(%rax)     # ...in the entry's code cell
	MAddParameter $0                # Add parameter and set to 0
	ret

#-------------------------------------------------------------------------------
# WBang - Stores a value in a variable
#
# Forth stack:
#   * Address of variable
#   * Value to store
#-------------------------------------------------------------------------------
	.globl WBang
	.type WBang, @function

WBang:
	MPop %rbx                       # Get variable address
	MPop %rcx                       # Get variable value
	movq %rcx, (%rbx)               # Store value
	ret

#-------------------------------------------------------------------------------
# WAt - Retrieves a variable value
#
# Forth stack:
#   * Address of variable
#
# Pushes value of address onto forth stack
#-------------------------------------------------------------------------------
	.globl WAt
	.type WAt, @function

WAt:
	MPop %rbx                       # Get variable address
	movq (%rbx), %rcx               # Get value
	MPush %rcx                      # and push onto forth stack
	ret
