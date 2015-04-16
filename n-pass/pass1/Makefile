.PHONY: cpuid
cpuid:
	as -o cpuid.o cpuid.s
	ld -s -o cpuid cpuid.o

.PHONY: cpuid_dbg
debug:
	as -gstabs -o cpuid_dbg.o cpuid.s
	gcc -g -o cpuid_dbg cpuid_dbg.o


