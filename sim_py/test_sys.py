"""
Cocotb Testbench for 2D Systolic Array (sys.sv)
Functional verification of the new Weight Loading Protocol and GEMM operations: C = A x B.
Tests the shift-register weight loading interface, internal PE registers, and systolic matrix multiplication.
"""

import cocotb
from cocotb.triggers import Timer, RisingEdge
from cocotb.clock import Clock
import numpy as np

# -----------------------------------------------------------------------------
# Bit-Packing / Unpacking Helper Functions
# -----------------------------------------------------------------------------

def pack_vector(vec):
    """
    Packs 4 8-bit elements into a 32-bit integer (row vector of A).
    Mapping: data_i[r] corresponds to bits [r*8 +: 8].
    """
    val = 0
    for r in range(4):
        val |= (int(vec[r]) & 0xFF) << (r * 8)
    return val

def pack_weight_row(row):
    """
    Packs a row of 4 8-bit weights into a 32-bit integer for the new weight_i port.
    Mapping: weight_i corresponds to bits [(c+1)*8 - 1 : c*8].
    """
    val = 0
    for c in range(4):
        val |= (int(row[c]) & 0xFF) << (c * 8)
    return val

def unpack_result(val):
    """
    Unpacks a 128-bit result_o output into a list of 4 signed 32-bit columns.
    Mapping: result_o[c] corresponds to bits [c*32 +: 32].
    """
    try:
        val_int = int(val)
    except ValueError:
        # If signal contains unknown 'x' or 'z' bits
        return [None, None, None, None]

    cols = []
    for c in range(4):
        raw = (val_int >> (c * 32)) & 0xFFFFFFFF
        if raw >= 0x80000000:
            raw -= 0x100000000
        cols.append(np.int32(raw))
    return cols

# -----------------------------------------------------------------------------
# Weight Loading & Inspection Coroutines
# -----------------------------------------------------------------------------

async def load_weights_shift(dut, B):
    """
    Drives the new Weight Loading Protocol:
    Asserts load_weight_i and streams the 4 rows of matrix B on weight_i over 4 clock cycles.
    """
    dut._log.info("[WEIGHT LOAD] Starting sequential shift-register weight load (4 cycles)...")
    dut.load_weight_i.value = 0
    dut.weight_i.value = 0
    await RisingEdge(dut.clk_i)

    for r in reversed(range(4)):
        dut.load_weight_i.value = 1
        dut.weight_i.value = pack_weight_row(B[r])
        dut._log.info(f"  Cycle {4 - r}: Loading Row {r} = {list(B[r])} (0x{pack_weight_row(B[r]):08X})")
        await RisingEdge(dut.clk_i)

    dut.load_weight_i.value = 0
    dut.weight_i.value = 0
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    dut._log.info("[WEIGHT LOAD] Weight loading protocol completed.")

def inspect_internal_weights(dut, B_expected):
    """
    White-box inspection of internal RTL registers:
    1. dut.weight_row_q (Shift-register buffer in sys.sv)
    2. dut.load_weight_q (Registered load enable)
    3. dut.gen_pe_row[r].gen_pe_col[c].u_pe.weight_q (Internal PE weight registers)
    """
    dut._log.info("[HARDWARE DIAGNOSTIC] Inspecting internal registers in DUT:")
    dut._log.info(f"  DUT load_weight_q: {dut.load_weight_q.value}")

    # Inspect weight_row_q elements
    weight_row_q_vals = []
    for i in range(4):
        try:
            elem = dut.weight_row_q[i].value
            val_str = str(elem)
            weight_row_q_vals.append(val_str)
        except Exception:
            weight_row_q_vals.append("N/A")
    dut._log.info(f"  DUT weight_row_q: {weight_row_q_vals}")

    # Inspect internal PE registers
    pe_errors = 0
    for r in range(4):
        for c in range(4):
            pe = dut.gen_pe_row[r].gen_pe_col[c].u_pe
            val_str = str(pe.weight_q.value)
            exp_val = int(B_expected[r, c])
            if 'x' in val_str.lower() or 'z' in val_str.lower():
                dut._log.warning(
                    f"  PE[{r}][{c}]: weight_q = {val_str} (UNRESOLVED) | Expected: {exp_val} "
                    f"<-- [RTL ERROR: u_pe.weight_i is unconnected in sys.sv!]"
                )
                pe_errors += 1
            else:
                try:
                    val_int = pe.weight_q.value.to_signed()
                    if val_int != exp_val:
                        dut._log.warning(f"  PE[{r}][{c}]: weight_q = {val_int} | Expected: {exp_val} <-- [MISMATCH]")
                        pe_errors += 1
                    else:
                        dut._log.info(f"  PE[{r}][{c}]: weight_q = {val_int} | Expected: {exp_val} [OK]")
                except Exception:
                    pe_errors += 1

    if pe_errors > 0:
        dut._log.error(
            f"[HARDWARE FAILURE] {pe_errors}/16 PEs failed to latch weights! "
            f"Cause: In RTL/sys.sv line 62, u_pe.weight_i is unconnected."
        )
    else:
        dut._log.info("[HARDWARE SUCCESS] All 16 PEs contain expected weights!")

    return pe_errors

