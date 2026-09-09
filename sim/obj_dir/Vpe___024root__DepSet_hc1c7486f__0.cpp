// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe.h for the primary calling header

#include "Vpe__pch.h"
#include "Vpe___024root.h"

void Vpe___024root___eval_act(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_act\n"); );
}

VL_INLINE_OPT void Vpe___024root___nba_sequent__TOP__0(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___nba_sequent__TOP__0\n"); );
    // Body
    if (vlSelf->rst_i) {
        vlSelf->pe__DOT__y_q = 0U;
        vlSelf->pe__DOT__weight_q = 0U;
        vlSelf->pe__DOT__x_q = 0U;
    } else {
        vlSelf->pe__DOT__y_q = ((IData)(vlSelf->prevout_i) 
                                + ((IData)(vlSelf->pe__DOT__x_q) 
                                   * (IData)(vlSelf->pe__DOT__weight_q)));
        vlSelf->pe__DOT__weight_q = vlSelf->weight_i;
        vlSelf->pe__DOT__x_q = vlSelf->data_i;
    }
    vlSelf->result_o = vlSelf->pe__DOT__y_q;
    vlSelf->data_o = vlSelf->pe__DOT__x_q;
}

void Vpe___024root___eval_nba(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vpe___024root___nba_sequent__TOP__0(vlSelf);
        vlSelf->__Vm_traceActivity[1U] = 1U;
    }
}

void Vpe___024root___eval_triggers__act(Vpe___024root* vlSelf);

bool Vpe___024root___eval_phase__act(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<1> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vpe___024root___eval_triggers__act(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vpe___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vpe___024root___eval_phase__nba(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vpe___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__nba(Vpe___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vpe___024root___dump_triggers__act(Vpe___024root* vlSelf);
#endif  // VL_DEBUG

void Vpe___024root___eval(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vpe___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("pe.sv", 1, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vpe___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("pe.sv", 1, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vpe___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vpe___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vpe___024root___eval_debug_assertions(Vpe___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root___eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((vlSelf->clk_i & 0xfeU))) {
        Verilated::overWidthError("clk_i");}
    if (VL_UNLIKELY((vlSelf->rst_i & 0xfeU))) {
        Verilated::overWidthError("rst_i");}
}
#endif  // VL_DEBUG
