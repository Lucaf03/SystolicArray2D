# Clean up simulation environment
quit -sim
if {![file exists work]} {
    vlib work
}

# Compile PE module and testbench
vlog -sv ../RTL/pe.sv tb_pe.sv

# Start simulation with 1ps precision and full visibility
vsim -t 1ps -voptargs="+acc" work.tb_pe

# Add waveform signals
add wave -divider "Clock & Reset"
add wave -color Yellow /tb_pe/clk_i
add wave -color Red    /tb_pe/rst_i

add wave -divider "PE Weight Control"
add wave -color Orange /tb_pe/load_weight_i
add wave -radix decimal /tb_pe/weight_i
add wave -radix decimal /tb_pe/weight_o

add wave -divider "PE Data Inputs"
add wave -radix decimal /tb_pe/data_i
add wave -radix decimal /tb_pe/prevout_i

add wave -divider "PE Outputs"
add wave -radix decimal /tb_pe/result_o
add wave -radix decimal /tb_pe/data_o

# Run simulation
run -all
