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

.name_colon:
	.ascii ":\0\0\0"
	.equ LEN_COLON, 1

.name_semicolon:
	.ascii ";\0\0\0"
	.equ LEN_SEMICOLON, 1

.name_if:
	.ascii "IF\0\0"
	.equ LEN_IF, 2

.name_then:
	.ascii "THEN"
	.equ LEN_THEN, 4

.name_else:
	.ascii "ELSE"
	.equ LEN_ELSE, 4

.name_while:
	.ascii "WHIL"
	.equ LEN_WHILE, 5

.name_repeat:
	.ascii "REPE"
	.equ LEN_REPEAT, 6

.name_dot_quote:
	.ascii ".\"\0\0"
	.equ LEN_DOT_QUOTE, 2

.name_load:
	.ascii "LOAD"
	.equ LEN_LOAD, 4

.name_interpret:
	.ascii "INTE"
	.equ LEN_INTERPRET, 9

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

	MDefineImmediateWord .name_semicolon, $LEN_SEMICOLON, WSemicolon
	MDefineWord .name_colon, $LEN_COLON, WColon

	MDefineImmediateWord .name_if, $LEN_IF, WIf
	MDefineImmediateWord .name_then, $LEN_THEN, WThen
	MDefineImmediateWord .name_else, $LEN_ELSE, WElse

	MDefineImmediateWord .name_while, $LEN_WHILE, WWhile
	MDefineImmediateWord .name_repeat, $LEN_REPEAT, WRepeat

	MDefineWord .name_dot_quote, $LEN_DOT_QUOTE, WDotQuote
	MDefineWord .name_load, $LEN_LOAD, WLoad

	MDefineWord .name_interpret, $LEN_INTERPRET, Interpret
	ret
