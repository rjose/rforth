;;; ===============================================================================
;;; rforth.asm
;;; ===============================================================================

	SECTION .data
	%include "./src/defines.asm"

Message:	db "Howdy", 10  ; Message + newline
MessageLen:	equ $ - Message
	
	SECTION .text
	global main

main:
	nop
	mov rax, SYSCALL_WRITE  ; Instruction: WRITE
	mov rdi, STDOUT         ; Output file descriptor
	mov rsi, Message        ; Address of message
	mov rdx, MessageLen     ; Length of message
	syscall                 ; Call WRITE

	mov rax, SYSCALL_EXIT	; Instruction: EXIT
	mov rdi, 42             ; Status code
	syscall                 ; Call EXIT
	nop

	SECTION .bss
