// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe.h for the primary calling header

#include "Vpe__pch.h"
#include "Vpe__Syms.h"
#include "Vpe___024root.h"

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__act(Vpe___024root* vlSelf);
#endif  // VL_DEBUG

void Vpe___024root___eval_triggers__act(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, (((IData)(vlSelf->clk_i) 
                                      & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__clk_i__0))) 
                                     | ((IData)(vlSelf->rst_i) 
                                        & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__rst_i__0)))));
    vlSelf->__Vtrigprevexpr___TOP__clk_i__0 = vlSelf->clk_i;
    vlSelf->__Vtrigprevexpr___TOP__rst_i__0 = vlSelf->rst_i;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vpe___024root___dump_triggers__act(vlSelf);
    }
#endif
}
