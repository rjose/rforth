#===============================================================================
# DefineBuiltinWords.s
#
# This defines all of the builtin words that the rforth interpreter can
# run without external files.
#===============================================================================

#========================================
# DATA section
#========================================
	.section .data
	.include "./src/gas/defines.s"
	.include "./src/gas/macros.s"

#-------------------------------------------------------------------------------
# Word names
#-------------------------------------------------------------------------------
.name_CONSTANT:
	.ascii "CONS"
	.equ LEN_CONSTANT, 8

.name_VARIABLE:
	.ascii "VARI"
	.equ LEN_VARIABLE, 8

.name_BANG:
	.ascii "!\0\0\0"
	.equ LEN_BANG, 1

.name_AT:
	.ascii "@\0\0\0"
	.equ LEN_AT, 1

.name_HASH:
	.ascii "#\0\0\0"
	.equ LEN_HASH, 1

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

.name_print:
	.ascii "PRIN"
	.equ LEN_PRINT, 5

.name_abort:
	.ascii "ABOR"
	.equ LEN_ABORT, 5

.name_reset:
	.ascii "RESE"
	.equ LEN_RESET, 5

.name_dup:
	.ascii "DUP\0"
	.equ LEN_DUP, 3

.name_swap:
	.ascii "SWAP"
	.equ LEN_SWAP, 4

.name_drop:
	.ascii "DROP"
	.equ LEN_DROP, 4

.name_over:
	.ascii "OVER"
	.equ LEN_OVER, 4

#========================================
# TEXT section
#========================================
	.section .text


#-------------------------------------------------------------------------------
# DefineBuiltinWords
#-------------------------------------------------------------------------------
	.globl DefineBuiltinWords
	.type DefineBuiltinWords, @function

DefineBuiltinWords:
	# Define "+", "-", "*", "/"
	MDefineWord .name_plus, $LEN_PLUS, WPlus
	MDefineWord .name_minus, $LEN_MINUS, WMinus
	MDefineWord .name_star, $LEN_STAR, WStar
	MDefineWord .name_slash, $LEN_SLASH, WSlash

	# Define "CONSTANT", "VARIABLE", "!", "@"
	MDefineWord .name_CONSTANT, $LEN_CONSTANT, WConstant
	MDefineWord .name_VARIABLE, $LEN_VARIABLE, WVariable
	MDefineWord .name_BANG, $LEN_BANG, WBang
	MDefineWord .name_AT, $LEN_AT, WAt

	# Define "#"
	MDefineWord .name_HASH, $LEN_HASH, WHash

	# Define ".s", ".q"
	MDefineWord .name_dot_s, $LEN_DOT_S, WDotS
	MDefineWord .name_dot_q, $LEN_DOT_Q, WDotQ

	# Define ":", ";"
	MDefineWord .name_colon, $LEN_COLON, WColon
	MDefineImmediateWord .name_semicolon, $LEN_SEMICOLON, WSemicolon

	# Define "IF", "ELSE", "THEN"
	MDefineImmediateWord .name_if, $LEN_IF, WIf
	MDefineImmediateWord .name_then, $LEN_THEN, WThen
	MDefineImmediateWord .name_else, $LEN_ELSE, WElse

	# Define "WHILE", "REPEAT"
	MDefineImmediateWord .name_while, $LEN_WHILE, WWhile
	MDefineImmediateWord .name_repeat, $LEN_REPEAT, WRepeat

	# Define '."', "LOAD"
	MDefineWord .name_dot_quote, $LEN_DOT_QUOTE, WDotQuote
	MDefineWord .name_load, $LEN_LOAD, WLoad

	# Define "INTERPRET"
	MDefineWord .name_interpret, $LEN_INTERPRET, Interpret

	# Define "PRINT", "ABORT", "RESET"
	MDefineWord .name_print, $LEN_PRINT, ForthPrint
	MDefineWord .name_abort, $LEN_ABORT, WAbort
	MDefineWord .name_reset, $LEN_RESET, Reset

	# Define "DUP", "SWAP", "DROP", "OVER"
	MDefineWord .name_dup, $LEN_DUP, Dup
	MDefineWord .name_swap, $LEN_SWAP, Swap
	MDefineWord .name_drop, $LEN_DROP, DropParam
	MDefineWord .name_over, $LEN_OVER, Over
	ret
