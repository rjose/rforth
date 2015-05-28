#===============================================================================
# WColon.s
#
# Defines word to define colon definitions.
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
# Creates a definition
#-------------------------------------------------------------------------------
	.globl WColon
	.type WColon, @function

WColon:
	call Create                     # Create a dictionary entry

	lea ExecuteColonDefinition, %rbx  # Get function to execute a colon def
	movq G_dp, %rax                 # G_dp has address of most recent entry
	movq %rbx, ENTRY_CODE(%rax)     # Store the function in the entry's code slot

	movb $0, WC_macro_mode          # Clear macro mode flag (normal case)

.loop:
	call WCompile                   # Compile next word of the definition

	# Check for Exit_rt
	movq G_pfa, %rdx                # Put G_pfa in rdx
	movq -WORD_SIZE(%rdx), %rbx     # and write the most recent param to rbx.
	lea Exit_rt, %rcx               # Put the address of Exit_rt in rcx
	cmp %rbx, %rcx                  # If the most recent param is an Exit_rt then
	je .done                        # we're done with this definition.

	jmp .loop                       # Otherwise, repeat

.done:
	ret
