#ifndef MACROS_H
#define MACROS_H


// Gets stack arg at index
#define M_get_stack_arg(value, index)   if (NULL == (value = FMC_stack_arg(state, index))) {return -1; }


#endif
