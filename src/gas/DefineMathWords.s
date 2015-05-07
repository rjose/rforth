
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

	# Word names
._plus:
	.ascii "+\0\0\0"

#-------------------------------------------------------------------------------
# _plus_rt - Runtime code for "+" word
#-------------------------------------------------------------------------------
	.type _plus_rt, @function
_plus_rt:
	call DropParam
	movq psp, %rsi
	movq (%rsi), %rbx

	call DropParam
	movq psp, %rsi
	movq (%rsi), %rcx

	addq %rbx, %rcx
	# TODO: Check for overflow

	# Return value
	pushq %rcx
	call PushParam
	addq $8, %rsp		# TODO: Make this into a macro

	ret

#-------------------------------------------------------------------------------
# DefineMathWords - Defines words for math functions
#-------------------------------------------------------------------------------
	.globl DefineMathWords
	.type DefineMathWords, @function
DefineMathWords:
	#--------------------------------------------------
	# Define "+"
	#--------------------------------------------------
	MDefineWord ._plus, $1, _plus_rt

	ret
