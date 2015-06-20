;;; ===============================================================================
;;; rforth.asm
;;; ===============================================================================

	SECTION .data
	%include "./src/defines.asm"
	%include "./src/macros.asm"

Message:	db "Howdy", 10  		; Message + newline
MessageLen:	equ $ - Message
	
	SECTION .text
	global main

main:
	nop
	MSyscall SYSCALL_WRITE, \ 		; Write message
	         STDOUT, Message, MessageLen	; .

	MSyscall SYSCALL_EXIT, 42               ; Exit with status code 42
	nop

	SECTION .bss
