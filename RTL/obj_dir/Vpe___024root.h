// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vpe.h for the primary calling header

#ifndef VERILATED_VPE___024ROOT_H_
#define VERILATED_VPE___024ROOT_H_  // guard

#include "verilated.h"


class Vpe__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vpe___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk_i,0,0);
    VL_IN8(rst_i,0,0);
    VL_IN8(data_i,7,0);
    VL_IN8(weight_i,7,0);
    VL_IN8(prevout_i,7,0);
    VL_OUT8(data_o,7,0);
    CData/*7:0*/ pe__DOT__weight_q;
    CData/*7:0*/ pe__DOT__x_q;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk_i__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst_i__0;
    CData/*0:0*/ __VactContinue;
    VL_OUT(result_o,31,0);
    IData/*31:0*/ pe__DOT__y_q;
    IData/*31:0*/ __VactIterCount;
    VlUnpacked<CData/*0:0*/, 2> __Vm_traceActivity;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<1> __VactTriggered;
    VlTriggerVec<1> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vpe__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vpe___024root(Vpe__Syms* symsp, const char* v__name);
    ~Vpe___024root();
    VL_UNCOPYABLE(Vpe___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
