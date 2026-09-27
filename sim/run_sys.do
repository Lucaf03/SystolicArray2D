# Clean up simulation environment
quit -sim
if {![file exists work]} {
    vlib work
}

# Compile PE module, systolic array, and testbench
vlog -sv ../RTL/pe.sv ../RTL/sys.sv tb_sys.sv

# Start simulation with 1ps precision and full visibility
vsim -t 1ps -voptargs="+acc" work.tb_sys

# Add signals to waveform window
add wave -divider "Control"
add wave -color Yellow /tb_sys/clk_i
add wave -color Red    /tb_sys/rst_i

add wave -divider "Inputs: Data A (Rows)"
add wave -radix unsigned /tb_sys/data_i

add wave -divider "Weights: Matrix B (NxN)"
add wave -radix unsigned /tb_sys/weight_i

add wave -divider "Outputs: Results C (Columns)"
add wave -radix unsigned /tb_sys/result_o

add wave -divider "Outputs: Passthrough Data"
add wave -radix unsigned /tb_sys/data_o

# Run all tests
run -all
