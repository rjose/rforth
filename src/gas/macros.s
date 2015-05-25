
#---------------------------------------------------------------------------
# Defines a new dictionary entry
#
# Args:
#   * name: Address to first 4 bytes of word entry
#   * name_len: Total length of entry name
#   * rt_func: Runtime function that's run when word is executed
#---------------------------------------------------------------------------
.macro MDefineWord name, name_len, rt_func
       # Move 4 bytes of name to RW_tib
       movl \name, %eax
       movl %eax, RW_tib

       # Store length of name
       movl \name_len, RW_tib_count
       call CreateAfterReadWord

       # Copy address of function into code slot
       lea \rt_func, %rbx
       movq G_dp, %rax
       movq %rbx, ENTRY_CODE(%rax)
.endm

#---------------------------------------------------------------------------
# Defines a new immediate dictionary entry
#
# Args:
#   * name: Address to first 4 bytes of word entry
#   * name_len: Total length of entry name
#   * rt_func: Runtime function that's run when word is executed
#---------------------------------------------------------------------------
.macro MDefineImmediateWord name, name_len, rt_func
       MDefineWord \name, \name_len, \rt_func

       # After MDefineWord, the address of the current entry is in %rax
       movb $1, ENTRY_IMMEDIATE(%rax)
.endm

#---------------------------------------------------------------------------
# Pushes a value onto the forth stack
#
# Args:
#   * value: Value to push onto stack
#---------------------------------------------------------------------------
.macro MPush value
	pushq \value
	call PushParam
	addq $WORD_SIZE, %rsp		# Drop pushed value from program stack
.endm

#---------------------------------------------------------------------------
# Pops a value off the forth stack into a register
#
# Args:
#   * dest_reg: Destination register for value
#   * address_reg=%rsi: Register to hold address of G_psp pointer
#---------------------------------------------------------------------------
.macro MPop dest_reg, address_reg=%rsi
	call DropParam
	movq G_psp, \address_reg
	movq (\address_reg), \dest_reg
.endm


#---------------------------------------------------------------------------
# Adds a new parameter at G_pfa and advances G_pfa pointer
#
# Args:
#   * value: new parameter value
#   * address_reg=%rdi: Register to hold address of G_pfa pointer
#
# NOTE: We use a label of 777 in this macro. You need to make sure any code
#       that includes this does not also use 777 inadvertently.
#---------------------------------------------------------------------------
.macro MAddParameter value, address_reg=%rdi
	movq G_pfa, \address_reg                       # Store address of next parameter cell in reg
	movq \value, (\address_reg)                    # Write new value into this parameter cell

	addq $WORD_SIZE, \address_reg                  # Point to next parameter cell
	movq \address_reg, G_pfa                       # Update G_pfa to point to this cell
	incq G_param_index                             # Increment current param index

	subq $G_dictionary, \address_reg               # Figure out number of entries we've used
	cmp $DICT_SIZE, \address_reg                   # and compare it to our max dictionary size.
	jl 777f                                        # If it's less, then we're good

	MPush $G_err_dictionary_exceeded               # Otherwise, print an error
	call Print                                     # .
	pushq $7                                       # and exit
	call Exit                                      # .

777:
.endm

#---------------------------------------------------------------------------
# Moves stack pointer up num_args entries to clear stack
#---------------------------------------------------------------------------
.macro MClearStackArgs num_args
       	addq $WORD_SIZE*\num_args, %rsp
.endm

#---------------------------------------------------------------------------
# Executes entry whose address is in the specified register
#
# Args:
#   * reg: Register where entry's address is
#
# NOTE: This modifies reg so that it holds the pointer to the entry's code.
#---------------------------------------------------------------------------
.macro MExecuteEntry reg
	pushq \reg
	# TODO: See if we can use addressing here
	addq $ENTRY_CODE, \reg
	call *(\reg)
	MClearStackArgs 1
.endm


#---------------------------------------------------------------------------
# Puts a character
#---------------------------------------------------------------------------
.macro MPutc char
	movb \char, %al
	call Putc
.endm


#---------------------------------------------------------------------------
# Function prologue
#
# This pushes the %rbp register and stores the stack pointer in %rbp. The
# MEpilogue macro should be called at the end of the function to restore %rbp.
#
# Any function that requires stack arguments should call use this.
#---------------------------------------------------------------------------
.macro MPrologue
       pushq %rbp
       movq %rsp, %rbp
.endm

#---------------------------------------------------------------------------
# Function epilogue
#
# This restores the %rbp contents from an MPrologue and returns the stack
# to its previous state.
#---------------------------------------------------------------------------
.macro MEpilogue
       movq %rbp, %rsp
       popq %rbp
.endm

#---------------------------------------------------------------------------
# Aborts execution of colon definition
#---------------------------------------------------------------------------
.macro MAbort msg_address
	MPrint \msg_address
	movq $1, G_abort
.endm

#---------------------------------------------------------------------------
# Prints a message without the forth stack
#---------------------------------------------------------------------------
.macro MPrint msg_address
       pushq \msg_address
       call Print
       MClearStackArgs 1
.endm

#---------------------------------------------------------------------------
# Prints a message with the forth stack
#---------------------------------------------------------------------------
.macro MForthPrint msg_address
       MPush \msg_address
       call ForthPrint
.endm

#---------------------------------------------------------------------------
# Make a system call
#---------------------------------------------------------------------------
.macro MSyscall arg1=$0, arg2=$0, arg3=$0, arg4=$0, arg5=$0, arg6=$0
       pushq %rdi
       pushq %rsi
       pushq %rdx
       pushq %r10
       pushq %r8
       pushq %r9

       movq \arg1, %rdi
       movq \arg2, %rsi
       movq \arg3, %rdx
       movq \arg4, %r10
       movq \arg5, %r8
       movq \arg6, %r9
       syscall

       popq %r9
       popq %r8
       popq %r10
       popq %rdx
       popq %rsi
       popq %rdi
.endm
