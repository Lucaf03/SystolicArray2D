"""
Cocotb Testbench for 2D Systolic Array (sys.sv)
Functional verification of GEMM (General Matrix Multiply) operations: C = A x B.
Includes 4x4 matrix tests, reduced matrices with zero-padding, and randomized stimuli.
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

def pack_matrix(mat):
    """
    Packs a 4x4 8-bit matrix into a 128-bit integer (weight matrix B).
    Mapping: weight_i[r][c] corresponds to bits [(r*4 + c)*8 +: 8].
    """
    val = 0
    for r in range(4):
        for c in range(4):
            shift = (r * 4 + c) * 8
            val |= (int(mat[r, c]) & 0xFF) << shift
    return val

def unpack_result(val):
    """
    Unpacks a 128-bit result_o output into a list of 4 32-bit columns.
    Mapping: result_o[c] corresponds to bits [c*32 +: 32].
    """
    val_int = int(val)
    return [(val_int >> (c * 32)) & 0xFFFFFFFF for c in range(4)]

# -----------------------------------------------------------------------------
# Reusable Driver / Monitor Coroutine
# -----------------------------------------------------------------------------

async def execute_gemm(dut, A_pad, B_pad, M_dim=4, P_dim=4, test_title="GEMM Test"):
    """
    Drives systolic array inputs, samples outputs with synchronous wavefront timing,
    and verifies the result against the NumPy golden reference model.
    """
    dut._log.info("=" * 64)
    dut._log.info(f"START {test_title}")
    dut._log.info(f"Effective Dimensions: ({M_dim}x{A_pad.shape[1]}) x ({B_pad.shape[0]}x{P_dim})")
    dut._log.info("=" * 64)

    # Golden Model calculation with NumPy
    C_expected = A_pad.astype(np.uint32) @ B_pad.astype(np.uint32)

    # 1. Weight Loading and Synchronous Reset
    dut.data_i.value = 0
    dut.prevout_i.value = 0
    dut.weight_i.value = pack_matrix(B_pad)

    dut.rst_i.value = 1
    await RisingEdge(dut.clk_i)
    await RisingEdge(dut.clk_i)
    await Timer(1, unit="ps")
    dut.rst_i.value = 0
    await RisingEdge(dut.clk_i) # 1 clock cycle to allow weight_q to latch weights

    # 2. Streaming Matrix A and Synchronous Sampling of C
    C_actual = np.zeros((4, 4), dtype=np.uint32)

    async def stream_A():
        for i in range(4):
            dut.data_i.value = pack_vector(A_pad[i])
            await RisingEdge(dut.clk_i)
        dut.data_i.value = 0

    async def sample_C():
        for cycle in range(13):
            await Timer(1, unit="ps")
            res_cols = unpack_result(dut.result_o.value)
            for c in range(4):
                if 4 + c <= cycle < 4 + c + 4:
                    i_idx = cycle - 4 - c
                    C_actual[i_idx, c] = res_cols[c]
            await RisingEdge(dut.clk_i)

    stream_task = cocotb.start_soon(stream_A())
    sample_task = cocotb.start_soon(sample_C())

    await stream_task
    await sample_task

    # 3. Result Validation
    C_exp_sub = C_expected[:M_dim, :P_dim]
    C_act_sub = C_actual[:M_dim, :P_dim]

    dut._log.info(f"Expected Matrix ({M_dim}x{P_dim}):\n{C_exp_sub}")
    dut._log.info(f"Actual Matrix ({M_dim}x{P_dim}):\n{C_act_sub}")

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
async def test_01_identity(dut):
    """Test 1: 4x4 Identity Matrix Multiplication (A * I = A)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A = np.array([
        [1,  2,  3,  4],
        [5,  6,  7,  8],
        [9,  10, 11, 12],
        [13, 14, 15, 16]
    ], dtype=np.uint8)

    B = np.eye(4, dtype=np.uint8)
    await execute_gemm(dut, A, B, M_dim=4, P_dim=4, test_title="TEST 1: Identity Multiplication (A * I = A)")

