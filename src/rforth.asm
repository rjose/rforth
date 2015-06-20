;;; ===============================================================================
;;; rforth.asm
;;; ===============================================================================

;;; ====================================
;;; Data Section
;;; ====================================
	SECTION .data
	%include "./src/defines.asm"
	%include "./src/macros.asm"

Message:	db "Howdy", 10  		; Message + newline
MessageLen:	equ $ - Message

;;; nanosleep_requested and nanosleep_remaining are both timespec structs with
;;; with the following fields:
;;;    * tv_sec (quadword): num seconds
;;;    * tv_nsec (quadword): num nanoseconds
nanosleep_requested:	dq 0, 0
nanosleep_remaining:	dq 0, 0


;;; ====================================
;;; Text Section
;;; ====================================
	SECTION .text
	global main

main:
	nop

loop:
	mov qword [nanosleep_requested], 0
	mov qword [nanosleep_requested + 8], 500000000 ; Sleep for 500ms
	MSyscall SYSCALL_NANOSLEEP, nanosleep_requested, nanosleep_remaining

	MSyscall SYSCALL_WRITE, STDOUT, Message, MessageLen 	; Write message
	jmp loop

	MSyscall SYSCALL_EXIT, 42               ; Exit with status code 42

	nop


;;; ====================================
;;; BSS Section
;;; ====================================
	SECTION .bss
