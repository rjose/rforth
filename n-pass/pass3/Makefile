.PHONY: next_word
next_word:
	as -o next_word.o next_word.s
	ld -e main -s -o next_word next_word.o


.PHONY: debug
debug:
	as -gstabs -o next_word.o next_word.s
	gcc -g -o next_word next_word.o