@cocotb.test()
async def test_02_known_values(dut):
    """Test 2: 4x4 Matrix Multiplication with Known Values"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A = np.array([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [1, 1, 1, 1],
        [2, 0, 1, 3]
    ], dtype=np.uint8)

    B = np.array([
        [1, 0, 2, 1],
        [0, 1, 1, 0],
        [2, 1, 0, 1],
        [1, 0, 1, 2]
    ], dtype=np.uint8)

    await execute_gemm(dut, A, B, M_dim=4, P_dim=4, test_title="TEST 2: 4x4 Matrix with Known Values")

@cocotb.test()
async def test_03_padded_2x3_by_3x4(dut):
    """Test 3: Rectangular Multiplication (2x3) x (3x4) with Zero-Padding to 4x4"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A_orig = np.array([
        [2, 3, 4],
        [1, 0, 5]
    ], dtype=np.uint8)

    B_orig = np.array([
        [1, 2, 3, 4],
        [5, 6, 7, 8],
        [9, 1, 0, 2]
    ], dtype=np.uint8)

    # Pad matrices to 4x4
    A_pad = np.zeros((4, 4), dtype=np.uint8)
    B_pad = np.zeros((4, 4), dtype=np.uint8)
    A_pad[:2, :3] = A_orig
    B_pad[:3, :4] = B_orig

    await execute_gemm(dut, A_pad, B_pad, M_dim=2, P_dim=4, 
                       test_title="TEST 3: Rectangular (2x3) x (3x4) with Zero-Padding")

@cocotb.test()
async def test_04_padded_2x2_by_2x2(dut):
    """Test 4: Reduced Square Multiplication (2x2) x (2x2) with Zero-Padding to 4x4"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A_orig = np.array([
        [7, 3],
        [2, 5]
    ], dtype=np.uint8)

    B_orig = np.array([
        [4, 1],
        [6, 8]
    ], dtype=np.uint8)

    A_pad = np.zeros((4, 4), dtype=np.uint8)
    B_pad = np.zeros((4, 4), dtype=np.uint8)
    A_pad[:2, :2] = A_orig
    B_pad[:2, :2] = B_orig

    await execute_gemm(dut, A_pad, B_pad, M_dim=2, P_dim=2, 
                       test_title="TEST 4: Reduced Square (2x2) x (2x2) with Zero-Padding")

@cocotb.test()
async def test_05_padded_3x2_by_2x4(dut):
    """Test 5: Rectangular Multiplication (3x2) x (2x4) with Zero-Padding to 4x4"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())

    A_orig = np.array([
        [3, 1],
        [4, 2],
        [5, 3]
    ], dtype=np.uint8)

    B_orig = np.array([
        [2, 4, 1, 3],
        [1, 0, 5, 2]
    ], dtype=np.uint8)

    A_pad = np.zeros((4, 4), dtype=np.uint8)
    B_pad = np.zeros((4, 4), dtype=np.uint8)
    A_pad[:3, :2] = A_orig
    B_pad[:2, :4] = B_orig

    await execute_gemm(dut, A_pad, B_pad, M_dim=3, P_dim=4, 
                       test_title="TEST 5: Rectangular (3x2) x (2x4) with Zero-Padding")

@cocotb.test()
async def test_06_random_full_4x4(dut):
    """Test 6: Full 4x4 Random Matrix Multiplications with values up to 100 (5 iterations)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    rng = np.random.default_rng(42)

    for iteration in range(1, 6):
        A = rng.integers(0, 100, size=(4, 4), dtype=np.uint8)
        B = rng.integers(0, 100, size=(4, 4), dtype=np.uint8)
        await execute_gemm(dut, A, B, M_dim=4, P_dim=4, 
                           test_title=f"TEST 6.{iteration}: Random 4x4 (Iteration {iteration})")

@cocotb.test()
async def test_07_random_padded_shapes(dut):
    """Test 7: Randomized Rectangular Shapes with Zero-Padding (4 iterations)"""
    cocotb.start_soon(Clock(dut.clk_i, 10, unit="ns").start())
    rng = np.random.default_rng(123)

    shapes = [
        (1, 4, 4), # Row vector 1x4 by 4x4
        (4, 4, 1), # 4x4 by Column vector 4x1
        (3, 3, 3), # 3x3 Submatrix
        (1, 2, 3)  # Rectangular matrix 1x2 by 2x3
    ]

    for idx, (M, K, P) in enumerate(shapes, 1):
        A_orig = rng.integers(1, 50, size=(M, K), dtype=np.uint8)
        B_orig = rng.integers(1, 50, size=(K, P), dtype=np.uint8)

        A_pad = np.zeros((4, 4), dtype=np.uint8)
        B_pad = np.zeros((4, 4), dtype=np.uint8)
        A_pad[:M, :K] = A_orig
        B_pad[:K, :P] = B_orig

        await execute_gemm(dut, A_pad, B_pad, M_dim=M, P_dim=P, 
                           test_title=f"TEST 7.{idx}: Random ({M}x{K}) x ({K}x{P}) with Zero-Padding")
