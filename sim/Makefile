# Simulator settings
VSIM ?= vsim

.PHONY: all test test_pe test_sys gui_pe gui_sys clean help

all: test

help:
	@echo "Available targets in sim/:"
	@echo "  make test      - Run both PE and 2D Systolic Array simulations in batch mode"
	@echo "  make test_pe   - Run Processing Element testbench (tb_pe.sv)"
	@echo "  make test_sys  - Run 2D Systolic Array testbench (tb_sys.sv)"
	@echo "  make gui_pe    - Open PE simulation in QuestaSim GUI"
	@echo "  make gui_sys   - Open 2D Systolic Array simulation in QuestaSim GUI"
	@echo "  make clean     - Remove all simulation logs, waveforms, reports, and compiled libraries"

test: test_pe test_sys

test_pe:
	$(VSIM) -c -do "do run.do; quit -f"

test_sys:
	$(VSIM) -c -do "do run_sys.do; quit -f"

gui_pe:
	$(VSIM) -do run.do

gui_sys:
	$(VSIM) -do run_sys.do

clean:
	@echo "Cleaning simulation artifacts in sim/..."
	rm -rf work transcript vsim.wlf *.wlf *.vcd *.log obj_dir modelsim.ini
	@echo "Cleanup completed."
