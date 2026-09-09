# Pulizia ambiente
quit -sim
vlib work

# Compilazione del modulo e del testbench
vlog pe.sv tb_pe.sv

# Avvio simulazione con risoluzione in ps e visibilità sui segnali interni
vsim -t 1ps -voptargs="+acc" work.tb_pe

# Aggiunta forma d'onda
add wave -divider "Clock & Reset"
add wave -color Yellow /tb_pe/clk_i
add wave -color Red    /tb_pe/rst_i

add wave -divider "Ingressi PE"
add wave -radix unsigned /tb_pe/data_i
add wave -radix unsigned /tb_pe/weight_i
add wave -radix unsigned /tb_pe/prevout_i

add wave -divider "Uscite PE"
add wave -radix unsigned /tb_pe/result_o
add wave -radix unsigned /tb_pe/data_o

# Esecuzione simulazione
run -all