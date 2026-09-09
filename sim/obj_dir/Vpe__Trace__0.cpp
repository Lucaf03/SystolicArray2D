// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Tracing implementation internals
#include "verilated_vcd_c.h"
#include "Vpe__Syms.h"


void Vpe___024root__trace_chg_0_sub_0(Vpe___024root* vlSelf, VerilatedVcd::Buffer* bufp);

void Vpe___024root__trace_chg_0(void* voidSelf, VerilatedVcd::Buffer* bufp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root__trace_chg_0\n"); );
    // Init
    Vpe___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vpe___024root*>(voidSelf);
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    if (VL_UNLIKELY(!vlSymsp->__Vm_activity)) return;
    // Body
    Vpe___024root__trace_chg_0_sub_0((&vlSymsp->TOP), bufp);
}

void Vpe___024root__trace_chg_0_sub_0(Vpe___024root* vlSelf, VerilatedVcd::Buffer* bufp) {
    if (false && vlSelf) {}  // Prevent unused
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root__trace_chg_0_sub_0\n"); );
    // Init
    uint32_t* const oldp VL_ATTR_UNUSED = bufp->oldp(vlSymsp->__Vm_baseCode + 1);
    // Body
    if (VL_UNLIKELY(vlSelf->__Vm_traceActivity[1U])) {
        bufp->chgCData(oldp+0,(vlSelf->pe__DOT__weight_q),8);
        bufp->chgIData(oldp+1,(vlSelf->pe__DOT__y_q),32);
        bufp->chgCData(oldp+2,(vlSelf->pe__DOT__x_q),8);
    }
    bufp->chgBit(oldp+3,(vlSelf->clk_i));
    bufp->chgBit(oldp+4,(vlSelf->rst_i));
    bufp->chgCData(oldp+5,(vlSelf->data_i),8);
    bufp->chgCData(oldp+6,(vlSelf->weight_i),8);
    bufp->chgCData(oldp+7,(vlSelf->prevout_i),8);
    bufp->chgIData(oldp+8,(vlSelf->result_o),32);
    bufp->chgCData(oldp+9,(vlSelf->data_o),8);
    bufp->chgIData(oldp+10,(((IData)(vlSelf->prevout_i) 
                             + ((IData)(vlSelf->pe__DOT__x_q) 
                                * (IData)(vlSelf->pe__DOT__weight_q)))),32);
}

void Vpe___024root__trace_cleanup(void* voidSelf, VerilatedVcd* /*unused*/) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vpe___024root__trace_cleanup\n"); );
    // Init
    Vpe___024root* const __restrict vlSelf VL_ATTR_UNUSED = static_cast<Vpe___024root*>(voidSelf);
    Vpe__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    // Body
    vlSymsp->__Vm_activity = false;
    vlSymsp->TOP.__Vm_traceActivity[0U] = 0U;
    vlSymsp->TOP.__Vm_traceActivity[1U] = 0U;
}
