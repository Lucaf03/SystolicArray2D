// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vpe.h for the primary calling header

#include "Vpe__pch.h"
#include "Vpe__Syms.h"
#include "Vpe___024root.h"

void Vpe___024root___ctor_var_reset(Vpe___024root* vlSelf);

Vpe___024root::Vpe___024root(Vpe__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vpe___024root___ctor_var_reset(this);
}

void Vpe___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
}

Vpe___024root::~Vpe___024root() {
}
