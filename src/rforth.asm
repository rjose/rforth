	section .data
	section .text

	global main

main:
	nop
	;; Put experiments here
	mov rax, 60		; EXIT code
	mov rdi, 42
	syscall
	nop

	section .bss
