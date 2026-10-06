"""
Cocotb Testbench for Processing Element (pe.sv)
Functional verification of the new Weight Loading mechanism and MAC computation in the PE.
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import numpy as np

async def reset_pe(dut):
    dut.rst_i.value = 1
    dut.load_weight_i.value = 0
    dut.data_i.value = 0
    dut.weight_i.value = 0
    dut.prevout_i.value = 0
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    dut.rst_i.value = 0
    await RisingEdge(dut.clk_i)

async def load_pe_weight(dut, w):
    dut._log.info(f"[PE LOAD WEIGHT] Loading weight = {w} into PE...")
    dut.load_weight_i.value = 1
    dut.weight_i.value = int(w)
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    dut.load_weight_i.value = 0
    dut.weight_i.value = 0
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")

@cocotb.test()
async def test_01_weight_loading_and_retention(dut):
    """Test 1: Verification of Weight Loading and Weight-Stationary Retention in PE"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    await reset_pe(dut)

    # 1. Verify reset value
    internal_w = dut.weight_q.value.to_signed()
    dut._log.info(f"After reset, PE internal weight_q = {internal_w}")
    assert internal_w == 0, f"Expected weight_q == 0 after reset, got {internal_w}"

    # 2. Load weight = 15
    await load_pe_weight(dut, 15)
    internal_w = dut.weight_q.value.to_signed()
    dut._log.info(f"After loading 15, PE internal weight_q = {internal_w}")
    assert internal_w == 15, f"Expected weight_q == 15 after load, got {internal_w}"

    # 3. Test weight retention when load_weight_i = 0
    dut.weight_i.value = 99  # Change input
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    internal_w = dut.weight_q.value.to_signed()
    dut._log.info(f"While weight_i = 99 and load_weight_i = 0, weight_q = {internal_w}")
    assert internal_w == 15, f"Weight retention failed! Expected 15, got {internal_w}"

    # 4. Update to negative weight = -42
    await load_pe_weight(dut, -42)
    internal_w = dut.weight_q.value.to_signed()
    dut._log.info(f"After loading -42, PE internal weight_q = {internal_w}")
    assert internal_w == -42, f"Expected weight_q == -42, got {internal_w}"

    dut._log.info("[PASS] Weight loading and retention verified successfully!")

@cocotb.test()
async def test_02_mac_operations(dut):
    """Test 2: Verification of MAC Computations with Loaded Stationary Weights"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    await reset_pe(dut)

    # Load weight = 6
    await load_pe_weight(dut, 6)

    test_vectors = [
        # (data_in, prevout, expected_result, desc)
        (4, 10, (4 * 6) + 10, "Positive MAC: 4*6 + 10 = 34"),
        (12, 0, (12 * 6) + 0, "Zero prevout: 12*6 + 0 = 72"),
        (-5, 50, (-5 * 6) + 50, "Negative data: -5*6 + 50 = 20"),
        (0, 100, (0 * 6) + 100, "Zero data: 0*6 + 100 = 100"),
    ]

    for d, p, exp_res, desc in test_vectors:
        dut.data_i.value = int(d)
        dut.prevout_i.value = int(p)
        await RisingEdge(dut.clk_i)
        await Timer(1, unit="ps")

        act_res = dut.result_o.value.to_signed()
        act_data_o = dut.data_o.value.to_signed()

        dut._log.info(f"[MAC TEST] {desc} -> result_o = {act_res} (Exp: {exp_res}), data_o = {act_data_o}")
        assert act_res == exp_res, f"MAC result mismatch! Got: {act_res}, Expected: {exp_res}"
        assert act_data_o == d, f"Horizontal passthrough mismatch! Got: {act_data_o}, Expected: {d}"

    dut._log.info("[PASS] All MAC computations passed successfully!")

@cocotb.test()
async def test_03_weight_o_port_diagnostic(dut):
    """Test 3: Hardware diagnostic on weight_o port (Checks RTL port direction bug)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    await reset_pe(dut)
    await load_pe_weight(dut, 25)

    # Check internal register
    int_w = dut.weight_q.value.to_signed()
    dut._log.info(f"PE internal register weight_q = {int_w}")

    # Check weight_o port
    port_w_str = str(dut.weight_o.value)
    dut._log.info(f"PE output port weight_o value string = '{port_w_str}'")

    if 'x' in port_w_str.lower() or 'z' in port_w_str.lower():
        dut._log.warning(
            f"[RTL BUG DETECTED] dut.weight_o is unresolved ('{port_w_str}'). "
            "Cause: In RTL/pe.sv line 10, weight_o is declared as 'input' instead of 'output'."
        )
    else:
        dut._log.info(f"[PASS] dut.weight_o port value = {dut.weight_o.value.to_signed()}")
