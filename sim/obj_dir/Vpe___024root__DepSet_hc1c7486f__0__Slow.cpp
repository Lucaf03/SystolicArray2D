// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe.h for the primary calling header

#include "Vpe__pch.h"
#include "Vpe___024root.h"

VL_ATTR_COLD void Vpe___024root___eval_static(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_static\n"); );
}

VL_ATTR_COLD void Vpe___024root___eval_initial(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_initial\n"); );
    // Body
    vlSelf->__Vtrigprevexpr___TOP__clk_i__0 = vlSelf->clk_i;
    vlSelf->__Vtrigprevexpr___TOP__rst_i__0 = vlSelf->rst_i;
}

VL_ATTR_COLD void Vpe___024root___eval_final(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__stl(Vpe___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vpe___024root___eval_phase__stl(Vpe___024root* vlSelf);

VL_ATTR_COLD void Vpe___024root___eval_settle(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vpe___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("pe.sv", 1, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vpe___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__stl(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vpe___024root___stl_sequent__TOP__0(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___stl_sequent__TOP__0\n"); );
    // Body
    vlSelf->data_o = vlSelf->pe__DOT__x_q;
    vlSelf->result_o = vlSelf->pe__DOT__y_q;
}

VL_ATTR_COLD void Vpe___024root___eval_stl(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vpe___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vpe___024root___eval_triggers__stl(Vpe___024root* vlSelf);

VL_ATTR_COLD bool Vpe___024root___eval_phase__stl(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vpe___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vpe___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__act(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge clk_i or posedge rst_i)\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__nba(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge clk_i or posedge rst_i)\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vpe___024root___ctor_var_reset(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->clk_i = VL_RAND_RESET_I(1);
    vlSelf->rst_i = VL_RAND_RESET_I(1);
    vlSelf->data_i = VL_RAND_RESET_I(8);
    vlSelf->weight_i = VL_RAND_RESET_I(8);
    vlSelf->prevout_i = VL_RAND_RESET_I(8);
    vlSelf->result_o = VL_RAND_RESET_I(32);
    vlSelf->data_o = VL_RAND_RESET_I(8);
    vlSelf->pe__DOT__weight_q = VL_RAND_RESET_I(8);
    vlSelf->pe__DOT__y_q = VL_RAND_RESET_I(32);
    vlSelf->pe__DOT__x_q = VL_RAND_RESET_I(8);
    vlSelf->__Vtrigprevexpr___TOP__clk_i__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__rst_i__0 = VL_RAND_RESET_I(1);
    for (int __Vi0 = 0; __Vi0 < 2; ++__Vi0) {
        vlSelf->__Vm_traceActivity[__Vi0] = 0;
    }
}
