# Clean up simulation environment
quit -sim
if {![file exists work]} {
    vlib work
}

# Compile PE module, systolic array, and testbench with -suppress 2997 for sys.sv:86 unpacked array assignment
vlog -sv -suppress 2997 ../RTL/pe.sv ../RTL/sys.sv tb_sys.sv

# Start simulation with 1ps precision and full visibility
vsim -t 1ps -voptargs="+acc" work.tb_sys

# Add signals to waveform window
add wave -divider "Control"
add wave -color Yellow /tb_sys/clk_i
add wave -color Red    /tb_sys/rst_i
add wave -color Orange /tb_sys/load_weight_i

add wave -divider "Weight Input (1D Shift Vector)"
add wave -radix hexadecimal /tb_sys/weight_i
add wave -radix decimal     /tb_sys/dut/weight_row
add wave -radix decimal     /tb_sys/dut/weight_row_q
add wave -color Orange      /tb_sys/dut/load_weight_q

add wave -divider "Internal PE Weights (Row 0)"
add wave -radix decimal /tb_sys/dut/gen_pe_row[0]/gen_pe_col[0]/u_pe/weight_q
add wave -radix decimal /tb_sys/dut/gen_pe_row[0]/gen_pe_col[1]/u_pe/weight_q
add wave -radix decimal /tb_sys/dut/gen_pe_row[0]/gen_pe_col[2]/u_pe/weight_q
add wave -radix decimal /tb_sys/dut/gen_pe_row[0]/gen_pe_col[3]/u_pe/weight_q

add wave -divider "Inputs: Data A (Rows)"
add wave -radix decimal /tb_sys/data_i

add wave -divider "Outputs: Results C (Columns)"
add wave -radix decimal /tb_sys/result_o

add wave -divider "Outputs: Passthrough Data"
add wave -radix decimal /tb_sys/data_o

# Run all tests
run -all
