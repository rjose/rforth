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
# Executes a colon definition
#
# Args:
#   * Stack arg 1: address of the colon definition we are executing
#-------------------------------------------------------------------------------
	.globl ExecuteColonDefinition
	.type ExecuteColonDefinition, @function

ExecuteColonDefinition:
	MPrologue

	# Add stack args for special functions
	pushq STACK_ARG_1(%rbp)                                  # Push address of the colon definition
	pushq $0                                                 # Push starting param index

.loop:
	# Get current colon def parameter
	movq STACK_ARG_1(%rbp), %rbx              		 # rbx holds the colon definition's entry address
	movq (%rsp), %rcx                         		 # rcx holds current parameter index
	movq ENTRY_PFA(%rbx, %rcx, WORD_SIZE), %rdx              # rdx holds address of parameter's entry

	# Check if parameter is Exit_rt
	lea Exit_rt, %rax                                        # rax holds address of Exit_rt
	cmp %rax, %rdx                                           # If current parameter is an Exit_rt, we're done
	je .done

	# Check if parameter is Literal_rt
	lea Literal_rt, %rax                                     # If the entry points directly to Literal_rt...
	cmp %rax, %rdx
	je .execute_directly                                     # ...then execute it directly.

	# Check if parameter is Jmp_false_rt
	lea Jmp_false_rt, %rax                                   # If the entry points directly to Jmp_false_rt...
	cmp %rax, %rdx
	je .execute_directly                                     # ...then execute it directly.

	# Check if parameter is Jmp_rt
	lea Jmp_rt, %rax                                         # If the entry points directly to Jmp_rt...
	cmp %rax, %rdx
	je .execute_directly                                     # ...then execute it directly.

	MExecuteEntry %rdx                                       # Otherwise, execute rdx as a normal word

	incq (%rsp)                                              # Go to next item in colon definition
	jmp .loop

	#--------------------------------------------------
	# Special functions (literals, conditions, loops)
	# don't have dictionary entries -- their function
	# addresses appear directly in the parameter cells.
	#
	# The stack args at this point are
	#    * Arg 1: current param index
	#    * Arg 2: address of colon def being executed
	#--------------------------------------------------
.execute_directly:
	call *%rdx                                               # rdx has the address of a special function
	jmp .loop                                                # NOTE: special function will update param index


.done:
	MClearStackArgs 2                                        # Remove pushed stack args
	MEpilogue
	ret
