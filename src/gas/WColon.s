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
# Creates a definition
#-------------------------------------------------------------------------------
	.globl WColon
	.type WColon, @function

WColon:
	# Create a new dictionary entry
	call Create

	# Store ExecuteColonDefinition in code pointer
	lea ExecuteColonDefinition, %rbx
	movq G_dp, %rax
	movq %rbx, ENTRY_CODE(%rax)

	# We start off in non-macro (i.e, normal) mode
	movb $0, WC_macro_mode

.loop:
	call WCompile

	# If the last parameter added was an Exit_rt, then we're done.
	movq G_pfa, %rdx
	movq -WORD_SIZE(%rdx), %rbx

	lea Exit_rt, %rcx
	cmp %rbx, %rcx
	je .done

	# Otherwise, keep going
	jmp .loop

.done:
	ret