# -----------------------------------------------------------------------------
# Reusable Driver / Monitor Coroutine for GEMM
# -----------------------------------------------------------------------------

async def execute_gemm(dut, A_pad, B_pad, M_dim=4, P_dim=4, test_title="GEMM Test"):
    """
    Executes GEMM test:
    1. Resets the DUT pipeline
    2. Loads weights via the new shift-register loading protocol
    3. Runs white-box hardware inspection on PE weight registers
    4. Streams matrix A and samples matrix C
    5. Validates results against the NumPy golden model
    """
    dut._log.info("=" * 64)
    dut._log.info(f"START {test_title}")
    dut._log.info(f"Effective Dimensions: ({M_dim}x{A_pad.shape[1]}) x ({B_pad.shape[0]}x{P_dim})")
    dut._log.info("=" * 64)

    # Golden Model calculation with NumPy (signed int32)
    C_expected = A_pad.astype(np.int32) @ B_pad.astype(np.int32)

    # 1. Pipeline Reset
    dut.data_i.value = 0
    dut.prevout_i.value = 0
    dut.load_weight_i.value = 0
    dut.weight_i.value = 0

    dut.rst_i.value = 1
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    dut.rst_i.value = 0
    await RisingEdge(dut.clk_i)

    # 2. Sequential Weight Loading Protocol
    await load_weights_shift(dut, B_pad)

    # 3. Hardware Diagnostic Inspection
    pe_errors = inspect_internal_weights(dut, B_pad)

    # 4. Streaming Matrix A and Synchronous Sampling of C
    C_actual = np.zeros((4, 4), dtype=object)
    has_unknowns = False

    async def stream_A():
        for i in range(4):
            dut.data_i.value = pack_vector(A_pad[i])
            await RisingEdge(dut.clk_i)
        dut.data_i.value = 0

    async def sample_C():
        nonlocal has_unknowns
        for cycle in range(13):
            await Timer(1, unit="ps")
            res_cols = unpack_result(dut.result_o.value)
            for c in range(4):
                if 4 + c <= cycle < 4 + c + 4:
                    i_idx = cycle - 4 - c
                    if res_cols[c] is None:
                        C_actual[i_idx, c] = 'X'
                        has_unknowns = True
                    else:
                        C_actual[i_idx, c] = res_cols[c]
            await RisingEdge(dut.clk_i)

    stream_task = cocotb.start_soon(stream_A())
    sample_task = cocotb.start_soon(sample_C())

    await stream_task
    await sample_task

    # 5. Result Validation
    C_exp_sub = C_expected[:M_dim, :P_dim]
    C_act_sub = C_actual[:M_dim, :P_dim]

    dut._log.info(f"Expected Matrix ({M_dim}x{P_dim}):\n{C_exp_sub}")
    dut._log.info(f"Actual Matrix ({M_dim}x{P_dim}):\n{C_act_sub}")

    if has_unknowns or pe_errors > 0:
        err_msg = (
            f"Verification FAILED in {test_title}!\n"
            f"- PE weight errors: {pe_errors}/16\n"
            f"- Output contains unknown values: {has_unknowns}\n"
            f"Root cause in RTL: In RTL/sys.sv (line 62), 'u_pe.weight_i ()' is unconnected and "
            f"shift-register connections between PEs are missing.\n"
            f"Actual Output:\n{C_act_sub}\nExpected Output:\n{C_exp_sub}"
        )
        dut._log.error(err_msg)
        assert False, err_msg

    assert np.array_equal(C_act_sub, C_exp_sub), (
        f"Calculation MISMATCH in {test_title}!\n"
        f"Actual:\n{C_act_sub}\n"
        f"Expected:\n{C_exp_sub}"
    )
    dut._log.info(f"[PASS] {test_title} passed successfully!\n")

