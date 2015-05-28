#===============================================================================
# WRepeat.s
#
# The REPEAT word is an immediate word that fills out dangling jump targets
# and creates a jump instruction back to the top of the loop.
#
# Please see: https://docs.google.com/document/d/1Tu2-x21rT4Sd8nqLZH4OOzDggb9pPFKl7Iw3dp3Q3J0
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
# Compiles a REPEAT word
#
# This updates the dangling parameter created by WHILE. It also sets up an
# unconditional jump to the TEST? instruction, which is 2 cells before the
# index of the parameter to fill out.
#
# NOTE: We're using the forth stack to push and pop indexes of parameters to
#       fill out later when we know what they should be. Other immediate words
#       should be careful about how they use the forth stack to ensure it is
#       consistent across WHILE and REPEAT.
#-------------------------------------------------------------------------------
	.globl WRepeat
	.type WRepeat, @function

WRepeat:
	MPop %rdx                       # Get index of the param to fill out

	# Add Jmp_rt instruction with a placeholder
	# This returns us to the top of the WHILE loop.
	lea Jmp_rt, %rbx                # Get a pointer to Jmp_false_rt,
	MAddParameter %rbx              # and add it as the next colon def param
	movq %rdx, %rcx                 # Copy index of param to fill out...
	subq $2, %rcx                   # ...and move 2 cells back to get to The TEST? instruction
	MAddParameter %rcx              # Add this index as the jump target

	# Now, tie up the dangling parameter index
	movq G_dp, %rax                 # G_dp is the colon def we're currently in
	movq G_param_index, %rcx        # Cur param index ties up the dangling index
	movq %rcx, ENTRY_PFA(%rax, %rdx, WORD_SIZE)
.done:
	ret

