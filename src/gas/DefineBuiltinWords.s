#===============================================================================
# DATA section
#===============================================================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#-------------------------------------------------------------------------------
# Word names
#-------------------------------------------------------------------------------
.name_CONSTANT:
	.ascii "CONS"
	.equ LEN_CONSTANT, 8

.name_plus:
	.ascii "+\0\0\0"
	.equ LEN_PLUS, 1

.name_minus:
	.ascii "-\0\0\0"
	.equ LEN_MINUS, 1

.name_star:
	.ascii "*\0\0\0"
	.equ LEN_STAR, 1

.name_slash:
	.ascii "/\0\0\0"
	.equ LEN_SLASH, 1

.name_dot_s:
	.ascii ".s\0\0"
	.equ LEN_DOT_S, 2

.name_dot_q:
	.ascii ".q\0\0"
	.equ LEN_DOT_Q, 2

#===============================================================================
# TEXT section
#===============================================================================
	.section .text


#-------------------------------------------------------------------------------
# DefineBuiltinWords - Defines words for math functions
#-------------------------------------------------------------------------------
	.globl DefineBuiltinWords
	.type DefineBuiltinWords, @function

DefineBuiltinWords:
	# Define "+", "-", "*", "/"
	MDefineWord .name_plus, $LEN_PLUS, WPlus
	MDefineWord .name_minus, $LEN_MINUS, WMinus
	MDefineWord .name_star, $LEN_STAR, WStar
	MDefineWord .name_slash, $LEN_SLASH, WSlash

	MDefineWord .name_CONSTANT, $LEN_CONSTANT, WConstant

	MDefineWord .name_dot_s, $LEN_DOT_S, WDotS
	MDefineWord .name_dot_q, $LEN_DOT_Q, WDotQ

	ret
