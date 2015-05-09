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
       movq %rbx, ENTRY_CODE_OFFSET(%rax)
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
	addq $WORD_SIZE, %rsp		# Drop pushed value from assmebly stack
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
#---------------------------------------------------------------------------
.macro MAddParameter value, address_reg=%rdi
	movq G_pfa, \address_reg
	movq \value, (\address_reg)

	# Advance pfa
	addq $WORD_SIZE, \address_reg
	movq \address_reg, G_pfa
.endm

#---------------------------------------------------------------------------
# Moves stack pointer up num_args entries to clear stack
#---------------------------------------------------------------------------
.macro MClearStackArgs num_args
       	addq $WORD_SIZE*\num_args, %rsp
.endm
