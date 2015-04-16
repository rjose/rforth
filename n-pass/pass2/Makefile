.PHONY: read_keyboard
read_keyboard:
	as -o read_keyboard.o read_keyboard.s
	ld -e main -s -o read_keyboard read_keyboard.o


.PHONY: debug
debug:
	as -gstabs -o read_keyboard.o read_keyboard.s
	gcc -g -o read_keyboard read_keyboard.o



