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
	@echo "        clean:         Removes built files"

#=======================================
# Build Targets
#======================================
source_files = rforth FMCore ForthMachine GenericForthMachine StackWords Variable DotQuote \
               Constant If Comment Time Math Log \
               ForthServer

obj_files = $(foreach f, $(source_files), src/$(f).o)
dbg_obj_files = $(foreach f, $(source_files), src/$(f)_dbg.o)

ForthMachine.o: ForthMachine.h
ForthMachine_dbg.o: ForthMachine.h

#-------------------------------------------------------------------------------
# Compile code
#-------------------------------------------------------------------------------
%.o:%.c src/FMCore.h src/defines.h
	gcc -c -o $@ $<

#-------------------------------------------------------------------------------
# Compile debug code
#-------------------------------------------------------------------------------
%_dbg.o:%.c src/FMCore.h src/defines.h
	gcc -c -g -o $@ $<


#-------------------------------------------------------------------------------
# Builds main rforth app
#-------------------------------------------------------------------------------
rforth: $(obj_files)
	gcc -o $@ $^

#-------------------------------------------------------------------------------
# Builds debuggable rforth app
#-------------------------------------------------------------------------------
rforth_dbg: $(dbg_obj_files)
	gcc -g -o $@ $^


#-------------------------------------------------------------------------------
# Removes program files and obj files
#-------------------------------------------------------------------------------
clean:
	rm -f rforth rforth_dbg $(obj_files) $(dbg_obj_files)
