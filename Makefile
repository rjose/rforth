#============================================================================
# rforth Makefile
#============================================================================

#-------------------------------------------------------------------------------
# "help" is the default target
#-------------------------------------------------------------------------------
default: help




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

