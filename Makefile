#============================================================================
# rforth2 Makefile
#============================================================================

#-------------------------------------------------------------------------------
# "help" is the default target
#-------------------------------------------------------------------------------
default: help

#-------------------------------------------------------------------------------
# Prints help message
#-------------------------------------------------------------------------------
.PHONY: help
help:
	@echo
	@echo "rforth2 Make Targets"
	@echo
	@echo "PROGRAMS"
	@echo "        rforth:        Builds rforth program"
	@echo "        rforth_dbg:    Builds debuggable rforth program"
	@echo
	@echo "MISC"
	@echo "        help:          Shows this message"
	@echo "        doc:           Builds ssk documentation (npass and spec)"
	@echo "        clean-doc:     Removes generated doc files"

#=======================================
# Build Targets
#======================================
source_files = rforth
obj_files = $(foreach f, $(source_files), src/$(f).o)
dbg_obj_files = $(foreach f, $(source_files), src/$(f)_dbg.o)

#-------------------------------------------------------------------------------
# Assemble debug code
#-------------------------------------------------------------------------------
%_dbg.o:%.asm
	nasm -f elf64 -g -F dwarf -o $@ $<

#-------------------------------------------------------------------------------
# Builds debuggable rforth app
#-------------------------------------------------------------------------------
rforth_dbg: $(dbg_obj_files)
	gcc -g -o $@ $^
