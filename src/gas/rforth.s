#===============================================================================
# rforth.s
#
# This is the main entry point for rforth. This defines our builtin words,
# loads a "main.fth" file, and runs the last entry defined in it.
#
# This entry is run in a loop that resets the interpreter state if
# execution is aborted. Typically though, this main entry is itself a
# loop that returns on an abort or an exit.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

.main_fth:                              # Filename to LOAD when we start
	.asciz "main.fth"


.run_word:                              # Address of word to run (last word in main.fth)
	.quad 0

#========================================
# BSS section
#========================================
	.section .bss

#========================================
# TEXT section
#========================================
	.section .text
	.globl main

#-------------------------------------------------------------------------------
# main
#-------------------------------------------------------------------------------
main:
	call DefineBuiltinWords         # Define builtin rforth words

	MPush $.main_fth                # ." main.fth" LOAD
	call WLoad

	movq G_dp, %rbx                 # Store last entry of main.fth as our run word
	movq %rbx, .run_word            # . 

	#----------------------------------------------------------------------
	# The run word in main.fth should be a loop that runs whatever the
	# rforth application is. We have a containing loop here that resets
	# the forth interpreter and re-executes the run loop in case one of
	# the instructions ran into an abort.
	#----------------------------------------------------------------------
.loop:
	call Reset                      # Reset the forth interpreter state
	pushq .run_word                 # Execute run word
	call ExecuteColonDefinition     # .
	MClearStackArgs 1               # .
	jmp .loop                       # Repeat

done:
	pushq 	$0                      # Normal exit code is 0
	call Exit
