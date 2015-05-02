#============================================================================
# rforth Makefile
#============================================================================

#-------------------------------------------------------------------------------
# "help" is the default target
#-------------------------------------------------------------------------------
default: help


#=======================================
# Targets: PROGRAMS
#=======================================

# Variables to define obj files for normal and debug targets
functions = rforth Exit Getc ReadWord Create Tick PushParam Constant DropParam
obj_files = $(foreach f, $(functions), src/gas/$(f).o)
dbg_obj_files = $(foreach f, $(functions), src/gas/$(f)_dbg.o)

#-------------------------------------------------------------------------------
# Builds main rforth app
#-------------------------------------------------------------------------------
rforth: $(obj_files)
	ld -e main -s -o $@ $^

#-------------------------------------------------------------------------------
# Builds debuggable rforth app
#-------------------------------------------------------------------------------
rforth_dbg: $(dbg_obj_files)
	gcc -g -o $@ $^


#=======================================
# Targets: Misc
#=======================================

#-------------------------------------------------------------------------------
# Prints help message
#-------------------------------------------------------------------------------
.PHONY: help
help:
	@echo -e "\nrforth Make Targets"

	@echo -e "\nPROGRAMS"
	@echo -e "\trforth:\t\tBuilds rforth program"
	@echo -e "\trforth-dbg:\tBuilds debuggable rforth program"

	@echo -e "\nMISC"
	@echo -e "\thelp:\t\tShows this message"
	@echo -e "\tdoc:\t\tBuilds ssk documentation (npass and spec)"
	@echo -e "\tclean-doc:\tRemoves generated doc files"


#-------------------------------------------------------------------------------
# Removes program files and obj files
#-------------------------------------------------------------------------------
clean:
	rm -f rforth rforth_dbg $(obj_files) $(dbg_obj_files)

#-------------------------------------------------------------------------------
# Builds all documentation
#
# Some will be under n-pass, some will be under spec.
#-------------------------------------------------------------------------------
.PHONY: doc
doc:
	asciidoctor ./npass/index.adoc

#-------------------------------------------------------------------------------
# Removes generated doc files
#-------------------------------------------------------------------------------
.PHONY: clean-doc
clean-doc:
	rm ./n-pass/*.html


#=======================================
# Generic
#=======================================

#-------------------------------------------------------------------------------
# Assemble code
#-------------------------------------------------------------------------------
%.o:%.s
	as -o $@ $<

#-------------------------------------------------------------------------------
# Assemble debug code
#-------------------------------------------------------------------------------
%_dbg.o:%.s
	as -gstabs -o $@ $<
