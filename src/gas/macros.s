#---------------------------------------------------------------------------
# Defines a new dictionary entry
#
# Args:
#   * name: Address to first 4 bytes of word entry
#   * name_len: Total length of entry name
#   * rt_func: Runtime function that's run when word is executed
#---------------------------------------------------------------------------
.macro MDefineWord name, name_len, rt_func
       # Move 4 bytes of name to tib
       movl \name, %eax
       movl %eax, tib

       # Store length of name
       movl \name_len, tib_count
       call CreateAfterReadWord

       # Copy address of function into code slot
       lea \rt_func, %rbx
       movq dp, %rax
       movq %rbx, CODE_OFFSET(%rax)
.endm

#---------------------------------------------------------------------------
# Pops a value off the forth stack into a register
#
# Args:
#   * dest_reg: Destination register for value
#   * address_reg=%rsi: Register to hold address of psp pointer
#---------------------------------------------------------------------------
.macro MPop dest_reg, address_reg=%rsi
	call DropParam
	movq psp, \address_reg
	movq (\address_reg), \dest_reg
.endm

#---------------------------------------------------------------------------
# Moves stack pointer up num_args entries to clear stack
#---------------------------------------------------------------------------
.macro MClearStackArgs num_args
       	addq $8*\num_args, %rsp
.endm
