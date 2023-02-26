#pragma once

#define unw_context_t unw_context2_t
#include "../libunwind/include/libunwind.h"
#undef unw_context_t

typedef struct unw_context_t{
   struct GPRs {
    uint64_t regs[29]; // x0-x28
    uint64_t fp;    // Frame pointer x29
    uint64_t lr;    // Link register x30
    uint64_t sp;    // Stack pointer x31
    uint64_t pc;    // Program counter
    uint64_t ra_sign_state; // RA sign state register
  };

  struct GPRs uc_mcontext;
  double  _vectorHalfRegisters[32];
  // Currently only the lower double in 128-bit vectore registers
  // is perserved during unwinding.  We could define new register
  // numbers (> 96) which mean whole vector registers, then this
  // struct would need to change to contain whole vector registers.
} unw_context_t;