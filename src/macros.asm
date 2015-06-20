
	%define pass nop
;; ---------------------------------------------------------------------
;; MSyscall - 2 arguments
;; ---------------------------------------------------------------------
%macro MSyscall 2
	push rax
	push rdi

	mov rax, %1
	mov rdi, %2
	syscall

	pop rdi
	pop rax
%endmacro

;; ---------------------------------------------------------------------
;; MSyscall - 3 arguments
;; ---------------------------------------------------------------------
%macro MSyscall 3
	push rax
	push rdi
	push rsi

	mov rax, %1
	mov rdi, %2
	mov rsi, %3
	syscall

	pop rsi
	pop rdi
	pop rax
%endmacro


;; ---------------------------------------------------------------------
;; MSyscall - 4 arguments
;; ---------------------------------------------------------------------
%macro MSyscall 4
	push rax
	push rdi
	push rsi
	push rdx

	mov rax, %1
	mov rdi, %2
	mov rsi, %3
	mov rdx, %4
	syscall

	pop rdx
	pop rsi
	pop rdi
	pop rax
%endmacro
	