# -----------------------------------------------------------------------------
# Test Cases
# -----------------------------------------------------------------------------

@cocotb.test()
async def test_01_weight_loading_diagnostic(dut):
    """Test 1: Specific verification of the Weight Loading shift register and PE registers"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    B = np.array([
        [10, 20, 30, 40],
        [11, 21, 31, 41],
        [12, 22, 32, 42],
        [13, 23, 33, 43]
    ], dtype=np.int8)

    dut.rst_i.value = 1
    dut.load_weight_i.value = 0
    dut.weight_i.value = 0
    dut.data_i.value = 0
    dut.prevout_i.value = 0
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    dut.rst_i.value = 0
    await RisingEdge(dut.clk_i)

    # Perform weight loading protocol
    await load_weights_shift(dut, B)

    # Hardware check
    pe_errors = inspect_internal_weights(dut, B)

    # Verify that load unit latched the last row (Row 0)
    try:
        dut._log.info(f"Verifying DUT load unit shift register (weight_row_q)...")
        for i in range(4):
            val_int = dut.weight_row_q[i].value.to_signed()
            assert val_int == B[0, i], f"weight_row_q[{i}] expected {B[0, i]}, got {val_int}"
        dut._log.info("[PASS] DUT weight_row_q successfully latched the incoming weight vector!")
    except Exception as e:
        dut._log.error(f"Failed verifying weight_row_q: {e}")

    # Check PE weights
    assert pe_errors == 0, f"Weight Loading Failed: {pe_errors}/16 PEs have incorrect weights."

@cocotb.test()
async def test_02_identity(dut):
    """Test 2: 4x4 Identity Matrix Multiplication (A * I = A)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A = np.array([
        [1,  2,  3,  4],
        [5,  6,  7,  8],
        [9,  10, 11, 12],
        [13, 14, 15, 16]
    ], dtype=np.int8)

    B = np.eye(4, dtype=np.int8)
    await execute_gemm(dut, A, B, M_dim=4, P_dim=4, test_title="TEST 2: Identity Multiplication (A * I = A)")

@cocotb.test()
async def test_03_known_values(dut):
    """Test 3: 4x4 Matrix Multiplication with Known Values"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A = np.array([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [1, 1, 1, 1],
        [2, 0, 1, 3]
    ], dtype=np.int8)

    B = np.array([
        [1, 0, 2, 1],
        [0, 1, 1, 0],
        [2, 1, 0, 1],
        [1, 0, 1, 2]
    ], dtype=np.int8)

    await execute_gemm(dut, A, B, M_dim=4, P_dim=4, test_title="TEST 3: 4x4 Matrix with Known Values")

@cocotb.test()
async def test_04_padded_2x3_by_3x4(dut):
    """Test 4: Rectangular Multiplication (2x3) x (3x4) with Zero-Padding to 4x4"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A_orig = np.array([
        [2, 3, 4],
        [1, 0, 5]
    ], dtype=np.int8)

    B_orig = np.array([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 1, 0, 2]
    ], dtype=np.int8)

    A_pad = np.zeros((4, 4), dtype=np.int8)
    B_pad = np.zeros((4, 4), dtype=np.int8)
    A_pad[:2, :3] = A_orig
    B_pad[:3, :4] = B_orig

    await execute_gemm(dut, A_pad, B_pad, M_dim=2, P_dim=4, 
                       test_title="TEST 4: Rectangular (2x3) x (3x4) with Zero-Padding")

@cocotb.test()
async def test_05_signed_random(dut):
    """Test 5: Full 4x4 Signed int8 Random Matrix Multiplications with negative numbers"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    rng = np.random.default_rng(42)

    A = rng.integers(-30, 30, size=(4, 4), dtype=np.int8)
    B = rng.integers(-30, 30, size=(4, 4), dtype=np.int8)
    await execute_gemm(dut, A, B, M_dim=4, P_dim=4, 
                       test_title="TEST 5: Signed int8 Random 4x4 with Negatives")
